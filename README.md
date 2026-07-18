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

## Come avviarla in locale

I service worker richiedono **HTTPS oppure `localhost`**: non funzionano aprendo il file `index.html` direttamente con `file://`. Serve quindi un piccolo server statico.

Scegli una delle opzioni:

```bash
# Opzione 1: con Python 3 (già presente su molti sistemi)
cd testprogetto
python3 -m http.server 8080

# Opzione 2: con Node.js
cd testprogetto
npx serve -l 8080
# oppure
npx http-server -p 8080
```

Poi apri il browser su:

```
http://localhost:8080/index.html
```

## Come installarla

### Desktop (Chrome / Edge)

1. Apri `http://localhost:8080/index.html`.
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
