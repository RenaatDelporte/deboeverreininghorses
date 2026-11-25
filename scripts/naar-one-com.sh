#!/usr/bin/env bash
# Zet de map site/ via SFTP op de webruimte van dbreininghorses.be bij one.com.
#
# Nodig (de workflow vult ze in):
#   SFTP_SERVER      host uit one.com → Hosting-instellingen → FTP (ssh.c63qju89y.service.one)
#   SFTP_GEBRUIKER   gebruikersnaam uit dezelfde pagina (c63qju89y_ssh)
#   SFTP_WACHTWOORD  het SFTP-wachtwoord, als geheim in GitHub
#                    (Settings → Secrets and variables → Actions)
# Optioneel, als variabele: SFTP_MAP, de publieke map op de server.
# Zonder SFTP_MAP kiest het script httpd.www of www, wat er bestaat.
#
# Gebruik: scripts/naar-one-com.sh <map-met-website>
set -euo pipefail

BRON="${1:?map met de website ontbreekt}"
: "${SFTP_SERVER:?geheim SFTP_SERVER ontbreekt}"
: "${SFTP_GEBRUIKER:?geheim SFTP_GEBRUIKER ontbreekt}"
: "${SFTP_WACHTWOORD:?geheim SFTP_WACHTWOORD ontbreekt}"
[ -f "$BRON/index.html" ] || { echo "Fout: $BRON/index.html ontbreekt." >&2; exit 1; }

export LFTP_PASSWORD="$SFTP_WACHTWOORD"
VERBINDEN="set cmd:fail-exit yes; set sftp:auto-confirm yes; set net:max-retries 2; set net:timeout 30; open --env-password -u \"$SFTP_GEBRUIKER\" sftp://$SFTP_SERVER"

# cls -1 zet / achter mappen en @ achter snelkoppelingen: die tekens weghalen
lijst() { lftp -c "$VERBINDEN; cd \"$1\"; cls -1" | sed 's#[/@]$##'; }

START=$(lijst .)
if [ -z "${SFTP_MAP:-}" ]; then
  for m in httpd.www www; do
    if grep -qx "$m" <<<"$START"; then SFTP_MAP="$m"; break; fi
  done
fi
# Nieuwe servers van one.com: de website staat in webroots/<code> (zie one.com → Subdomeinen).
# Alleen automatisch kiezen als er precies één map in webroots staat.
if [ -z "${SFTP_MAP:-}" ] && grep -qx webroots <<<"$START"; then
  # by-route is een hulpmap van one.com, geen website
  WEBROOTS=$(lijst webroots | grep -vx 'by-route' | grep . || true)
  AANTAL=$(grep -c . <<<"$WEBROOTS" || true)
  if [ "$AANTAL" = 1 ]; then
    SFTP_MAP="webroots/$WEBROOTS"
  else
    echo "Fout: webroots bevat $AANTAL mappen, ik weet niet welke de website is:" >&2
    echo "$WEBROOTS" >&2
    echo "Zet de juiste map (bv. webroots/abcd1234) als variabele SFTP_MAP in GitHub." >&2
    exit 1
  fi
fi
if [ -z "${SFTP_MAP:-}" ]; then
  echo "Fout: geen map httpd.www, www of webroots gevonden op de server. Wat er staat:" >&2
  echo "$START" >&2
  echo "Zet de juiste map als variabele SFTP_MAP in GitHub." >&2
  exit 1
fi

# Veiligheid: nooit synchroniseren in een map met privégegevens of back-ups
DOELMAP=$(lijst "$SFTP_MAP")
if grep -qxE 'httpd\.private|backups|home' <<<"$DOELMAP"; then
  echo "Fout: $SFTP_MAP lijkt niet de publieke map te zijn (bevat httpd.private, backups of home). Gestopt." >&2
  exit 1
fi

echo "Website naar $SFTP_SERVER:$SFTP_MAP zetten..."
lftp -c "$VERBINDEN; cd \"$SFTP_MAP\"; mirror --reverse --delete --no-perms --parallel=4 --verbose=1 --exclude '^\.well-known/' \"$BRON\" ."
echo "Klaar: de website staat op one.com."
