// Service worker do Por km: deixa o app abrir sem internet.
// - Pagina e icones: busca na rede primeiro (pega versao nova) e cai no cache se estiver sem sinal.
// - Bibliotecas externas (versoes fixas): cache primeiro, nunca mudam.
// - Supabase (dados e login): nunca passa pelo cache; offline o proprio app usa a copia local.
const VERSAO = "porkm-v1.7"; // trocar a cada versao: limpa o cache antigo no celular
const APP = ["./", "./index.html", "./manifest.webmanifest", "./icone.svg", "./icone-180.png", "./icone-192.png", "./icone-512.png"];
const LIBS = [
  "https://unpkg.com/react@18.3.1/umd/react.production.min.js",
  "https://unpkg.com/react-dom@18.3.1/umd/react-dom.production.min.js",
  "https://unpkg.com/@babel/standalone@7.22.5/babel.min.js",
  "https://cdn.jsdelivr.net/npm/@supabase/supabase-js@2.45.4/dist/umd/supabase.min.js",
];

self.addEventListener("install", (e) => {
  e.waitUntil(caches.open(VERSAO).then((c) => c.addAll([...APP, ...LIBS])).then(() => self.skipWaiting()));
});

self.addEventListener("activate", (e) => {
  e.waitUntil(
    caches.keys()
      .then((nomes) => Promise.all(nomes.filter((n) => n !== VERSAO).map((n) => caches.delete(n))))
      .then(() => self.clients.claim())
  );
});

self.addEventListener("fetch", (e) => {
  const req = e.request;
  if (req.method !== "GET") return;
  const url = new URL(req.url);
  if (url.hostname.endsWith("supabase.co")) return; // dados: sempre direto

  if (LIBS.includes(req.url)) {
    e.respondWith(caches.match(req).then((r) => r || fetch(req)));
    return;
  }
  if (url.origin === self.location.origin) {
    e.respondWith(
      fetch(req)
        .then((resp) => {
          if (resp.ok) { const copia = resp.clone(); caches.open(VERSAO).then((c) => c.put(req, copia)); }
          return resp;
        })
        .catch(() => caches.match(req).then((r) => r || caches.match("./index.html")))
    );
  }
});
