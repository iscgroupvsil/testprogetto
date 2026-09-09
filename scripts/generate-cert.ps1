<#
.SYNOPSIS
  Genera un certificato TLS autofirmato per sviluppo locale (localhost/127.0.0.1)
  e il relativo keystore PKCS12 per Tomcat, su Windows (PowerShell).

.USO
  cd testprogetto
  .\scripts\generate-cert.ps1

  Se PowerShell blocca l'esecuzione degli script, avvialo una volta con:
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#>

$ErrorActionPreference = "Stop"

$RootDir = Split-Path -Parent $PSScriptRoot
$CertDir = Join-Path $RootDir "certs"
New-Item -ItemType Directory -Force -Path $CertDir | Out-Null

$openssl = Get-Command openssl -ErrorAction SilentlyContinue
if (-not $openssl) {
    Write-Error @"
openssl non trovato nel PATH.
Installalo con una di queste opzioni e riprova:
  - Git for Windows (include openssl.exe): https://git-scm.com/download/win
    (usalo da 'Git Bash' oppure aggiungi <cartella Git>\usr\bin al PATH di PowerShell)
  - Chocolatey: choco install openssl
  - winget: winget install ShiningLight.OpenSSL
"@
    exit 1
}

$keyPath  = Join-Path $CertDir "localhost-key.pem"
$certPath = Join-Path $CertDir "localhost-cert.pem"
$p12Path  = Join-Path $CertDir "localhost.p12"

& openssl req -x509 -nodes -newkey rsa:2048 -sha256 -days 825 `
    -keyout $keyPath `
    -out $certPath `
    -subj "/CN=localhost" `
    -addext "subjectAltName=DNS:localhost,IP:127.0.0.1,IP:::1"

# Keystore PKCS12 per il connector HTTPS di Tomcat (server.xml).
# Password fissa "changeit" per comodita' di sviluppo: per un ambiente
# reale rigenera con una password propria.
& openssl pkcs12 -export `
    -in $certPath -inkey $keyPath `
    -out $p12Path -name tomcat `
    -passout pass:changeit

Write-Host "Certificato generato in $CertDir :"
Write-Host "  - localhost-cert.pem"
Write-Host "  - localhost-key.pem"
Write-Host "  - localhost.p12   (keystore per il connector HTTPS di Tomcat, password: changeit)"
Write-Host ""
Write-Host "Attenzione: e' un certificato AUTOFIRMATO, valido solo per sviluppo locale."
Write-Host "Il browser mostrera' un avviso 'connessione non sicura' finche' non lo"
Write-Host "accetti manualmente (o lo importi tra le CA attendibili del sistema)."
