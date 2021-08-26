provider "vault" {

}

resource "vault_mount" "transit" {
  path      = "transit"
  type      = "transit"
  description = "Transit for cosign 1.0.0"
}

resource "vault_transit_secret_backend_key" "key" {
  backend = vault_mount.transit.path
  name = "testkey"
  type = "ecdsa-p256"
}

### Transit for cosign > 1.0.0
resource "vault_mount" "cosign-space" {
  path = "cosign-space"
  type = "transit"
  description = "Transit for cosign > 1.0.0"
}

resource "vault_transit_secret_backend_key" "cosign-space" {
  backend = vault_mount.cosign-space.path
  name = "cosign"
  type = "ecdsa-p256"
}

resource "vault_policy" "transit-admin" {
  name = "transit-admin"
  policy = <<EOT
path "transit/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "transit/keys/testkey" {
  capabilities = ["update", "read"]
}
EOT
}

resource "vault_policy" "cosign-admin" {
  name = "cosign-space-admin"
  policy = <<EOT
path "cosign-space/*" {
  capabilities = ["create", "read", "update", "delete", "list"]
}
path "cosign-space/keys/cosign" {
  capabilities = ["update", "read"]
}
EOT
}

resource "vault_token" "cosign" {
  policies = ["transit-admin", "cosign-space-admin"]
}

output "cosign-token" {
  value = vault_token.cosign.client_token
  sensitive = true
}