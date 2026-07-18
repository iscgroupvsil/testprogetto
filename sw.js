const CACHE_NAME = "notifiche-min-pwa-v1";
const APP_SHELL = [
  "./",
  "./index.html",
  "./style.css",
  "./app.js",
  "./manifest.webmanifest",
  "./icons/icon-192.png",
  "./icons/icon-512.png",
  "./icons/icon-maskable-512.png"
];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(APP_SHELL))
  );
  self.skipWaiting();
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(
        keys
          .filter((key) => key !== CACHE_NAME)
          .map((key) => caches.delete(key))
      )
    )
  );
  self.clients.claim();
});

self.addEventListener("fetch", (event) => {
  if (event.request.method !== "GET") return;
  event.respondWith(
    caches.match(event.request).then(
      (cached) =>
        cached ||
        fetch(event.request)
          .then((response) => {
            const copy = response.clone();
            caches.open(CACHE_NAME).then((cache) => cache.put(event.request, copy));
            return response;
          })
          .catch(() => cached)
    )
  );
});

function formatTime(date) {
  return date.toLocaleTimeString("it-IT", {
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit"
  });
}

function showMinuteNotification() {
  const now = new Date();
  return self.registration.showNotification("Promemoria PWA", {
    body: `Sono le ${formatTime(now)} — tutto ok, l'app e' attiva.`,
    icon: "./icons/icon-192.png",
    badge: "./icons/icon-192.png",
    tag: "minute-tick",
    renotify: true,
    silent: false
  });
}

// La pagina, finche' e' aperta, chiede al service worker di mostrare
// la notifica ogni minuto passando qui il comando.
self.addEventListener("message", (event) => {
  if (event.data && event.data.type === "SHOW_WELCOME") {
    event.waitUntil(
      self.registration.showNotification("Benvenuto!", {
        body: event.data.body || "Grazie per aver aperto l'app.",
        icon: "./icons/icon-192.png",
        badge: "./icons/icon-192.png",
        tag: "welcome"
      })
    );
  }
  if (event.data && event.data.type === "SHOW_MINUTE_TICK") {
    event.waitUntil(showMinuteNotification());
  }
});

// Supporto opzionale al Periodic Background Sync (solo Chrome/Edge desktop
// e Android, PWA installata, permesso concesso dal browser). Se disponibile
// permette notifiche anche a pagina chiusa; altrimenti si usa il timer
// lato pagina in app.js.
self.addEventListener("periodicsync", (event) => {
  if (event.tag === "minute-tick") {
    event.waitUntil(showMinuteNotification());
  }
});

self.addEventListener("notificationclick", (event) => {
  event.notification.close();
  event.waitUntil(
    self.clients.matchAll({ type: "window" }).then((clientsArr) => {
      const existing = clientsArr.find((c) => "focus" in c);
      if (existing) return existing.focus();
      return self.clients.openWindow("./index.html");
    })
  );
});
