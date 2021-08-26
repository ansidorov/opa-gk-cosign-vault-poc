from aiohttp import web
from aiohttp import ClientSession, ClientTimeout
import logging
import asyncio
import nest_asyncio
import json
import time
import os
import argparse
from aiocache import Cache

nest_asyncio.apply()
logger = logging.getLogger(__name__)
cache = Cache(Cache.MEMCACHED, endpoint=os.getenv("MEMCACHED_HOST"), port=int(os.getenv("MEMCACHED_PORT")), namespace="main")
allowed_user_agents = ["Open Policy Agent", "curl"]


async def handle_probe(request):
    vault_addr = os.getenv("VAULT_ADDR")
    vault_healthy = False
    timeout = ClientTimeout(total=5)
    async with ClientSession(timeout=timeout) as session:
        async with session.get(vault_addr + "/v1/sys/health") as resp:
            logger.debug(f"Get response {await resp.text()} from {vault_addr}")
            if resp.status == 200:
                vault_healthy = True
    if vault_healthy is True:
        return web.json_response({"vault_health": True}, status=200)
    else:
        return web.json_response({"vault_health": False}, status=503)


async def work_with_cache(command, key, value=None, ttl=None):
    try:
        if command == "get":
            is_exists = await cache.get(key)
            logger.debug(f"decision for {key} exist in cache: {is_exists}")
            return is_exists
        elif command == "set":
            await cache.set(key=key, value=value, ttl=ttl)
    except ConnectionRefusedError as e:
        logger.warn(f"Cannot connect to memcached with error: {e}")


async def handle_verify(request):
    input_data = await request.json()
    logger.debug(input_data)
    allowed_decision = {"verified": True}
    forbidden_decision = {"verified": False}
    image = input_data.get('image')
    cosign_keychain = input_data.get('cosignKeychain')

    # If User-Agent not allowed - block request and return 403
    if request.headers['User-Agent'].split('/')[0] not in allowed_user_agents:
        logger.debug(f"Request from {request.headers['User-Agent']} deny")
        return web.json_response({"error": "deny", "reason": "forbidden"}, status=403)

    is_exists_in_cache = await work_with_cache(command="get", key=image)
    if is_exists_in_cache is True:
        return web.json_response(allowed_decision)
    elif is_exists_in_cache is False:
        return web.json_response(forbidden_decision)
    else:
        time_start = time.time()
        verify = asyncio.run(cosign_verify(image=image, cosign_keychain=cosign_keychain))
        logger.debug(f"Cosign verify completed at {time.time() - time_start}")
        if verify is None:
            return web.json_response(forbidden_decision)
        else:
            if verify.get('critical').get('type'):
                return web.json_response(allowed_decision)
            else:
                return web.json_response(forbidden_decision)


async def cosign_verify(image, cosign_keychain):
    proc = await asyncio.create_subprocess_shell(
        rf'cosign verify -key hashivault:\/\/{cosign_keychain} {image}',
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE
    )

    stdout, stderr = await proc.communicate()

    logger.debug(f'cosign verify -key hashivault://{cosign_keychain} {image} exited with {proc.returncode}')

    if proc.returncode == 0:
        if stdout:
            logger.debug(f"[stdout]\n{stdout.decode()}")
            await work_with_cache(command="set", key=image, value=True, ttl=10)
            return json.loads(stdout.decode())
    else:
        logger.debug(f"[stderr]\n{stderr.decode()}")
        await work_with_cache(command="set", key=image, value=False, ttl=10)
        return None


parser = argparse.ArgumentParser(description="aiohttp server")
parser.add_argument('--port')

if __name__ == "__main__":
    app = web.Application()
    logging.basicConfig(level=logging.DEBUG)
    app.add_routes([
        web.post('/verify', handle_verify),
        web.get('/probe', handle_probe)
    ])
    args = parser.parse_args()
    web.run_app(app, port=args.port)
