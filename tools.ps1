<# 
    Script: Instalador-Apps.ps1
    Compatibilidad: PowerShell 2.0+
    Funciones:
      - Elegir gestor: Chocolatey o winget
      - Instalar gestor si falta (best-effort)
      - Menú: Listar apps, Instalar todas, Instalar seleccionadas, Actualizar todo
    Uso:
      1) Ejecutar PowerShell como Administrador
      2) Set-ExecutionPolicy Bypass -Scope Process -Force
      3) .\Instalador-Apps.ps1
#>

# =========================
# Utilidades (compatibles PS2)
# =========================

function Pausa {
  Write-Host ""
  $null = Read-Host "Presiona [Enter] para continuar..."
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

# =========================
# Catálogo de aplicaciones
#   - Clave: nombre amigable
#   - Valor: IDs para cada gestor
# =========================

# Nota: Puedes agregar/quitar apps sin romper el menú.
$Apps = @(
  @{ Nombre="Discord";             ChocoId="discord";                 WingetId="Discord.Discord" }
  @{ Nombre="Google Chrome";       ChocoId="googlechrome";            WingetId="Google.Chrome" }
  @{ Nombre="VLC";                 ChocoId="vlc";                     WingetId="VideoLAN.VLC" }
  @{ Nombre="7-Zip";               ChocoId="7zip";                    WingetId="7zip.7zip" }
  @{ Nombre="OBS Studio";          ChocoId="obs-studio";              WingetId="OBSProject.OBSStudio" }
  @{ Nombre="Node.js LTS";         ChocoId="nodejs-lts";              WingetId="OpenJS.NodeJS.LTS" }
  @{ Nombre="Python 3.x";          ChocoId="python";                  WingetId="Python.Python.3.12" }
  @{ Nombre="Git";                 ChocoId="git";                     WingetId="Git.Git" }
  @{ Nombre="Visual Studio Code";  ChocoId="vscode";                  WingetId="Microsoft.VisualStudioCode" }
  @{ Nombre="FFmpeg";              ChocoId="ffmpeg";                  WingetId="FFmpeg.FFmpeg" }
  @{ Nombre="ImageMagick";         ChocoId="imagemagick.app";         WingetId="ImageMagick.ImageMagick" }
  @{ Nombre="yt-dlp";              ChocoId="yt-dlp";                  WingetId="yt-dlp.yt-dlp" }
  @{ Nombre="VirtualBox";          ChocoId="virtualbox";              WingetId="Oracle.VirtualBox" }
  @{ Nombre="Tesseract OCR";       ChocoId="tesseract";               WingetId="tesseract-ocr.tesseract" }
  @{ Nombre="Google Drive";        ChocoId="googledrive";             WingetId="Google.Drive" }
  @{ Nombre="HandBrake";           ChocoId="handbrake.install";       WingetId="HandBrake.HandBrake" }
  @{ Nombre="Steam";               ChocoId="steam";                   WingetId="Valve.Steam" }
)

# =========================
# Operaciones por gestor
# =========================

function Choco-Listar {
  Write-Host "`nCatálogo disponible (Chocolatey IDs):`n" -ForegroundColor Cyan
  $i = 1
  foreach ($a in $Apps) {
    Write-Host ("[{0}] {1}  ->  {2}" -f $i, $a.Nombre, $a.ChocoId)
    $i++
  }
}

function Winget-Listar {
  Write-Host "`nCatálogo disponible (winget IDs):`n" -ForegroundColor Cyan
  $i = 1
  foreach ($a in $Apps) {
    Write-Host ("[{0}] {1}  ->  {2}" -f $i, $a.Nombre, $a.WingetId)
    $i++
  }
}

function Choco-Instalar {
  param([string[]]$ids)
  foreach ($id in $ids) {
    Write-Host "Instalando $id con Chocolatey..." -ForegroundColor Cyan
    cmd /c "choco install $id -y --no-progress"
  }
}

function Winget-Instalar {
  param([string[]]$ids)
  foreach ($id in $ids) {
    Write-Host "Instalando $id con winget..." -ForegroundColor Cyan
    # --silent para reducir prompts; se aceptan acuerdos automáticamente
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

# =========================
# Menú principal
# =========================

function Elegir-Gestor {
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
