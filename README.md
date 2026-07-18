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
- `certs/` — certificato TLS autofirmato per lo sviluppo locale (`localhost-cert.pem` + `localhost-key.pem`).
- `scripts/generate-cert.sh` — rigenera il certificato in `certs/`.

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

**Al primo accesso il browser mostrerà un avviso "La connessione non è privata"** perché il certificato è autofirmato (non emesso da una CA riconosciuta). È normale: clicca su **Avanzate → Procedi su localhost (non sicuro)** per continuare. Da quel momento service worker, notifiche e prompt di installazione funzioneranno esattamente come con HTTPS reale.

Se vuoi evitare l'avviso del browser, puoi:
- installare il certificato `certs/localhost-cert.pem` tra le CA attendibili del sistema operativo/browser, oppure
- usare uno strumento come [mkcert](https://github.com/FiloSottile/mkcert) per generare un certificato locale già fidato dal sistema (poi copia i due file generati sovrascrivendo quelli in `certs/`, mantenendo i nomi `localhost-cert.pem` e `localhost-key.pem`).

#### Rigenerare il certificato

Il certificato incluso è valido 825 giorni (il massimo accettato dai browser per un self-signed) e copre `localhost`, `127.0.0.1` e `::1`. Per rigenerarlo (es. se scaduto, o per includere altri host):

```bash
cd testprogetto
./scripts/generate-cert.sh
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

## Pubblicarla online (per installarla su mobile con HTTPS)

Essendo file statici, basta un hosting qualsiasi con HTTPS, ad esempio:

- **GitHub Pages**: attiva Pages sul branch/cartella del progetto.
- **Netlify / Vercel**: trascina la cartella o collega il repository.

Una volta online, apri l'URL HTTPS dal browser del telefono e segui le istruzioni di installazione sopra.
