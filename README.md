testpprogetto
=============

testprogetto

# Notifiche Minute PWA

PWA statica (HTML/CSS/JS puro, nessuna build necessaria) che:

- mostra un **messaggio di benvenuto** all'apertura;
- propone il **prompt di installazione** dell'app (con fallback manuale su iOS/Safari);
- una volta attivate le notifiche, invia una **notifica ogni minuto** con un messaggio e l'orario corrente.

## File principali

- `index.html` — interfaccia dell'app.
- `style.css` — stile.
- `app.js` — logica: benvenuto, install prompt, richiesta permesso notifiche, timer al minuto.
- `sw.js` — service worker: cache offline dell'app shell, mostra le notifiche, gestisce il click sulla notifica e (dove supportato) il Periodic Background Sync.
- `manifest.webmanifest` — manifest della PWA (nome, icone, colori, `display: standalone`).
- `icons/` — icone dell'app (192x192, 512x512, 512x512 maskable).
- `server.js` — server statico **HTTPS** in Node.js che usa il certificato in `certs/`.
- `certs/` — certificato TLS autofirmato per lo sviluppo locale (`localhost-cert.pem` + `localhost-key.pem` + `localhost.p12`, quest'ultimo usabile come keystore per Tomcat).
- `scripts/generate-cert.sh` / `scripts/generate-cert.ps1` — rigenera il certificato (e il keystore) in `certs/` (bash o PowerShell, vedi nota Windows sotto).
- `WEB-INF/web.xml` — descrittore della webapp usato solo quando la PWA viene impacchettata per Tomcat (vedi sotto).
- `scripts/build-war.sh` / `scripts/build-war.ps1` — genera il pacchetto `.war` da deployare su Tomcat (bash o PowerShell).

> 🪟 **Sei su Windows?** Tutti gli script hanno un equivalente PowerShell (`.ps1`) accanto a quello bash (`.sh`) — usa quello. Dettagli più sotto in "Note per Windows".

## Come avviarla in locale

I service worker richiedono **HTTPS oppure `localhost`**: non funzionano aprendo il file `index.html` direttamente con `file://`. Puoi scegliere tra HTTP su `localhost` (più semplice) oppure HTTPS con il certificato incluso nel progetto (più vicino a un ambiente di produzione, utile ad es. per testare da un altro dispositivo in rete locale).

### Opzione A — HTTP su localhost (senza certificato)

```bash
# Con Python 3 (già presente su molti sistemi)
cd testprogetto
python3 -m http.server 8080

# oppure con Node.js
npx serve -l 8080
```

Poi apri il browser su:

```
http://localhost:8080/index.html
```

### Opzione B — HTTPS con il certificato del progetto

Il repository include già un certificato autofirmato in `certs/` e un piccolo server Node.js (`server.js`) che lo usa. Serve solo Node.js, nessuna dipendenza da installare.

```bash
cd testprogetto
node server.js          # porta di default: 8443
# oppure una porta a scelta:
node server.js 4443
```

Poi apri il browser su:

```
https://localhost:8443/index.html
```

**Al primo accesso il browser mostrerà un avviso "La connessione non è privata"** perché il certificato è autofirmato (non emesso da una CA riconosciuta).

⚠️ **Importante**: cliccare su "Avanzate → Procedi su localhost (non sicuro)" fa caricare la pagina, **ma non basta**. Chrome (e gli altri browser Chromium) blocca deliberatamente la registrazione del service worker — e quindi anche il prompt di installazione, che ne dipende — su qualunque pagina HTTPS il cui certificato non sia effettivamente attendibile, anche se hai proceduto manualmente oltre l'avviso. In console vedrai un errore tipo:

```
Failed to register a ServiceWorker: An SSL certificate error occurred when fetching the script.
```

Per far funzionare davvero service worker/notifiche/installazione su HTTPS locale hai due strade:

**1) Soluzione rapida (solo Chrome/Edge, solo su questa macchina): abilita il flag per localhost**

1. Apri `chrome://flags/#allow-insecure-localhost`.
2. Imposta il flag su **Enabled**.
3. Riavvia il browser.
4. Ricarica `https://localhost:8443/index.html`: ora il certificato autofirmato viene trattato come valido e tutto funziona.

**2) Soluzione robusta e universale: certificato firmato da una CA locale attendibile con [mkcert](https://github.com/FiloSottile/mkcert)**

`mkcert` installa una CA di sviluppo nel trust store del sistema operativo (e quindi dei browser), così i certificati che genera risultano validi per davvero, senza avvisi e senza flag speciali:

```bash
# installazione (una tantum), esempio su macOS/Linux con Homebrew:
brew install mkcert
mkcert -install                # installa la CA locale nel sistema/browser

# nella cartella del progetto:
cd testprogetto
mkcert -key-file certs/localhost-key.pem -cert-file certs/localhost-cert.pem localhost 127.0.0.1 ::1
```

Questo sovrascrive i file in `certs/` con un certificato realmente attendibile dal tuo sistema. Riavvia `node server.js` e ricarica la pagina: nessun avviso, secure context completo.

Se non vuoi installare nulla, resta comunque disponibile l'**Opzione A (HTTP su `http://localhost`)**: `localhost` è considerato un'origine sicura dal browser anche senza TLS, quindi service worker, notifiche e installazione funzionano subito, senza alcun certificato.

#### Rigenerare il certificato

Il certificato incluso è valido 825 giorni (il massimo accettato dai browser per un self-signed) e copre `localhost`, `127.0.0.1` e `::1`. Per rigenerarlo (es. se scaduto, o per includere altri host):

```bash
cd testprogetto
./scripts/generate-cert.sh
```

Su Windows (PowerShell), equivalente:

```powershell
cd testprogetto
.\scripts\generate-cert.ps1
```

> ⚠️ Il certificato incluso in `certs/` serve **solo per lo sviluppo locale**. Non ha alcun valore per un dominio pubblico reale: per la produzione usa un certificato emesso da una CA reale (es. Let's Encrypt) o affidati a un hosting che lo fornisce automaticamente (GitHub Pages, Netlify, Vercel — vedi sotto).

## Come installarla

### Desktop (Chrome / Edge)

1. Apri `http://localhost:8080/index.html` (Opzione A) oppure `https://localhost:8443/index.html` accettando l'avviso del certificato (Opzione B).
2. Nella pagina apparirà la sezione "📲 Installa l'app": clicca **Installa app**.
   - In alternativa, clicca l'icona di installazione (⊕/monitor) che compare a destra nella barra dell'indirizzo.
3. Conferma nella finestra di dialogo del browser.
4. L'app si aprirà come finestra standalone e comparirà tra le app installate del sistema.

### Android (Chrome)

1. Apri l'URL della PWA (in produzione servito via HTTPS, es. GitHub Pages/Netlify/Vercel — vedi sotto).
2. Tocca il pulsante **Installa app** nella pagina, oppure il menu ⋮ → **Installa app / Aggiungi a schermata Home**.
3. Conferma: l'icona apparirà sulla home screen.

### iPhone/iPad (Safari)

Safari non supporta il prompt automatico (`beforeinstallprompt`), quindi la pagina mostra istruzioni manuali:

1. Apri l'URL nella PWA con **Safari**.
2. Tocca l'icona **Condividi** (il quadrato con la freccia verso l'alto).
3. Scegli **Aggiungi alla schermata Home**.
4. Conferma: l'app apparirà come icona sulla home screen e si aprirà a schermo intero.

## Come attivare le notifiche ogni minuto

1. Dopo aver aperto l'app (installata o nel browser), clicca **Attiva notifiche** nella sezione "🔔 Notifiche ogni minuto".
2. Accetta il permesso richiesto dal browser/sistema operativo.
3. Da quel momento, ogni 60 secondi arriverà una notifica con orario aggiornato, finché la pagina/app resta aperta (anche in background su desktop/Android se l'app è installata).
4. Su Chrome/Edge desktop e Android, se il browser concede il permesso "Periodic Background Sync", l'app prova ad attivarlo per ricevere notifiche anche a pagina completamente chiusa; è un'API sperimentale e non disponibile ovunque (non su Firefox/Safari), quindi il timer lato pagina resta il meccanismo principale e affidabile.

## Deploy su Tomcat, accanto alla webapp Angular (senza toccarla)

Questa PWA è pensata per convivere sullo **stesso Tomcat** che ospita già la webapp Angular (deployata come WAR), come **webapp separata su un context path diverso** — non serve modificare né ricompilare il WAR Angular, solo aggiungere questo pacchetto e (se serve) configurare l'HTTPS di Tomcat.

### 1. Genera il pacchetto `.war`

```bash
cd testprogetto
./scripts/build-war.sh notifiche-pwa
```

Su Windows (PowerShell):

```powershell
cd testprogetto
.\scripts\build-war.ps1 -ContextName notifiche-pwa
```

Crea `dist/notifiche-pwa.war`, contenente solo i file statici della PWA più un `WEB-INF/web.xml` proprio (mappa `.webmanifest` come `application/manifest+json`: non serve toccare il `web.xml` globale di Tomcat né quello della webapp Angular). Il nome passato allo script diventa il **context path**: scegline uno che non collida con quello già usato dall'app Angular (es. `notifiche-pwa`, non `ROOT` né lo stesso nome dell'altra app).

### 2. Copia il WAR nella cartella `webapps/` di Tomcat

```bash
cp dist/notifiche-pwa.war "$CATALINA_HOME/webapps/"
```

Su Windows (PowerShell/cmd), assumendo che `CATALINA_HOME` sia una variabile d'ambiente già impostata:

```powershell
copy dist\notifiche-pwa.war "$env:CATALINA_HOME\webapps\"
```

Con `autoDeploy="true"` (impostazione di default in `conf/server.xml`) Tomcat la pubblica da sola in pochi secondi; altrimenti riavvia il servizio. Sarà raggiungibile su:

```
http(s)://<host>[:porta]/notifiche-pwa/
```

Tutti i percorsi nel progetto (manifest, service worker, icone) sono **relativi**, quindi funzionano automaticamente sotto qualunque context path, senza modifiche.

### 3. Configura HTTPS sul connector di Tomcat (solo config, nessun tocco alla webapp)

Come già visto per lo sviluppo locale, il prompt di installazione e il service worker richiedono un'origine sicura: `http://localhost` va bene solo se accedi dalla stessa macchina col nome letterale `localhost`; se raggiungi Tomcat da un altro dispositivo o con un hostname/IP di rete, **serve HTTPS con un certificato attendibile**. Questa è pura configurazione Tomcat (`conf/server.xml`), non tocca nessuna webapp:

**Per uso interno/di test**, puoi riusare il keystore già generato in `certs/localhost.p12` (password `changeit`) — copialo dove preferisci sul server Tomcat (es. dentro `conf/`) e **aggiungi un connector nuovo, separato da quello HTTP esistente** in `conf/server.xml` (non modificare quest'ultimo, altrimenti smetti di servire HTTP sulla stessa porta):

```xml
<!-- connector HTTP esistente, lasciato invariato -->
<Connector port="7070" protocol="HTTP/1.1"
           connectionTimeout="20000"
           redirectPort="8443" />

<!-- nuovo connector HTTPS, porta diversa -->
<Connector port="8443" protocol="org.apache.coyote.http11.Http11NioProtocol"
           maxThreads="150" SSLEnabled="true"
           scheme="https" secure="true"
           sslEnabledProtocols="TLSv1.2,TLSv1.3">
  <SSLHostConfig>
    <Certificate certificateKeystoreFile="conf/localhost.p12"
                 certificateKeystorePassword="changeit"
                 type="RSA" />
  </SSLHostConfig>
</Connector>
```

`scheme="https"` e `secure="true"` non sono opzionali per correttezza: senza, `SSLEnabled="true"` fa comunque terminare il TLS ma l'applicazione vede la richiesta come se fosse HTTP (utile ad es. se qualche componente genera URL assoluti in base allo schema). Dopo il riavvio, nel log Tomcat il nuovo connector deve comparire come `https-nio-...-8443`, non `http-nio-...`: se vedi ancora `http-nio` sulla porta che hai scelto per HTTPS, la configurazione non è stata applicata.

⚠️ **Usa sempre la porta del connector HTTPS per accedere via `https://`** — è un errore comune (capitato spesso in pratica) puntare per sbaglio il browser alla porta del vecchio connector HTTP con `https://` davanti: in quel caso Tomcat riceve i byte cifrati del TLS handshake su una porta che parla solo HTTP in chiaro, e nel log compare un errore tipo `Invalid character found in method name [0x16 0x03 0x01 ...]` — quei byte (`0x16 0x03 0x01`) sono proprio l'inizio di un handshake TLS. Se lo vedi, controlla che l'URL usi la porta giusta.

⚠️ **Il certificato deve coprire l'IP/hostname con cui accedi davvero**: quello incluso di default nel repo copre solo `localhost`/`127.0.0.1`/`::1`. Se raggiungi Tomcat con un IP di rete reale (es. `10.10.15.43`) o un hostname interno, rigeneralo includendolo nel Subject Alternative Name:

```bash
./scripts/generate-cert.sh 10.10.15.43
# Windows (PowerShell):
.\scripts\generate-cert.ps1 -AdditionalHosts 10.10.15.43
```

poi ricopia il `localhost.p12` risultante nel percorso indicato dal connector Tomcat e riavvia. Senza questo, il browser mostrerà un errore di certificato "hostname mismatch" anche dopo aver sistemato la porta.

⚠️ Vale lo stesso avviso già visto in locale: essendo autofirmato, i browser dei client mostreranno l'avviso "connessione non privata" e — a differenza di `localhost` puro in HTTP — un semplice click su "procedi comunque" **non sblocca** service worker/installazione. Per un uso reale (accesso da altri dispositivi, utenti finali) serve un certificato realmente attendibile:

- un certificato emesso da una CA reale (Let's Encrypt, CA interna aziendale) convertito in keystore Java (`.p12` o `.jks`) e referenziato allo stesso modo nel `<Connector>`, oppure
- un **reverse proxy** davanti a Tomcat (Nginx/Apache/IIS) che termina TLS con un certificato valido e inoltra in HTTP semplice a Tomcat — molto comune in produzione, e non richiede nulla lato Tomcat oltre ad ascoltare in HTTP sulla porta interna.

Per convertire un certificato reale (coppia `.pem`/`.key`) in un keystore PKCS12 utilizzabile da Tomcat:

```bash
openssl pkcs12 -export -in mio-certificato.pem -inkey mia-chiave.pem \
  -out mio-keystore.p12 -name tomcat -passout pass:<password-a-scelta>
```

### 4. Verifica che non ci siano collisioni con l'app Angular

- **Context path diverso** dalla webapp Angular (obbligatorio: due webapp non possono condividere lo stesso path su Tomcat).
- Se entrambe le app sono **sullo stesso host:porta**, condividono la stessa origine ma hanno **scope diversi** (ognuna cade sotto il proprio context path) — i rispettivi service worker non entrano in conflitto.
- Se preferisci porte/host separati (es. un virtual host o una porta dedicata solo per la PWA), va bene lo stesso: cambia solo l'URL con cui la raggiungi, la configurazione del WAR resta identica.

## Note per Windows

Tutto quello descritto sopra funziona anche su Windows, con questi accorgimenti:

- **Script di generazione certificato e build del WAR**: usa le versioni `.ps1` (`scripts\generate-cert.ps1`, `scripts\build-war.ps1`) invece delle `.sh`, che richiederebbero Git Bash o WSL. Se PowerShell blocca l'esecuzione con un errore tipo "l'esecuzione di script è disabilitata su questo sistema", sblocca per la sessione corrente con:
  ```powershell
  Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
  ```
- **`openssl`** (richiesto da `generate-cert.ps1`) non è incluso in Windows di default. Se non lo hai già (es. installato insieme a Git for Windows, che include `openssl.exe`), installalo con uno di:
  ```powershell
  choco install openssl
  # oppure
  winget install ShiningLight.OpenSSL
  ```
- **`node server.js`** (Opzione B, HTTPS in locale) funziona identico su Windows, nessuna modifica: `node server.js` o `node server.js 4443` da PowerShell/cmd.
- **`python3 -m http.server`** (Opzione A): su Windows il comando di solito si chiama `python`, non `python3`:
  ```powershell
  python -m http.server 8080
  ```
- **`build-war.ps1`** non richiede `zip`/`jar` esterni: usa `Compress-Archive`, già incluso in PowerShell 5.1+ (presente di default da Windows 10 in poi).
- **Deploy su Tomcat**: se Tomcat gira come servizio Windows, dopo aver copiato il `.war` in `webapps\` l'auto-deploy funziona come su Linux; se non parte, riavvia il servizio da `services.msc` o con `net stop Tomcat9` / `net start Tomcat9` (nome servizio variabile a seconda dell'installazione).

## Pubblicarla online (per installarla su mobile con HTTPS)

Essendo file statici, basta un hosting qualsiasi con HTTPS, ad esempio:

- **GitHub Pages**: attiva Pages sul branch/cartella del progetto.
- **Netlify / Vercel**: trascina la cartella o collega il repository.

Una volta online, apri l'URL HTTPS dal browser del telefono e segui le istruzioni di installazione sopra.
