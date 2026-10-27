#!/usr/bin/env bash
# Neemt de laatste versie van de testsite (RenaatDelporte/deboever-test) over
# in de map site/ en maakt ze klaar voor de echte website:
#   - noindex weg, zodat Google de site mag vinden
#   - robots.txt laat zoekmachines toe
#   - het CNAME-bestand van de testsite gaat niet mee
#
# Gebruik: scripts/overnemen-van-testsite.sh <map-met-testsite> <doelmap>
set -euo pipefail

BRON="${1:?map met de testsite ontbreekt}"
DOEL="${2:?doelmap ontbreekt}"

rm -rf "$DOEL"
mkdir -p "$DOEL"
cp -a "$BRON"/. "$DOEL"/
rm -rf "$DOEL/.git" "$DOEL/.github" "$DOEL/CNAME" "$DOEL/README.md" "$DOEL/robots.txt"

# noindex-regels verwijderen
find "$DOEL" -name '*.html' -print0 | xargs -0 sed -i -E \
  '/<meta[^>]*name="robots"[^>]*noindex[^>]*>/d'

printf 'User-agent: *\nAllow: /\n' > "$DOEL/robots.txt"

# Controle: er mag nergens nog noindex staan
if grep -rqi 'noindex' "$DOEL" --include='*.html'; then
  echo "Fout: er staat nog noindex in de pagina's:" >&2
  grep -rli 'noindex' "$DOEL" --include='*.html' >&2
  exit 1
fi

echo "Testsite overgenomen in $DOEL ($(find "$DOEL" -name '*.html' | wc -l) pagina's)."
