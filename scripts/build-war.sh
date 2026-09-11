#!/usr/bin/env bash
# Genera il pacchetto .war della PWA, pronto per essere copiato in
# $CATALINA_HOME/webapps/ di Tomcat, senza toccare nessun'altra webapp.
#
# Uso:
#   ./scripts/build-war.sh [nome-context-path]
#
# Esempio:
#   ./scripts/build-war.sh notifiche-pwa
#   -> genera dist/notifiche-pwa.war, deployata da Tomcat su
#      https://<host>/notifiche-pwa/
#
# Se non passi un nome, di default usa "notifiche-pwa".
# Per farla rispondere sulla root del sito (es. https://<host>/), rinomina
# il file generato in ROOT.war (occhio: entra in conflitto con qualunque
# altra webapp gia' mappata sulla root).

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONTEXT_NAME="${1:-notifiche-pwa}"
DIST_DIR="$ROOT_DIR/dist"
STAGE_DIR="$(mktemp -d)"
WAR_PATH="$DIST_DIR/${CONTEXT_NAME}.war"

trap 'rm -rf "$STAGE_DIR"' EXIT

mkdir -p "$DIST_DIR"

# Copia solo i file che devono finire nella webapp (niente certs/, server.js,
# script di sviluppo, README, .git...).
cp "$ROOT_DIR/index.html" "$STAGE_DIR/"
cp "$ROOT_DIR/style.css" "$STAGE_DIR/"
cp "$ROOT_DIR/app.js" "$STAGE_DIR/"
cp "$ROOT_DIR/sw.js" "$STAGE_DIR/"
cp "$ROOT_DIR/manifest.webmanifest" "$STAGE_DIR/"
cp -r "$ROOT_DIR/icons" "$STAGE_DIR/"
mkdir -p "$STAGE_DIR/WEB-INF"
cp "$ROOT_DIR/WEB-INF/web.xml" "$STAGE_DIR/WEB-INF/"

rm -f "$WAR_PATH"
( cd "$STAGE_DIR" && zip -r -X -q "$WAR_PATH" . )

echo "Pacchetto creato: $WAR_PATH"
echo
echo "Deploy:"
echo "  cp \"$WAR_PATH\" \$CATALINA_HOME/webapps/"
echo "  (Tomcat con autoDeploy attivo la pubblica da sola in pochi secondi,"
echo "   altrimenti riavvia Tomcat)"
echo
echo "Sara' raggiungibile su:  https://<host>[:porta]/${CONTEXT_NAME}/"
