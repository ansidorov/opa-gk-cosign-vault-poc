FROM python:3.9
RUN wget -O /usr/local/bin/cosign https://github.com/sigstore/cosign/releases/download/v1.0.0/cosign-linux-amd64 \
  && chmod +x /usr/local/bin/cosign
WORKDIR /app
COPY api.py /app/api.py
COPY requirements.txt /app/requirements.txt
RUN pip install -r requirements.txt
CMD ["python", "api.py"]
