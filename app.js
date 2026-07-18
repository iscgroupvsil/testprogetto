(() => {
  "use strict";

  const $ = (id) => document.getElementById(id);
  const welcomeText = $("welcome-text");
  const insecureWarning = $("insecure-warning");
  const insecureUrl = $("insecure-url");
  const installCard = $("install-card");
  const installBtn = $("install-btn");
  const installHint = $("install-hint");
  const notifBtn = $("notif-btn");
  const notifStatus = $("notif-status");
  const nextTick = $("next-tick");
  const logList = $("log-list");
  const connectionStatus = $("connection-status");
  const swStatus = $("sw-status");

  const MINUTE_MS = 60 * 1000;
  let deferredInstallPrompt = null;
  let tickInterval = null;
  let countdownInterval = null;
  let nextTickAt = null;
  let swRegistration = null;

  function log(message) {
    const li = document.createElement("li");
    const time = new Date().toLocaleTimeString("it-IT");
    li.textContent = `[${time}] ${message}`;
    logList.appendChild(li);
  }

  function updateConnectionStatus() {
    const online = navigator.onLine;
    connectionStatus.classList.toggle("online", online);
    connectionStatus.title = online ? "Online" : "Offline";
  }

  // ---------- 1. Messaggio di benvenuto ----------
  function showWelcome() {
    const hour = new Date().getHours();
    const saluto = hour < 12 ? "Buongiorno" : hour < 18 ? "Buon pomeriggio" : "Buonasera";
    const isStandalone =
      window.matchMedia("(display-mode: standalone)").matches || window.navigator.standalone === true;

    welcomeText.textContent = isStandalone
      ? `${saluto}! L'app è installata e pronta all'uso. 🎉`
      : `${saluto}! Benvenuto nella PWA di esempio.`;

    log("Messaggio di benvenuto mostrato.");

    // Se il permesso di notifica è già stato concesso in passato,
    // mandiamo anche una notifica di benvenuto vera e propria.
    if ("Notification" in window && Notification.permission === "granted") {
      sendToSW({ type: "SHOW_WELCOME", body: `${saluto}! Grazie per aver aperto l'app.` });
    }
  }

  // ---------- 2. Prompt di installazione ----------
  window.addEventListener("beforeinstallprompt", (event) => {
    event.preventDefault();
    deferredInstallPrompt = event;
    installCard.hidden = false;
    installHint.textContent = "";
    log("Il browser consente l'installazione: pulsante attivato.");
  });

  installBtn.addEventListener("click", async () => {
    if (!deferredInstallPrompt) return;
    installBtn.disabled = true;
    deferredInstallPrompt.prompt();
    const { outcome } = await deferredInstallPrompt.userChoice;
    log(outcome === "accepted" ? "Utente ha accettato l'installazione." : "Utente ha rifiutato l'installazione.");
    deferredInstallPrompt = null;
    installBtn.disabled = false;
    if (outcome === "accepted") installCard.hidden = true;
  });

  window.addEventListener("appinstalled", () => {
    installCard.hidden = true;
    log("App installata con successo. 🎉");
  });

  const isStandaloneNow =
    window.matchMedia("(display-mode: standalone)").matches || window.navigator.standalone === true;
  if (isStandaloneNow) {
    installCard.hidden = true;
  } else if (!("onbeforeinstallprompt" in window)) {
    // Safari/iOS non supporta beforeinstallprompt: mostriamo istruzioni manuali.
    installCard.hidden = false;
    installBtn.hidden = true;
    installHint.textContent =
      "Su iOS/Safari: tocca l'icona Condividi e poi \"Aggiungi alla schermata Home\".";
  }

  // ---------- 3. Notifiche ogni minuto ----------
  function sendToSW(message) {
    if (swRegistration && swRegistration.active) {
      swRegistration.active.postMessage(message);
    } else if (navigator.serviceWorker.controller) {
      navigator.serviceWorker.controller.postMessage(message);
    }
  }

  function updateCountdown() {
    if (!nextTickAt) {
      nextTick.textContent = "";
      return;
    }
    const remaining = Math.max(0, Math.round((nextTickAt - Date.now()) / 1000));
    nextTick.textContent = `Prossima notifica tra ${remaining}s`;
  }

  function startMinuteNotifications() {
    if (tickInterval) return;

    sendToSW({ type: "SHOW_MINUTE_TICK" });
    log("Notifica inviata (ora): " + new Date().toLocaleTimeString("it-IT"));
    nextTickAt = Date.now() + MINUTE_MS;

    tickInterval = setInterval(() => {
      sendToSW({ type: "SHOW_MINUTE_TICK" });
      log("Notifica inviata (ora): " + new Date().toLocaleTimeString("it-IT"));
      nextTickAt = Date.now() + MINUTE_MS;
    }, MINUTE_MS);

    countdownInterval = setInterval(updateCountdown, 1000);
    updateCountdown();

    tryEnablePeriodicSync();
  }

  function stopMinuteNotifications() {
    clearInterval(tickInterval);
    clearInterval(countdownInterval);
    tickInterval = null;
    countdownInterval = null;
    nextTickAt = null;
    nextTick.textContent = "";
  }

  async function tryEnablePeriodicSync() {
    if (!swRegistration || !("periodicSync" in swRegistration)) return;
    try {
      const status = await navigator.permissions.query({ name: "periodic-background-sync" });
      if (status.state === "granted") {
        await swRegistration.periodicSync.register("minute-tick", { minInterval: MINUTE_MS });
        log("Periodic Background Sync attivato (notifiche anche a pagina chiusa, se supportato).");
      }
    } catch (err) {
      // Non supportato dal browser/piattaforma: si usa solo il timer di pagina.
    }
  }

  async function requestNotifications() {
    if (!("Notification" in window)) {
      notifStatus.textContent = "Stato: le notifiche non sono supportate su questo browser.";
      return;
    }

    const permission = await Notification.requestPermission();
    notifStatus.textContent = `Stato: permesso ${permission}`;
    log(`Permesso notifiche: ${permission}`);

    if (permission === "granted") {
      notifBtn.textContent = "Notifiche attive ✔";
      notifBtn.disabled = true;
      startMinuteNotifications();
    }
  }

  notifBtn.addEventListener("click", requestNotifications);

  // ---------- Service worker ----------
  async function registerServiceWorker() {
    if (!("serviceWorker" in navigator)) {
      swStatus.textContent = "Service worker: non supportato da questo browser.";
      return;
    }
    try {
      swRegistration = await navigator.serviceWorker.register("sw.js");
      swStatus.textContent = "Service worker: attivo ✔";
      log("Service worker registrato.");

      if (Notification.permission === "granted") {
        notifBtn.textContent = "Notifiche attive ✔";
        notifBtn.disabled = true;
        startMinuteNotifications();
      }
    } catch (err) {
      swStatus.textContent = "Service worker: errore in registrazione.";
      log("Errore registrazione service worker: " + err.message);
    }
  }

  // ---------- Diagnostica contesto sicuro ----------
  // Fuori da http://localhost o https:// (es. aperta come file://), Chrome
  // rimuove del tutto navigator.serviceWorker e beforeinstallprompt non
  // scatta mai: da qui il messaggio "non supportato" anche se il browser
  // lo supporterebbe normalmente.
  function checkSecureContext() {
    if (!window.isSecureContext) {
      insecureUrl.textContent = window.location.href;
      insecureWarning.hidden = false;
      log("Contesto non sicuro rilevato: " + window.location.protocol);
      return false;
    }
    return true;
  }

  // ---------- Init ----------
  window.addEventListener("online", updateConnectionStatus);
  window.addEventListener("offline", updateConnectionStatus);
  updateConnectionStatus();
  showWelcome();
  if (checkSecureContext()) {
    registerServiceWorker();
  } else {
    swStatus.textContent = "Service worker: bloccato (contesto non sicuro, vedi avviso sopra).";
  }
})();
