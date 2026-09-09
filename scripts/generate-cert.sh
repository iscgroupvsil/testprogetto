#!/usr/bin/env bash
# Genera un certificato TLS autofirmato per sviluppo/deploy locale.
# Uso: ./scripts/generate-cert.sh [host-o-ip-aggiuntivo ...]
#
# Copre sempre localhost/127.0.0.1/::1; ogni argomento in piu' (IP o
# hostname) viene aggiunto al Subject Alternative Name, utile quando il
# server (es. Tomcat) viene raggiunto tramite un IP di rete reale invece
# che da "localhost".
#
# Esempio, per un Tomcat raggiungibile su 10.10.15.43:
#   ./scripts/generate-cert.sh 10.10.15.43
#
# Rigenera i file in certs/ (validi 825 giorni, il massimo accettato da Chrome/Safari
# per un certificato self-signed).

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CERT_DIR="$ROOT_DIR/certs"
mkdir -p "$CERT_DIR"

SAN="DNS:localhost,IP:127.0.0.1,IP:::1"
for host in "$@"; do
  if [[ "$host" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]] || [[ "$host" == *:* ]]; then
    SAN="$SAN,IP:$host"
  else
    SAN="$SAN,DNS:$host"
  fi
done

openssl req -x509 -nodes -newkey rsa:2048 -sha256 -days 825 \
  -keyout "$CERT_DIR/localhost-key.pem" \
  -out "$CERT_DIR/localhost-cert.pem" \
  -subj "/CN=localhost" \
  -addext "subjectAltName=$SAN"

# Keystore PKCS12 per il connector HTTPS di Tomcat (server.xml), generato
# dallo stesso certificato/chiave. Password fissa "changeit" per comodita'
# di sviluppo: per un ambiente reale rigenera con una password propria.
openssl pkcs12 -export \
  -in "$CERT_DIR/localhost-cert.pem" -inkey "$CERT_DIR/localhost-key.pem" \
  -out "$CERT_DIR/localhost.p12" -name tomcat \
  -passout pass:changeit

echo "Certificato generato in $CERT_DIR:"
echo "  - localhost-cert.pem"
echo "  - localhost-key.pem"
echo "  - localhost.p12   (keystore per il connector HTTPS di Tomcat, password: changeit)"
echo "  SAN incluso: $SAN"
echo
echo "Attenzione: e' un certificato AUTOFIRMATO, valido solo per sviluppo/uso interno."
echo "Il browser mostrera' un avviso 'connessione non sicura' finche' non lo"
echo "accetti manualmente (o lo importi tra le CA attendibili del sistema)."
