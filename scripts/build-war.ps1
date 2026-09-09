<#
.SYNOPSIS
  Genera il pacchetto .war della PWA, pronto per essere copiato in
  %CATALINA_HOME%\webapps\ di Tomcat, senza toccare nessun'altra webapp.
  Versione Windows (PowerShell), usa Compress-Archive (nessuna dipendenza
  esterna: niente bisogno di zip/jar installati a parte).

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
    $tmpZip = Join-Path $DistDir "$ContextName.zip"
    if (Test-Path $tmpZip) { Remove-Item $tmpZip -Force }

    Compress-Archive -Path (Join-Path $StageDir "*") -DestinationPath $tmpZip -Force
    Move-Item $tmpZip $WarPath -Force

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
