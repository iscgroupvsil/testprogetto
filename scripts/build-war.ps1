<#
.SYNOPSIS
  Genera il pacchetto .war della PWA, pronto per essere copiato in
  %CATALINA_HOME%\webapps\ di Tomcat, senza toccare nessun'altra webapp.
  Versione Windows (PowerShell). Costruisce lo zip a basso livello con
  System.IO.Compression (nessuna dipendenza esterna da zip/jar), usando
  sempre "/" come separatore nei nomi delle voci: Compress-Archive su
  Windows le scrive con "\", e Tomcat (ExpandWar) non riconosce il
  backslash come separatore di percorso nello zip, con il risultato che
  fallisce a creare le sottocartelle (es. icons\) durante lo scompattamento
  del WAR.

.USO
  cd testprogetto
  .\scripts\build-war.ps1                  # context path di default: notifiche-pwa
  .\scripts\build-war.ps1 -ContextName mia-pwa

  Se PowerShell blocca l'esecuzione degli script, avvialo una volta con:
    Set-ExecutionPolicy -Scope Process -ExecutionPolicy Bypass
#>

param(
    [string]$ContextName = "notifiche-pwa"
)

$ErrorActionPreference = "Stop"

Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

$RootDir  = Split-Path -Parent $PSScriptRoot
$DistDir  = Join-Path $RootDir "dist"
$StageDir = Join-Path ([System.IO.Path]::GetTempPath()) ("pwa-stage-" + [System.Guid]::NewGuid())
$WarPath  = Join-Path $DistDir "$ContextName.war"

New-Item -ItemType Directory -Force -Path $DistDir | Out-Null
New-Item -ItemType Directory -Force -Path $StageDir | Out-Null

try {
    # Copia solo i file che devono finire nella webapp (niente certs/,
    # server.js, script di sviluppo, README, .git...).
    Copy-Item (Join-Path $RootDir "index.html") $StageDir
    Copy-Item (Join-Path $RootDir "style.css") $StageDir
    Copy-Item (Join-Path $RootDir "app.js") $StageDir
    Copy-Item (Join-Path $RootDir "sw.js") $StageDir
    Copy-Item (Join-Path $RootDir "manifest.webmanifest") $StageDir
    Copy-Item (Join-Path $RootDir "icons") $StageDir -Recurse
    New-Item -ItemType Directory -Force -Path (Join-Path $StageDir "WEB-INF") | Out-Null
    Copy-Item (Join-Path $RootDir "WEB-INF\web.xml") (Join-Path $StageDir "WEB-INF")

    if (Test-Path $WarPath) { Remove-Item $WarPath -Force }

    $zip = [System.IO.Compression.ZipFile]::Open($WarPath, [System.IO.Compression.ZipArchiveMode]::Create)
    try {
        $stagePrefixLength = $StageDir.TrimEnd('\').Length + 1
        Get-ChildItem -Path $StageDir -Recurse -File | ForEach-Object {
            # Nome della voce nello zip: percorso relativo alla cartella di
            # staging, SEMPRE con "/" come separatore (richiesto dallo
            # standard ZIP e da Tomcat), indipendentemente dal fatto che
            # Windows usi "\" sul filesystem.
            $entryName = $_.FullName.Substring($stagePrefixLength) -replace '\\', '/'
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile(
                $zip, $_.FullName, $entryName,
                [System.IO.Compression.CompressionLevel]::Optimal
            ) | Out-Null
        }
    }
    finally {
        $zip.Dispose()
    }

    Write-Host "Pacchetto creato: $WarPath"
    Write-Host ""
    Write-Host "Deploy:"
    Write-Host "  copy `"$WarPath`" `"%CATALINA_HOME%\webapps\`""
    Write-Host "  (Tomcat con autoDeploy attivo la pubblica da sola in pochi secondi,"
    Write-Host "   altrimenti riavvia Tomcat)"
    Write-Host ""
    Write-Host "Sara' raggiungibile su:  https://<host>[:porta]/$ContextName/"
}
finally {
    Remove-Item -Recurse -Force $StageDir -ErrorAction SilentlyContinue
}
