function Pausa {
  Write-Host ""
  $null = Read-Host "Presiona [Enter] para continuar..."
    cls
}

function EsAdmin {
  $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
  $principal   = New-Object Security.Principal.WindowsPrincipal($currentUser)
  return $principal.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if (-not (EsAdmin)) {
  Write-Host "Este script requiere ejecutar PowerShell como **Administrador**." -ForegroundColor Yellow
  Pausa
  return
}

function TryEnable-TLS {
  # En PS 2.0 no existe Tls12; probamos opciones disponibles.
  try {
    # Si existe el tipo, lo ajustamos; en .NET viejas puede fallar silenciosamente.
    [void][System.Net.ServicePointManager]::SecurityProtocol
    $proto = [System.Net.ServicePointManager]::SecurityProtocol
    # Intento agregar Tls si no está
    if (($proto -band [Net.SecurityProtocolType]::Tls) -eq 0) {
      [System.Net.ServicePointManager]::SecurityProtocol = $proto -bor [Net.SecurityProtocolType]::Tls
    }
  } catch { }
}

function Get-Exe {
  param([string]$name)
  $paths = $env:PATH -split ';'
  foreach ($p in $paths) {
    $candidate = Join-Path $p $name
    if (Test-Path $candidate) { return $candidate }
    # también probamos con .exe
    $candidate = Join-Path $p ($name + ".exe")
    if (Test-Path $candidate) { return $candidate }
  }
  return $null
}

# =========================
# Verificación / Instalación de gestores
# =========================

function Existe-Choco { return [bool](Get-Exe "choco") }
function Existe-Winget { return [bool](Get-Exe "winget") }

function Instalar-Choco {
  Write-Host "Instalando Chocolatey..." -ForegroundColor Cyan
  TryEnable-TLS
  try {
    # Instalador oficial simplificado compatible con PS 2.0
    $wc = New-Object System.Net.WebClient
    $wc.Headers.Add("user-agent","Mozilla/5.0")
    $script = $wc.DownloadString("https://community.chocolatey.org/install.ps1")
    Invoke-Expression $script
    Write-Host "Chocolatey instalado (si no hubo errores). Cierra y abre una nueva consola si no se reconoce 'choco'." -ForegroundColor Green
  } catch {
    Write-Host "No se pudo descargar el instalador de Chocolatey desde HTTPS (posible TLS antiguo)." -ForegroundColor Yellow
    Write-Host "Alternativa: ejecuta manualmente (en una consola con Internet):" -ForegroundColor Yellow
    Write-Host '  @"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((new-object net.webclient).DownloadString(''https://community.chocolatey.org/install.ps1''))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"' -ForegroundColor Gray
    Pausa
  }
}

function Instalar-Winget {
  Write-Host "Instalar winget requiere Windows 10/11 y Microsoft Store (App Installer)." -ForegroundColor Yellow
  Write-Host "Intentaré abrir la página de App Installer en la Microsoft Store..." -ForegroundColor Cyan
  try {
    # Abre la Store para App Installer (winget) - el usuario solo debe pulsar "Obtener/Instalar"
    Start-Process "ms-windows-store://pdp/?productid=9NBLGGH4NNS1" | Out-Null
    Write-Host "Cuando finalice la instalación de 'App Installer', vuelve a ejecutar este script." -ForegroundColor Green
  } catch {
    Write-Host "No pude abrir la Microsoft Store automáticamente." -ForegroundColor Yellow
    Write-Host "Instálalo manualmente buscando 'App Installer' en la Store, o descarga el MSIXBundle desde GitHub (Microsoft.WinGet.Client)." -ForegroundColor Yellow
  }
  Pausa
}

$Apps = @(
  # =========================
  # Web / Navegación y Nube
  # =========================
  @{ Nombre="Google Chrome";  ChocoId="googlechrome";            WingetId="Google.Chrome" }
  @{ Nombre="Google Drive";   ChocoId="googledrive";             WingetId="Google.Drive" }
  # =========================
  # Comunicaciones / Productividad
  # =========================
  @{ Nombre="Discord";        ChocoId="discord";                 WingetId="Discord.Discord" }
  @{ Nombre="TeamViewer";     ChocoId="teamviewer";              WingetId="TeamViewer.TeamViewer" }
  @{ Nombre="TeamSpeak";      ChocoId="teamspeak";               WingetId="TeamSpeakSystems.TeamSpeakClient" } # (TS5 puede diferir)
  @{ Nombre="Thunderbird ESR";ChocoId="thunderbird";             WingetId="Mozilla.Thunderbird" } # ESR/estable varía por canal
  # =========================
  # Gaming / Launchers y utilidades
  # =========================
  @{ Nombre="Steam";          ChocoId="steam";                   WingetId="Valve.Steam" }
  @{ Nombre="EA app";         ChocoId="";                        WingetId="ElectronicArts.EADesktop" }
  @{ Nombre="MSI Afterburner";ChocoId="msiafterburner";          WingetId="Guru3D.MSIAfterburner" }
  @{ Nombre="RivaTuner Statistics Server"; ChocoId="rtss";       WingetId="TechPowerUp.RTSS" }
  # =========================
  # Multimedia / Edición y Streaming
  # =========================
  @{ Nombre="VLC media player"; ChocoId="vlc";                   WingetId="VideoLAN.VLC" }
  @{ Nombre="HandBrake";      ChocoId="handbrake.install";       WingetId="HandBrake.HandBrake" }
  @{ Nombre="OBS Studio";     ChocoId="obs-studio";              WingetId="OBSProject.OBSStudio" }
  @{ Nombre="REAPER (x64)";   ChocoId="reaper";                  WingetId="Cockos.REAPER" }
  @{ Nombre="ImageMagick";    ChocoId="imagemagick.app";         WingetId="ImageMagick.ImageMagick" }
  @{ Nombre="FFmpeg";         ChocoId="ffmpeg";                  WingetId="FFmpeg.FFmpeg" }
  @{ Nombre="yt-dlp";         ChocoId="yt-dlp";                  WingetId="yt-dlp.yt-dlp" }
  # =========================
  # Desarrollo / Herramientas y Virtualización
  # =========================
  @{ Nombre="Node.js LTS";    ChocoId="nodejs-lts";              WingetId="OpenJS.NodeJS.LTS" }
  @{ Nombre="Python 3.12 (x64)"; ChocoId="python";               WingetId="Python.Python.3.12" }
  @{ Nombre="PowerShell 7 (x64)"; ChocoId="powershell-core";     WingetId="Microsoft.PowerShell" }
  @{ Nombre="VirtualBox";     ChocoId="virtualbox";              WingetId="Oracle.VirtualBox" }
  @{ Nombre="Tesseract OCR";  ChocoId="tesseract";               WingetId="tesseract-ocr.tesseract" }
  # =========================
  # Utilidades del sistema / Archivo
  # =========================
  @{ Nombre="7-Zip";          ChocoId="7zip";                    WingetId="7zip.7zip" }
  # =========================
  # Runtimes de alto impacto (.NET)
  # =========================
  @{ Nombre=".NET Framework 4.8";              ChocoId="dotnetfx";                     WingetId="Microsoft.DotNet.Framework.4.8" }
  @{ Nombre=".NET Desktop Runtime 9 (x64)";    ChocoId="dotnet-9.0-desktopruntime";    WingetId="Microsoft.DotNet.DesktopRuntime.9" }
  @{ Nombre=".NET Desktop Runtime 8 (x64)";    ChocoId="dotnet-desktopruntime";        WingetId="Microsoft.DotNet.DesktopRuntime.8" }
)
function Choco-Listar {
  Write-Host "`nCatálogo disponible (Chocolatey IDs):`n" -ForegroundColor Cyan
  $half = [math]::Ceiling($Apps.Count / 2)
  for ($i = 0; $i -lt $half; $i++) {
    $leftIndex  = $i
    $rightIndex = $i + $half
    $leftText = "[{0,2}] {1,-30} -> {2,-25}" -f ($leftIndex + 1), $Apps[$leftIndex].Nombre, $Apps[$leftIndex].ChocoId
    if ($rightIndex -lt $Apps.Count) {
      $rightText = "[{0,2}] {1,-30} -> {2}" -f ($rightIndex + 1), $Apps[$rightIndex].Nombre, $Apps[$rightIndex].ChocoId
    } else {
      $rightText = ""
    }
    Write-Host ($leftText + "   " + $rightText)
  }
}
function Winget-Listar {
  Write-Host "`nCatálogo disponible (winget IDs):`n" -ForegroundColor Cyan
  $half = [math]::Ceiling($Apps.Count / 2)
  for ($i = 0; $i -lt $half; $i++) {
    $leftIndex  = $i
    $rightIndex = $i + $half
    $leftText = "[{0,2}] {1,-30} -> {2,-30}" -f ($leftIndex + 1), $Apps[$leftIndex].Nombre, $Apps[$leftIndex].WingetId
    if ($rightIndex -lt $Apps.Count) {
      $rightText = "[{0,2}] {1,-30} -> {2}" -f ($rightIndex + 1), $Apps[$rightIndex].Nombre, $Apps[$rightIndex].WingetId
    } else {
      $rightText = ""
    }
    Write-Host ($leftText + "   " + $rightText)
  }
}
function Choco-Instalar { param([string[]]$ids)
  foreach ($id in $ids) {
    if ([string]::IsNullOrEmpty($id)) { continue }
    Write-Host "Instalando $id con Chocolatey..." -ForegroundColor Cyan
    cmd /c "choco install $id -y --no-progress"
  }
}
function Winget-Instalar { param([string[]]$ids)
  foreach ($id in $ids) {
    if ([string]::IsNullOrEmpty($id)) { continue }
    Write-Host "Instalando $id con winget..." -ForegroundColor Cyan
    cmd /c "winget install --id `"$id`" --accept-package-agreements --accept-source-agreements --silent"
  }
}
function Choco-ActualizarTodo {
  Write-Host "Actualizando todas las apps administradas por Chocolatey..." -ForegroundColor Cyan
  cmd /c "choco upgrade all -y --no-progress"
}
function Winget-ActualizarTodo {
  Write-Host "Actualizando todas las apps administradas por winget..." -ForegroundColor Cyan
  # Primero actualizamos el origen e instalamos upgrades
  cmd /c "winget source update"
  cmd /c "winget upgrade --all --accept-package-agreements --accept-source-agreements --silent"
}
function Elegir-Gestor {
  cls
  Write-Host "====================================="
  Write-Host "  Instalador de Aplicaciones (PS2.0) "
  Write-Host "====================================="

  Write-Host ""
  Write-Host "Elige el gestor de paquetes:"
  Write-Host "  1) Chocolatey"
  Write-Host "  2) winget"
  Write-Host "  0) Salir"
  $op = Read-Host "Opción"

  if ($op -eq "1") { return "choco" }
  if ($op -eq "2") { return "winget" }
  if ($op -eq "0") { return $null }
  Write-Host "Opción no válida." -ForegroundColor Yellow
  return (Elegir-Gestor)
}

function Asegurar-Gestor {
  param([string]$gestor)

  if ($gestor -eq "choco") {
    if (-not (Existe-Choco)) { Instalar-Choco }
    if (-not (Existe-Choco)) {
      Write-Host "Chocolatey no está disponible. No puedo continuar con este gestor." -ForegroundColor Red
      return $false
    }
    return $true
  }

  if ($gestor -eq "winget") {
    if (-not (Existe-Winget)) { Instalar-Winget }
    if (-not (Existe-Winget)) {
      Write-Host "winget no está disponible. No puedo continuar con este gestor." -ForegroundColor Red
      return $false
    }
    return $true
  }
  return $false
}

function Menu-Acciones {
  param([string]$gestor)

  while ($true) {
  cls
    Write-Host "`nGestor activo: $gestor" -ForegroundColor Green
    Write-Host "Acciones:"
    Write-Host "  1) Listar catálogo"
    Write-Host "  2) Instalar TODO el catálogo"
    Write-Host "  3) Instalar apps seleccionadas"
    Write-Host "  4) Actualizar TODO (ya instaladas)"
    Write-Host "  9) Cambiar de gestor"
    Write-Host "  0) Salir"
    $acc = Read-Host "Opción"

    if ($acc -eq "1") {
      if ($gestor -eq "choco") { Choco-Listar } else { Winget-Listar }
      Pausa
    }
    elseif ($acc -eq "2") {
      # Instalar todas
      $ids = @()
      foreach ($a in $Apps) {
        if ($gestor -eq "choco") { $ids += $a.ChocoId } else { $ids += $a.WingetId }
      }
      if ($gestor -eq "choco") { Choco-Instalar -ids $ids } else { Winget-Instalar -ids $ids }
      Pausa
    }
    elseif ($acc -eq "3") {
      # Instalar seleccionadas por número separado por comas
      if ($gestor -eq "choco") { Choco-Listar } else { Winget-Listar }
      $sel = Read-Host "Escribe los números separados por coma (ej. 1,3,5)"
      $nums = $sel -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' }
      if ($nums.Count -eq 0) {
        Write-Host "Selección vacía o inválida." -ForegroundColor Yellow
      } else {
        $ids = @()
        for ($i=0; $i -lt $nums.Count; $i++) {
          $idx = [int]$nums[$i] - 1
          if ($idx -ge 0 -and $idx -lt $Apps.Count) {
            if ($gestor -eq "choco") { $ids += $Apps[$idx].ChocoId } else { $ids += $Apps[$idx].WingetId }
          }
        }
        if ($ids.Count -gt 0) {
          if ($gestor -eq "choco") { Choco-Instalar -ids $ids } else { Winget-Instalar -ids $ids }
        } else {
          Write-Host "No se seleccionaron elementos válidos." -ForegroundColor Yellow
        }
      }
      Pausa
    }
    elseif ($acc -eq "4") {
      if ($gestor -eq "choco") { Choco-ActualizarTodo } else { Winget-ActualizarTodo }
      Pausa
    }
    elseif ($acc -eq "9") {
      return "cambiar"
    }
    elseif ($acc -eq "0") {
      return "salir"
    }
    else {
      Write-Host "Opción no válida." -ForegroundColor Yellow
    }
  }
}
# =========================
# Flujo principal
# =========================
while ($true) {
  $gestor = Elegir-Gestor
  if (-not $gestor) { break }

  if (-not (Asegurar-Gestor $gestor)) {
    Pausa
    continue
  }

  $res = Menu-Acciones $gestor
  if ($res -eq "salir") { break }
  if ($res -eq "cambiar") { continue }
}

Write-Host "`n¡Listo! Gracias por usar el instalador." -ForegroundColor Green
