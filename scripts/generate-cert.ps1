<#
.SYNOPSIS
  Genera un certificato TLS autofirmato per sviluppo/deploy locale
  (localhost/127.0.0.1) e il relativo keystore PKCS12 per Tomcat, su
  Windows (PowerShell).

.PARAMETER AdditionalHosts
  IP o hostname aggiuntivi da includere nel Subject Alternative Name,
  oltre a localhost/127.0.0.1/::1. Utile quando il server (es. Tomcat)
  viene raggiunto tramite un IP di rete reale.

.USO
  cd testprogetto
  .\scripts\generate-cert.ps1
  .\scripts\generate-cert.ps1 -AdditionalHosts 10.10.15.43

  Se PowerShell blocca l'esecuzione degli script, avvialo una volta con:
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#>

param(
    [string[]]$AdditionalHosts = @()
)

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

# openssl scrive messaggi di avanzamento (es. "Generating a RSA private
# key") su stderr: e' normale, non un errore. Con $ErrorActionPreference
# = "Stop" attivo, PowerShell tratterebbe comunque quell'output come un
# errore bloccante (a prescindere da come lo si redirige dopo), quindi
# per la durata della chiamata nativa lo abbassiamo a "Continue" e
# verifichiamo l'esito reale con $LASTEXITCODE.
function Invoke-OpenSsl {
    param([string[]]$Arguments)
    $previousPreference = $ErrorActionPreference
    $ErrorActionPreference = "Continue"
    try {
        & openssl @Arguments
    } finally {
        $ErrorActionPreference = $previousPreference
    }
    if ($LASTEXITCODE -ne 0) {
        throw "openssl ha restituito un errore (exit code $LASTEXITCODE): openssl $($Arguments -join ' ')"
    }
}

$SanEntries = @("DNS:localhost", "IP:127.0.0.1", "IP:::1")
foreach ($h in $AdditionalHosts) {
    if ($h -match '^\d+\.\d+\.\d+\.\d+$' -or $h -match ':') {
        $SanEntries += "IP:$h"
    } else {
        $SanEntries += "DNS:$h"
    }
}
$San = $SanEntries -join ","

$keyPath  = Join-Path $CertDir "localhost-key.pem"
$certPath = Join-Path $CertDir "localhost-cert.pem"
$p12Path  = Join-Path $CertDir "localhost.p12"

Invoke-OpenSsl @(
    "req", "-x509", "-nodes", "-newkey", "rsa:2048", "-sha256", "-days", "825",
    "-keyout", $keyPath,
    "-out", $certPath,
    "-subj", "/CN=localhost",
    "-addext", "subjectAltName=$San"
)

# Keystore PKCS12 per il connector HTTPS di Tomcat (server.xml).
# Password fissa "changeit" per comodita' di sviluppo: per un ambiente
# reale rigenera con una password propria.
Invoke-OpenSsl @(
    "pkcs12", "-export",
    "-in", $certPath, "-inkey", $keyPath,
    "-out", $p12Path, "-name", "tomcat",
    "-passout", "pass:changeit"
)

Write-Host ""
Write-Host "Certificato generato in $CertDir :"
Write-Host "  - localhost-cert.pem"
Write-Host "  - localhost-key.pem"
Write-Host "  - localhost.p12   (keystore per il connector HTTPS di Tomcat, password: changeit)"
Write-Host "  SAN incluso: $San"
Write-Host ""
Write-Host "Attenzione: e' un certificato AUTOFIRMATO, valido solo per sviluppo/uso interno."
Write-Host "Il browser mostrera' un avviso 'connessione non sicura' finche' non lo"
Write-Host "accetti manualmente (o lo importi tra le CA attendibili del sistema)."
