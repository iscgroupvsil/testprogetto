#!/usr/bin/env node
// Server statico HTTPS per servire la PWA in locale con il certificato
// autofirmato in certs/. Uso: node server.js [porta]
"use strict";

const fs = require("fs");
const path = require("path");
const https = require("https");

const ROOT_DIR = __dirname;
const CERT_DIR = path.join(ROOT_DIR, "certs");
const PORT = Number(process.argv[2] || process.env.PORT || 8443);

const CERT_PATH = path.join(CERT_DIR, "localhost-cert.pem");
const KEY_PATH = path.join(CERT_DIR, "localhost-key.pem");

if (!fs.existsSync(CERT_PATH) || !fs.existsSync(KEY_PATH)) {
  console.error("Certificato non trovato in certs/.");
  console.error("Generalo con: ./scripts/generate-cert.sh");
  process.exit(1);
}

const MIME_TYPES = {
  ".html": "text/html; charset=utf-8",
  ".js": "text/javascript; charset=utf-8",
  ".css": "text/css; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".webmanifest": "application/manifest+json; charset=utf-8",
  ".png": "image/png",
  ".svg": "image/svg+xml",
  ".ico": "image/x-icon"
};

const options = {
  cert: fs.readFileSync(CERT_PATH),
  key: fs.readFileSync(KEY_PATH)
};

function safeJoin(root, requestPath) {
  const decoded = decodeURIComponent(requestPath.split("?")[0]);
  const resolved = path.normalize(path.join(root, decoded));
  if (!resolved.startsWith(root)) return null; // blocca path traversal
  return resolved;
}

const server = https.createServer(options, (req, res) => {
  let filePath = safeJoin(ROOT_DIR, req.url === "/" ? "/index.html" : req.url);
  if (!filePath) {
    res.writeHead(400);
    res.end("Bad request");
    return;
  }

  fs.stat(filePath, (err, stats) => {
    if (err) {
      res.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
      res.end("404 Not Found");
      return;
    }
    if (stats.isDirectory()) {
      filePath = path.join(filePath, "index.html");
    }

    fs.readFile(filePath, (readErr, data) => {
      if (readErr) {
        res.writeHead(404, { "Content-Type": "text/plain; charset=utf-8" });
        res.end("404 Not Found");
        return;
      }
      const ext = path.extname(filePath);
      res.writeHead(200, {
        "Content-Type": MIME_TYPES[ext] || "application/octet-stream",
        "Cache-Control": "no-cache"
      });
      res.end(data);
    });
  });
});

server.listen(PORT, () => {
  console.log(`PWA disponibile su https://localhost:${PORT}/index.html`);
  console.log("Certificato autofirmato: il browser mostrera' un avviso al primo accesso.");
});
