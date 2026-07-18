#!/usr/bin/env bash
# Genera un certificato TLS autofirmato per sviluppo locale (localhost/127.0.0.1).
# Uso: ./scripts/generate-cert.sh
# Rigenera i file in certs/ (validi 825 giorni, il massimo accettato da Chrome/Safari
# per un certificato self-signed).

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CERT_DIR="$ROOT_DIR/certs"
mkdir -p "$CERT_DIR"

openssl req -x509 -nodes -newkey rsa:2048 -sha256 -days 825 \
  -keyout "$CERT_DIR/localhost-key.pem" \
  -out "$CERT_DIR/localhost-cert.pem" \
  -subj "/CN=localhost" \
  -addext "subjectAltName=DNS:localhost,IP:127.0.0.1,IP:::1"

echo "Certificato generato in $CERT_DIR:"
echo "  - localhost-cert.pem"
echo "  - localhost-key.pem"
echo
echo "Attenzione: e' un certificato AUTOFIRMATO, valido solo per sviluppo locale."
echo "Il browser mostrera' un avviso 'connessione non sicura' finche' non lo"
echo "accetti manualmente (o lo importi tra le CA attendibili del sistema)."
