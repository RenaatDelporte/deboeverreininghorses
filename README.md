# De Boever Reining Horses – website

De echte website van De Boever Reining Horses (dbstables.be).

## Hoe het werkt

1. Alle wijzigingen gebeuren eerst op de **testsite** (repository `deboever-test`, https://deboever.renaatdelporte.be).
2. Is de testsite goed, dan start je **Actions → Website publiceren → Run workflow**.
3. Die stap haalt de testsite op, haalt de `noindex` weg (Google mag de echte site wel vinden), bewaart het resultaat in de map `site/` en zet het online.

Pas de bestanden in `site/` dus niet rechtstreeks aan: bij de volgende publicatie worden ze vervangen door de testsite.

## Hosting

- **Nu:** GitHub Pages.
- **Straks:** eigen hosting. Dan komt er een stap bij die `site/` via FTP op de server zet.
