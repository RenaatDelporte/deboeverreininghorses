#!/usr/bin/env bash
# Neemt de laatste versie van de testsite (RenaatDelporte/deboever-test) over
# in de map site/ en maakt ze klaar voor de echte website:
#   - noindex weg, zodat Google de site mag vinden
#   - robots.txt laat zoekmachines toe en verwijst naar de sitemap
#   - het CNAME-bestand van de testsite gaat niet mee
#   - elke pagina krijgt een canonieke link en een volledig adres voor
#     og:url en og:image (nodig voor Facebook, WhatsApp, Google)
#   - sitemap.xml en .htaccess (https, zonder www, caching) worden gemaakt
#
# Gebruik: scripts/overnemen-van-testsite.sh <map-met-testsite> <doelmap> [adres]
set -euo pipefail

BRON="${1:?map met de testsite ontbreekt}"
DOEL="${2:?doelmap ontbreekt}"
ADRES="${3:-https://dbreininghorses.be}"
ADRES="${ADRES%/}"
DOMEIN="${ADRES#https://}"

rm -rf "$DOEL"
mkdir -p "$DOEL"
cp -a "$BRON"/. "$DOEL"/
rm -rf "$DOEL/.git" "$DOEL/.github" "$DOEL/CNAME" "$DOEL/README.md" "$DOEL/robots.txt"

# noindex-regels verwijderen
find "$DOEL" -name '*.html' -print0 | xargs -0 sed -i -E \
  '/<meta[^>]*name="robots"[^>]*noindex[^>]*>/d'

# Canonieke link, og:url en volledige og:image per pagina; url in de gestructureerde gegevens
python3 - "$DOEL" "$ADRES" <<'PY'
import pathlib, re, sys
doel, adres = pathlib.Path(sys.argv[1]), sys.argv[2]
for pagina in sorted(doel.glob('*.html')):
    t = pagina.read_text(encoding='utf-8')
    url = adres + '/' if pagina.name == 'index.html' else f'{adres}/{pagina.name}'
    t = re.sub(r'<link rel="canonical"[^>]*>\n?|<meta property="og:url"[^>]*>\n?', '', t)
    t = re.sub(r'(<meta property="og:image" content=")(?!https?://)([^"]+)"',
               lambda m: f'{m.group(1)}{adres}/{m.group(2)}"', t)
    extra = f'<link rel="canonical" href="{url}">\n<meta property="og:url" content="{url}">\n'
    t = t.replace('<meta charset="utf-8">\n', '<meta charset="utf-8">\n' + extra, 1)
    if pagina.name == 'index.html' and '"url":' not in t:
        t = t.replace(' "alternateName": "DB Stables",\n',
                      f' "alternateName": "DB Stables",\n "url": "{adres}/",\n', 1)
    if url not in t:
        sys.exit(f'Fout: canonieke link niet toegevoegd in {pagina.name}')
    pagina.write_text(t, encoding='utf-8')
PY

# sitemap.xml
VANDAAG=$(date -u +%Y-%m-%d)
{
  echo '<?xml version="1.0" encoding="UTF-8"?>'
  echo '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">'
  for pagina in index.html pensionstalling.html reining.html onze-paarden.html familie-de-boever.html te-koop.html privacybeleid.html; do
    [ -f "$DOEL/$pagina" ] || continue
    if [ "$pagina" = index.html ]; then url="$ADRES/"; else url="$ADRES/$pagina"; fi
    printf '  <url><loc>%s</loc><lastmod>%s</lastmod></url>\n' "$url" "$VANDAAG"
  done
  echo '</urlset>'
} > "$DOEL/sitemap.xml"

printf 'User-agent: *\nAllow: /\n\nSitemap: %s/sitemap.xml\n' "$ADRES" > "$DOEL/robots.txt"

# .htaccess voor de webruimte bij one.com (GitHub Pages negeert dit bestand)
DOMEIN_REGEX="${DOMEIN//./\\.}"
cat > "$DOEL/.htaccess" <<HT
# Gemaakt door scripts/overnemen-van-testsite.sh. Niet met de hand aanpassen.
DirectoryIndex index.html

# Altijd via https en zonder www op $DOMEIN
RewriteEngine On
RewriteCond %{HTTPS} !=on [OR]
RewriteCond %{HTTP_HOST} !^${DOMEIN_REGEX}\$ [NC]
RewriteRule ^ $ADRES%{REQUEST_URI} [L,R=301]

# /index.html naar /
RewriteCond %{THE_REQUEST} \s/index\.html[\s?]
RewriteRule ^index\.html\$ $ADRES/ [L,R=301]

# Foto's, lettertypes en icoontjes mogen lang in de browser blijven
<IfModule mod_expires.c>
  ExpiresActive On
  ExpiresByType image/webp "access plus 1 month"
  ExpiresByType image/jpeg "access plus 1 month"
  ExpiresByType image/png "access plus 1 month"
  ExpiresByType image/x-icon "access plus 1 month"
  ExpiresByType font/woff2 "access plus 1 year"
  ExpiresByType video/mp4 "access plus 1 month"
  ExpiresByType text/html "access plus 0 seconds"
</IfModule>
HT

# Controle: er mag nergens nog noindex staan
if grep -rqi 'noindex' "$DOEL" --include='*.html'; then
  echo "Fout: er staat nog noindex in de pagina's:" >&2
  grep -rli 'noindex' "$DOEL" --include='*.html' >&2
  exit 1
fi

echo "Testsite overgenomen in $DOEL ($(find "$DOEL" -name '*.html' | wc -l) pagina's) voor $ADRES."
