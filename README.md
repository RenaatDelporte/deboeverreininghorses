# De Boever Reining Horses – website

De echte website van De Boever Reining Horses: https://dbreininghorses.be

## Hoe het werkt

1. Alle wijzigingen gebeuren eerst op de **testsite** (repository `deboever-test`, https://deboever.renaatdelporte.be).
2. Is de testsite goed, dan start je **Actions → Website publiceren → Run workflow**.
3. Die stap haalt de testsite op, haalt de `noindex` weg (Google mag de echte site wel vinden), bewaart het resultaat in de map `site/` en zet het online.

Pas de bestanden in `site/` dus niet rechtstreeks aan: bij de volgende publicatie worden ze vervangen door de testsite.

## Hosting

- **dbreininghorses.be:** webruimte bij one.com. De publicatie zet `site/` er via SFTP op (`scripts/naar-one-com.sh`). Host (`ssh.c63qju89y.service.one`) en gebruikersnaam (`c63qju89y_ssh`) staan in de workflow; ze komen uit one.com → Hosting-instellingen → FTP. Alleen het wachtwoord moet als geheim ingevuld zijn onder **Settings → Secrets and variables → Actions**:
  - `SFTP_WACHTWOORD`: het SFTP-wachtwoord dat je in one.com instelt (via de knop **Verzenden** op die pagina krijg je een mail om het in te stellen)
- **GitHub Pages:** blijft als reservekopie meelopen op https://renaatdelporte.github.io/deboeverreininghorses/. Elke pagina verwijst met een canonieke link naar dbreininghorses.be, zodat Google alleen dat adres toont.

Bij het overnemen maakt het script ook `sitemap.xml`, `robots.txt` en `.htaccess` (altijd https, zonder www) aan.
