// Cache per l'uso offline. Cambia VERSIONE a ogni aggiornamento dei file.
const VERSIONE = "spese-v1";
const FILE = [
  "./", "index.html", "style.css", "app.js", "manifest.webmanifest",
  "icons/icon-192.png", "icons/icon-512.png", "icons/apple-touch-icon.png",
];

self.addEventListener("install", (e) => {
  e.waitUntil(caches.open(VERSIONE).then((c) => c.addAll(FILE)).then(() => self.skipWaiting()));
});

self.addEventListener("activate", (e) => {
  e.waitUntil(
    caches.keys()
      .then((chiavi) => Promise.all(chiavi.filter((k) => k !== VERSIONE).map((k) => caches.delete(k))))
      .then(() => self.clients.claim())
  );
});

// Prima la rete (così gli aggiornamenti arrivano subito), poi la cache se offline.
self.addEventListener("fetch", (e) => {
  if (e.request.method !== "GET") return;
  e.respondWith(
    fetch(e.request)
      .then((risposta) => {
        const copia = risposta.clone();
        caches.open(VERSIONE).then((c) => c.put(e.request, copia));
        return risposta;
      })
      .catch(() => caches.match(e.request).then((r) => r || caches.match("index.html")))
  );
});
