cls
function Pausa {
  Write-Host ""
  Write-Host "Presiona [Enter] para continuar..." -ForegroundColor Yellow -NoNewline
  [void][System.Console]::ReadLine()
}
function Ask([string]$msg) {
    if (-not [string]::IsNullOrWhiteSpace($msg)) {
        Write-Host $msg -ForegroundColor Yellow -NoNewline
        Write-Host ": " -NoNewline
    }
    return [System.Console]::ReadLine()
}
function UI-GetWidth {
  try { return [System.Console]::WindowWidth } catch { return 80 }
}
function UI-Separador {
  param([string]$char = "=")
  $w = UI-GetWidth
  Write-Host ($char * $w) -ForegroundColor DarkCyan
}
function UI-Titulo {
  param(
    [Parameter(Mandatory=$true)][string]$Titulo,
    [string]$Subtitulo
  )
  cls
  $w   = UI-GetWidth
  $top = ("=" * $w)
  $bot = ("=" * $w)
  Write-Host $top -ForegroundColor Cyan
  $lineTitle = " $Titulo "
  Write-Host ($lineTitle.PadRight($w)) -ForegroundColor Cyan
  if ($Subtitulo) {
    $lineSub = " $Subtitulo "
    Write-Host ($lineSub.PadRight($w)) -ForegroundColor DarkCyan
  }
  Write-Host $bot -ForegroundColor Cyan
  Write-Host ""
}
function UI-Hint {
  param([string]$Texto)
  if (-not [string]::IsNullOrWhiteSpace($Texto)) {
    Write-Host $Texto -ForegroundColor DarkGray
  }
}
function Mostrar-VersionPS {
  try {
    if ($PSVersionTable) {
      $ver = $PSVersionTable.PSVersion
      $ed  = $PSVersionTable.PSEdition
    } else {
      $ver = $host.Version
      $ed  = "Desktop"
    }
  } catch {
    $ver = $host.Version
    $ed  = "Desktop"
  }
  Write-Host ""
  Write-Host "=====================================" -ForegroundColor Cyan
  Write-Host ("  PowerShell actual : {0}  ({1})" -f $ver, $ed) -ForegroundColor Cyan
  Write-Host "=====================================" -ForegroundColor Cyan
  if ($ver.Major -le 2) {
    Write-Host "Estás en PowerShell 2.x (muy antiguo). Te conviene instalar PowerShell 7 y, si usas módulos legados, considerar Windows PowerShell 5.1." -ForegroundColor Yellow
  }
}
Mostrar-VersionPS
function Actualizar-PowerShell {
  param([string]$gestor)
  Write-Host ""
  Write-Host "Actualización de PowerShell:" -ForegroundColor Green
  Write-Host "  1) Instalar/Actualizar PowerShell 7 (recomendado, side-by-side)"
  Write-Host "  2) Información para Windows PowerShell 5.1 (WMF 5.1)"
  Write-Host "  0) Volver"
  $opc = Ask "Opción"
  if ($opc -eq "1") {
    if ($gestor -eq "choco") {
      Choco-Instalar -ids @("powershell-core")
    } elseif ($gestor -eq "winget") {
      Winget-Instalar -ids @("Microsoft.PowerShell")
    } else {
      Write-Host "Gestor desconocido. Usa Chocolatey o winget." -ForegroundColor Yellow
      return
    }
    try {
      if (Set-WindowsTerminalDefaultPwsh) {
        Write-Host "PS7 quedó como predeterminado en Windows Terminal." -ForegroundColor Green
      } else {
        Write-Host "No se pudo establecer PS7 como predeterminado en Windows Terminal (ver mensajes arriba)." -ForegroundColor Yellow
      }
    } catch {
      Write-Host "Ocurrió un error al configurar Windows Terminal: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    return
  }
  if ($opc -eq "2") {
    Write-Host ""
    Write-Host "Windows PowerShell 5.1 es la última versión de la rama clásica." -ForegroundColor Cyan
    Write-Host "Requiere SO compatible y se instala mediante WMF 5.1." -ForegroundColor Cyan
    Write-Host "Abriré la página oficial para descargar WMF 5.1..." -ForegroundColor Cyan
    try {
      Start-Process "https://aka.ms/wmf5download" | Out-Null
    } catch {
      Write-Host "No pude abrir el navegador. Abre manualmente: https://aka.ms/wmf5download" -ForegroundColor Yellow
    }
    Pausa
    return
  }
  return
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
  try {
    [void][System.Net.ServicePointManager]::SecurityProtocol
    $proto = [System.Net.ServicePointManager]::SecurityProtocol
    if (($proto -band [Net.SecurityProtocolType]::Tls) -eq 0) {
      [System.Net.ServicePointManager]::SecurityProtocol = $proto -bor [Net.SecurityProtocolType]::Tls
    }
  } catch { }
}
function Get-Exe {
  param([string]$name)
  $paths = $env:PATH -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
  foreach ($p in $paths) {
    $candidate = Join-Path $p $name
    if (Test-Path $candidate) { return $candidate }
    $candidate = Join-Path $p ($name + ".exe")
    if (Test-Path $candidate) { return $candidate }
  }
  return $null
}
function Remove-JsonComments {
  param([Parameter(Mandatory=$true)][string]$JsonWithComments)
  $noBlock = [regex]::Replace($JsonWithComments, '/\*.*?\*/', '', 'Singleline')
  $noLine  = $noBlock -split "`n" | ForEach-Object {
    $line = $_
    if ($line -match '^\s*//') { '' }
    else {
      $idx = $line.IndexOf('//')
      if ($idx -ge 0 -and ($line.Substring(0,$idx) -notmatch 'https?:$')) {
        $line.Substring(0,$idx)
      } else { $line }
    }
  } | Out-String
  return $noLine
}
function Get-WT-SettingsPath {
  $store     = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminal_8wekyb3d8bbwe\LocalState\settings.json"
  $storePrev = Join-Path $env:LOCALAPPDATA "Packages\Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe\LocalState\settings.json"
  $unpkg     = Join-Path $env:LOCALAPPDATA "Microsoft\Windows Terminal\settings.json"
  foreach ($p in @($store, $storePrev, $unpkg)) { if (Test-Path $p) { return $p } }
  return $store
}
function Set-WindowsTerminalDefaultPwsh {
  [CmdletBinding()]
  param()
  $pwshCmd = Get-Command pwsh -ErrorAction SilentlyContinue
  $pwshExe = if ($pwshCmd) {
    $pwshCmd.Source
  } else {
    @(
      "$env:ProgramFiles\PowerShell\7\pwsh.exe",
      "$env:ProgramFiles(x86)\PowerShell\7\pwsh.exe"
    ) | Where-Object { Test-Path $_ } | Select-Object -First 1
  }
  if (-not $pwshExe) {
    Write-Host "No encontré pwsh.exe. (Instala PowerShell 7 primero)" -ForegroundColor Yellow
    return $false
  }
  $wt = Get-Command wt -ErrorAction SilentlyContinue
  if (-not $wt) {
    Write-Host "Windows Terminal no parece estar instalado (no se encontró 'wt')." -ForegroundColor Yellow
    Write-Host "Instálalo con: winget install --id Microsoft.WindowsTerminal" -ForegroundColor Yellow
    return $false
  }
  $settingsPath = Get-WT-SettingsPath
  $settingsDir  = Split-Path $settingsPath -Parent
  if (-not (Test-Path $settingsDir)) {
    New-Item -ItemType Directory -Path $settingsDir -Force | Out-Null
  }
  $json = $null
  if (Test-Path $settingsPath) {
    try {
      $raw   = Get-Content $settingsPath -Raw -ErrorAction Stop
      $clean = Remove-JsonComments -JsonWithComments $raw
      $tmp   = $clean | ConvertFrom-Json -ErrorAction Stop
      if ($tmp -and $tmp.profiles) {
        $json = $tmp
      }
    } catch {
      Write-Host "Advertencia: settings.json actual no se pudo leer/parsear, se generará uno nuevo." -ForegroundColor Yellow
      $json = $null
    }
  }
  if (-not $json) {
    $newGuid = "{"+([guid]::NewGuid().ToString())+"}"
    $json = [PSCustomObject]@{
      "$schema"      = "https://aka.ms/terminal-profiles-schema"
      defaultProfile = $newGuid
      profiles       = [PSCustomObject]@{
        list = @(
          [PSCustomObject]@{
            guid        = $newGuid
            name        = "PowerShell 7"
            commandline = "`"$pwshExe`" -NoExit -NoProfile"
            hidden      = $false
          }
        )
      }
    }
    Write-Host "Creando settings.json mínimo para Windows Terminal..." -ForegroundColor Cyan
  }
  else {
    if (-not $json.profiles) {
      $json | Add-Member -NotePropertyName profiles -NotePropertyValue ([PSCustomObject]@{ list = @() }) -Force
    }
    if (-not $json.profiles.list) {
      $json.profiles | Add-Member -NotePropertyName list -NotePropertyValue @() -Force
    }
    if ($json.profiles.list -isnot [System.Collections.IList]) {
      $json.profiles.list = @($json.profiles.list)
    }
    $profilesList = $json.profiles.list
    $pwshProfile = $profilesList | Where-Object {
      ($_.commandline -and $_.commandline -match 'pwsh(?:\.exe)?') -or
      ($_.name -match 'PowerShell 7')
    } | Select-Object -First 1
    if (-not $pwshProfile) {
      $winps = $profilesList | Where-Object { $_.name -eq 'Windows PowerShell' } | Select-Object -First 1
      if ($winps) {
        $winps.commandline = "`"$pwshExe`" -NoExit -NoProfile"
        if (-not $winps.guid) { $winps.guid = "{"+([guid]::NewGuid().ToString())+"}" }
        $pwshProfile = $winps
        Write-Host "Perfil 'Windows PowerShell' apuntado a pwsh.exe" -ForegroundColor Green
      }
      else {
        $newGuid = "{"+([guid]::NewGuid().ToString())+"}"
        $newProf = [PSCustomObject]@{
          guid        = $newGuid
          name        = "PowerShell 7"
          commandline = "`"$pwshExe`" -NoExit -NoProfile"
          hidden      = $false
        }
        $json.profiles.list += $newProf
        $pwshProfile = $newProf
        Write-Host "Perfil nuevo 'PowerShell 7' creado." -ForegroundColor Green
      }
    }
    else {
      $pwshProfile.commandline = "`"$pwshExe`" -NoExit -NoProfile"
      if (-not $pwshProfile.guid) {
        $pwshProfile.guid = "{"+([guid]::NewGuid().ToString())+"}"
      }
    }
    $json.defaultProfile = $pwshProfile.guid
  }
  $bak = "$settingsPath.bak.$((Get-Date).ToString('yyyyMMddHHmmss'))"
  try {
    if (Test-Path $settingsPath) {
      Copy-Item $settingsPath $bak -Force
    }
  } catch { }

  $out = $json | ConvertTo-Json -Depth 99
  Set-Content -Path $settingsPath -Value $out -Encoding UTF8

  Write-Host "✅ Windows Terminal configurado. Perfil por omisión: PowerShell 7" -ForegroundColor Green
  Write-Host "Archivo: $settingsPath" -ForegroundColor DarkGray
  Write-Host "Cierra y vuelve a abrir Windows Terminal para aplicar los cambios." -ForegroundColor DarkGray
  return $true
}
  $script:PaneLines   = New-Object System.Collections.ArrayList
  $script:PaneTopRow  = 0
  $script:PaneHeight  = 12
  $script:PaneWidth   = 80
function UI-GetWidth {
  try { return [System.Console]::WindowWidth } catch { return 100 }
}
function UI-GetHeight {
  try { return [System.Console]::WindowHeight } catch { return 30 }
}
function UI-WriteAt([int]$col,[int]$row,[string]$text) {
  try { [System.Console]::SetCursorPosition([Math]::Max(0,$col), [Math]::Max(0,$row)) } catch { }
  Write-Host ($text.PadRight($script:PaneWidth)) -NoNewline
}
function UI-InitProgress([string]$titulo) {
  $script:PaneWidth  = [Math]::Max(40, (UI-GetWidth))
  $totalH            = (UI-GetHeight)
  $minPanel          = 8     # alto mínimo de panel
  $script:PaneHeight = [Math]::Max($minPanel, [Math]::Min(18, [int]($totalH * 0.45)))
  $script:PaneTopRow = $totalH - $script:PaneHeight
  $sep = ("-" * $script:PaneWidth)
  UI-WriteAt 0 ($script:PaneTopRow)       $sep
  UI-WriteAt 0 ($script:PaneTopRow + 1)   (" Progreso: " + $titulo).PadRight($script:PaneWidth)
  UI-WriteAt 0 ($script:PaneTopRow + 2)   $sep
  $script:PaneLines.Clear() | Out-Null
  for ($r = 3; $r -lt $script:PaneHeight; $r++) {
    UI-WriteAt 0 ($script:PaneTopRow + $r) ""
  }
}
function Buscar-Paquete {
  param([string]$gestor)
  cls
  Write-Host "=== Buscar e instalar paquete ($gestor) ===" -ForegroundColor Cyan
  $texto = Ask "Escribe el nombre del paquete a buscar"
  if ([string]::IsNullOrWhiteSpace($texto)) {
    Write-Host "Texto vacío. Cancelado." -ForegroundColor Yellow
    Pausa
    return
  }
  Write-Host "`nBuscando paquetes, espera..." -ForegroundColor Cyan
  if ($gestor -eq "winget") {
    $resultado = winget search $texto --source winget | Select-Object -Skip 1
    if (-not $resultado) {
      Write-Host "No se encontraron paquetes." -ForegroundColor Yellow
      Pausa
      return
    }
    $lista = @()
    foreach ($linea in $resultado) {
      try {
        $line = $linea.Trim()
        if (-not $line) { continue }
        $cols = $line -split "\s{2,}"
        if ($cols.Count -ge 2) {
          $name = $cols[0]
          $id   = $cols[1]
          $ver  = if ($cols.Count -ge 3) { $cols[2] } else { "" }
          $src  = if ($cols.Count -ge 4) { $cols[3] } else { "winget" }
          $obj = [PSCustomObject]@{
            Name    = $name
            Id      = $id
            Version = $ver
            Source  = $src
          }
          $lista += $obj
        }
      } catch { }
    }
  }
  elseif ($gestor -eq "choco") {
    $raw = choco search $texto --limit-output --verbose | Where-Object { $_ -match '\|' }
    if (-not $raw) {
      Write-Host "No se encontraron paquetes." -ForegroundColor Yellow
      Pausa
      return
    }
    $lista = @()
    foreach ($r in $raw) {
      $cols = $r -split "\|"
      if ($cols.Count -ge 2) {
        $lista += [PSCustomObject]@{
          Name    = $cols[0]
          Id      = $cols[0]
          Version = $cols[1]
          Source  = "chocolatey"
        }
      }
    }
  }
  else {
    Write-Host "Gestor desconocido." -ForegroundColor Red
    Pausa
    return
  }
  if (-not $lista -or $lista.Count -eq 0) {
    Write-Host "No se encontraron paquetes." -ForegroundColor Yellow
    Pausa
    return
  }
  $pageSize = 10       # solo 10 resultados por página
  $offset   = 0        # índice inicial
  $total    = $lista.Count
  while ($true) {
    UI-Titulo -Titulo "Resultados de búsqueda" -Subtitulo "Gestor: $gestor"
    Write-Host ("Mostrando resultados {0}-{1} de {2}" -f ($offset + 1), [Math]::Min($offset + $pageSize, $total), $total) `
      -ForegroundColor White
    Write-Host ""
    $end       = [Math]::Min($offset + $pageSize, $total)
    $indices   = $offset..($end - 1)
    $pageCount = $indices.Count
    $colCount = 2
    $winWidth = 80
    try { $winWidth = [System.Console]::WindowWidth } catch { }
    $colWidth = [Math]::Floor(($winWidth - 4) / $colCount)
    if ($colWidth -lt 30) { $colWidth = 30 }
    $perCol = [math]::Ceiling($pageCount / $colCount)
    for ($i = 0; $i -lt $perCol; $i++) {
      $row1 = ""
      $row2 = ""
      for ($c = 0; $c -lt $colCount; $c++) {
        $idxLocal = $i + ($c * $perCol)
        if ($idxLocal -lt $pageCount) {
          $idxGlobal  = $indices[$idxLocal]
          $item       = $lista[$idxGlobal]
          $displayNum = $idxGlobal + 1
          $line1 = "[{0,2}] {1}" -f $displayNum, $item.Name
          $line2 = "     ID: {0}" -f $item.Id
          if ($item.Version) { $line2 += "  v$($item.Version)" }
          if ($item.Source)  { $line2 += "  [$($item.Source)]" }
          if ($line1.Length -gt $colWidth) {
            $line1 = $line1.Substring(0, $colWidth - 3) + "..."
          }
          if ($line2.Length -gt $colWidth) {
            $line2 = $line2.Substring(0, $colWidth - 3) + "..."
          }
          $row1 += $line1.PadRight($colWidth)
          $row2 += $line2.PadRight($colWidth)
        }
      }
      if ($row1.Trim().Length -gt 0) { Write-Host $row1 }
      if ($row2.Trim().Length -gt 0) { Write-Host $row2 }
      Write-Host ""
    }
    UI-Separador "-"
    UI-Hint "Puedes instalar, ver detalles o pedir más resultados sin salir de esta pantalla."
    Write-Host ""
    Write-Host "Opciones:" -ForegroundColor DarkGray
    Write-Host "  0) Cancelar"
    if ($end -lt $total) {
      Write-Host "  M) Mostrar más resultados (siguientes 10)"
    }
    Write-Host ""
    Write-Host "También puedes:" -ForegroundColor DarkGray
    Write-Host "  - Escribir un número para instalar ese paquete."
    Write-Host "  - Escribir D<num> para ver detalles (ej. D3)." 
    Write-Host ""
    $sel = Ask "Escribe tu opción"
    if ($sel -eq "0" -or [string]::IsNullOrWhiteSpace($sel)) {
      return
    }
    if ($sel -match '^[mM]$') {
      if ($end -ge $total) {
        Write-Host "Ya no hay más resultados para mostrar." -ForegroundColor Yellow
        Pausa
      } else {
        $offset += $pageSize
      }
      continue
    }
    if ($sel -match '^[dD](\d+)$') {
      $n   = [int]$matches[1]
      $pos = $n - 1
      if ($pos -lt 0 -or $pos -ge $lista.Count) {
        Write-Host "Número inválido." -ForegroundColor Yellow
        Pausa
        continue
      }
      $pkg = $lista[$pos]
      Write-Host "`nDetalles de $($pkg.Name)  (ID: $($pkg.Id))`n" -ForegroundColor Cyan
      if ($gestor -eq "winget") {
        winget show $($pkg.Id)
      } else {
        choco info $($pkg.Id)
      }
      Pausa
      continue
    }
    if ($sel -match '^\d+$') {
      $pos = [int]$sel - 1
      if ($pos -lt 0 -or $pos -ge $lista.Count) {
        Write-Host "Opción inválida." -ForegroundColor Yellow
        Pausa
        continue
      }
      $pkg = $lista[$pos]
      $conf = Ask "¿Instalar $($pkg.Name) (ID: $($pkg.Id))? (S/N)"
      if ($conf -notmatch '^[sSyY]$') {
        Write-Host "Instalación cancelada." -ForegroundColor Yellow
        Pausa
        continue
      }
      Write-Host "`nInstalando: $($pkg.Name)  (ID: $($pkg.Id))" -ForegroundColor Green
      if ($gestor -eq "winget") {
        Winget-Instalar -ids @($pkg.Id)
      } else {
        Choco-Instalar -ids @($pkg.Id)
      }
      Pausa
      return
    }
    Write-Host "Entrada no válida. Usa por ejemplo: 3, D3, M o 0." -ForegroundColor Yellow
    Pausa
  }
}
function UI-RefreshProgress {
  $visible = $script:PaneHeight - 3
  $start   = [Math]::Max(0, $script:PaneLines.Count - $visible)
  $slice   = $script:PaneLines[$start..($script:PaneLines.Count-1)] 2>$null
  $row = $script:PaneTopRow + 3
  foreach ($line in $slice) {
    $txt = ($line -replace "`r","")
    if ($txt.Length -gt $script:PaneWidth) { $txt = $txt.Substring(0, $script:PaneWidth) }
    UI-WriteAt 0 $row $txt
    $row++
  }
  while ($row -lt ($script:PaneTopRow + $script:PaneHeight)) {
    UI-WriteAt 0 $row ""
    $row++
  }
}
function UI-ProgressLine([string]$text) {
    $t    = $text -replace "`r",""
    $trim = $t.Trim()
    $esSpinner = $false
    if ($trim.Length -eq 1 -and @('/', '-', '\', '|') -contains $trim) {
        $esSpinner = $true
    }
    $esProgreso = $false
    if ($trim.StartsWith("Progress:", [System.StringComparison]::OrdinalIgnoreCase)) {
        $esProgreso = $true
    }
    if ($esSpinner -and $script:PaneLines.Count -gt 0) {
        $script:PaneLines[$script:PaneLines.Count - 1] = $t
        UI-RefreshProgress
        return
    }
    if ($esProgreso -and $script:PaneLines.Count -gt 0) {
        $last     = $script:PaneLines[$script:PaneLines.Count - 1]
        $lastTrim = $last.Trim()
        if ($lastTrim.StartsWith("Progress:", [System.StringComparison]::OrdinalIgnoreCase)) {
            $pctCur  = ([regex]::Match($trim, '(\d+)%$')).Groups[1].Value
            $pctLast = ([regex]::Match($lastTrim, '(\d+)%$')).Groups[1].Value
            if ($pctCur -and $pctLast -and $pctCur -eq $pctLast) {
                return
            }
            $script:PaneLines[$script:PaneLines.Count - 1] = $t
            UI-RefreshProgress
            return
        }
        else {
            [void]$script:PaneLines.Add($t)
            UI-RefreshProgress
            return
        }
    }
    [void]$script:PaneLines.Add($t)
    UI-RefreshProgress
}
function Run-WithProgress {
  param(
    [Parameter(Mandatory=$true)][string]$Title,
    [Parameter(Mandatory=$true)][string]$Command  # cadena completa para cmd /c
  )
  UI-InitProgress $Title
  UI-ProgressLine ">>> $Title"
  cmd /c $Command 2>&1 | ForEach-Object { UI-ProgressLine $_ }
  UI-ProgressLine "<<< FIN: $Title"
}
function Existe-Choco { return [bool](Get-Exe "choco") }
function Existe-Winget { return [bool](Get-Exe "winget") }
function Instalar-Choco {
    Write-Host "`nInstalando Chocolatey..." -ForegroundColor Cyan

    # Si ya existe, no hacemos nada
    if (Get-Command choco -ErrorAction SilentlyContinue) {
        Write-Host "Chocolatey ya está instalado." -ForegroundColor Green
        return
    }

    try {
        # Asegurar ejecución y TLS 1.2+
        Set-ExecutionPolicy Bypass -Scope Process -Force
        [System.Net.ServicePointManager]::SecurityProtocol = `
            [System.Net.ServicePointManager]::SecurityProtocol -bor 3072
        iex ((New-Object System.Net.WebClient).DownloadString('https://community.chocolatey.org/install.ps1'))
        Write-Host "`nChocolatey se instaló correctamente." -ForegroundColor Green
        Write-Host "Configurando Chocolatey (cacheLocation en C:\Choco\cache)..." -ForegroundColor Yellow
        choco config set cacheLocation 'C:\Choco\cache' | Out-Null
        Write-Host "`nChocolatey quedó instalado y configurado." -ForegroundColor Green
        Write-Host "Si 'choco' no se reconoce, cierra y vuelve a abrir PowerShell." -ForegroundColor Yellow
    }
    catch {
        Write-Host "`nNo se pudo descargar o ejecutar el instalador de Chocolatey (posible problema de TLS o red)." -ForegroundColor Yellow
        Write-Host "Alternativa: ejecuta manualmente este comando en una consola con Internet:" -ForegroundColor Yellow
        Write-Host '  @"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -InputFormat None -ExecutionPolicy Bypass -Command "iex ((New-Object net.webclient).DownloadString(''https://community.chocolatey.org/install.ps1''))" && SET "PATH=%PATH%;%ALLUSERSPROFILE%\chocolatey\bin"' -ForegroundColor Gray
        Write-Host "`nPresiona [Enter] para continuar..." -ForegroundColor DarkGray
        [void][System.Console]::ReadLine()
    }
}

function Instalar-Winget {
  Write-Host "Instalar winget requiere Windows 10/11 y Microsoft Store (App Installer)." -ForegroundColor Yellow
  Write-Host "Intentaré abrir la página de App Installer en la Microsoft Store..." -ForegroundColor Cyan
  try {
    Start-Process "ms-windows-store://pdp/?productid=9NBLGGH4NNS1" | Out-Null
    Write-Host "Cuando finalice la instalación de 'App Installer', vuelve a ejecutar este script." -ForegroundColor Green
  } catch {
    Write-Host "No pude abrir la Microsoft Store automáticamente." -ForegroundColor Yellow
    Write-Host "Instálalo manualmente buscando 'App Installer' en la Store, o descarga el MSIXBundle desde GitHub (Microsoft.WinGet.Client)." -ForegroundColor Yellow
  }
  Pausa
}
$script:ConfigRoot = "C:\Temp\WinCho"
$script:ConfigFile = Join-Path $script:ConfigRoot "apps.json"
$script:DefaultApps = @(
  # Web / Navegación y Nube
  # =========================
  @{ Seccion="Web / Navegación y Nube"; Nombre="Google Chrome";  ChocoId="googlechrome";            WingetId="Google.Chrome" }
  @{ Seccion="Web / Navegación y Nube"; Nombre="Google Drive";   ChocoId="googledrive";             WingetId="Google.Drive" }
  # Comunicaciones / Productividad
  # =========================
  @{ Seccion="Comunicaciones / Productividad"; Nombre="Discord";        ChocoId="discord";                 WingetId="Discord.Discord" }
  @{ Seccion="Comunicaciones / Productividad"; Nombre="TeamViewer";     ChocoId="teamviewer";              WingetId="TeamViewer.TeamViewer" }
  @{ Seccion="Comunicaciones / Productividad"; Nombre="TeamSpeak";      ChocoId="teamspeak";               WingetId="TeamSpeakSystems.TeamSpeakClient" }
  @{ Seccion="Comunicaciones / Productividad"; Nombre="Thunderbird ESR";ChocoId="thunderbird";             WingetId="Mozilla.Thunderbird" }
  # Gaming / Launchers y utilidades
  # =========================
  @{ Seccion="Gaming / Launchers"; Nombre="Steam";          ChocoId="steam";                   WingetId="Valve.Steam" }
  @{ Seccion="Gaming / Launchers"; Nombre="EA app";         ChocoId="";                        WingetId="ElectronicArts.EADesktop" }
  @{ Seccion="Gaming / Launchers"; Nombre="MSI Afterburner";ChocoId="msiafterburner";          WingetId="Guru3D.MSIAfterburner" }
  @{ Seccion="Gaming / Launchers"; Nombre="RivaTuner Statistics Server"; ChocoId="rtss";       WingetId="TechPowerUp.RTSS" }
  # Multimedia / Edición y Streaming
  # =========================
  @{ Seccion="Multimedia / Edición y Streaming"; Nombre="VLC media player"; ChocoId="vlc";             WingetId="VideoLAN.VLC" }
  @{ Seccion="Multimedia / Edición y Streaming"; Nombre="HandBrake";      ChocoId="handbrake.install"; WingetId="HandBrake.HandBrake" }
  @{ Seccion="Multimedia / Edición y Streaming"; Nombre="OBS Studio";     ChocoId="obs-studio";        WingetId="OBSProject.OBSStudio" }
  @{ Seccion="Multimedia / Edición y Streaming"; Nombre="REAPER (x64)";   ChocoId="reaper";            WingetId="Cockos.REAPER" }
  @{ Seccion="Multimedia / Edición y Streaming"; Nombre="ImageMagick";    ChocoId="imagemagick.app";   WingetId="ImageMagick.ImageMagick" }
  @{ Seccion="Multimedia / Edición y Streaming"; Nombre="FFmpeg";         ChocoId="ffmpeg";            WingetId="FFmpeg.FFmpeg" }
  @{ Seccion="Multimedia / Edición y Streaming"; Nombre="yt-dlp";         ChocoId="yt-dlp";            WingetId="yt-dlp.yt-dlp" }
  # Desarrollo / Herramientas y Virtualización
  # =========================
  @{ Seccion="Desarrollo / Herramientas y Virtualización"; Nombre="Node.js LTS";             ChocoId="nodejs-lts";           WingetId="OpenJS.NodeJS.LTS" }
  @{ Seccion="Desarrollo / Herramientas y Virtualización"; Nombre="Python 3.12 (x64)";       ChocoId="python";               WingetId="Python.Python.3.12" }
  @{ Seccion="Desarrollo / Herramientas y Virtualización"; Nombre="PowerShell 7 (x64)";      ChocoId="powershell-core";      WingetId="Microsoft.PowerShell" }
  @{ Seccion="Desarrollo / Herramientas y Virtualización"; Nombre="VirtualBox";              ChocoId="virtualbox";           WingetId="Oracle.VirtualBox" }
  @{ Seccion="Desarrollo / Herramientas y Virtualización"; Nombre="Tesseract OCR";           ChocoId="tesseract";            WingetId="tesseract-ocr.tesseract" }
  # Utilidades del sistema / Archivo
  # =========================
  @{ Seccion="Utilidades del sistema / Archivo"; Nombre="7-Zip";          ChocoId="7zip";          WingetId="7zip.7zip" }
  # Runtimes de alto impacto (.NET)
  # =========================
  @{ Seccion="Runtimes .NET"; Nombre=".NET Framework 4.8";              ChocoId="dotnetfx";                     WingetId="Microsoft.DotNet.Framework.4.8" }
  @{ Seccion="Runtimes .NET"; Nombre=".NET Desktop Runtime 9 (x64)";    ChocoId="dotnet-9.0-desktopruntime";    WingetId="Microsoft.DotNet.DesktopRuntime.9" }
  @{ Seccion="Runtimes .NET"; Nombre=".NET Desktop Runtime 8 (x64)";    ChocoId="dotnet-desktopruntime";        WingetId="Microsoft.DotNet.DesktopRuntime.8" }
)
function Ensure-ConfigFolder {
    if (-not (Test-Path $script:ConfigRoot)) {
        New-Item -ItemType Directory -Path $script:ConfigRoot -Force | Out-Null
    }
}
function Guardar-Catalogo {
    param(
        [Parameter(Mandatory=$true)]
        [array]$Apps
    )
    Ensure-ConfigFolder
    $obj = [PSCustomObject]@{
        Version = 1
        Apps    = $Apps
    }
    $json = $obj | ConvertTo-Json -Depth 6
    $json | Set-Content -Path $script:ConfigFile -Encoding UTF8
}
function Cargar-Catalogo {
    Ensure-ConfigFolder
    if (Test-Path $script:ConfigFile) {
        try {
            $raw  = Get-Content $script:ConfigFile -Raw -ErrorAction Stop
            $json = $raw | ConvertFrom-Json -ErrorAction Stop
            if ($json -and $json.Apps) {
                return @($json.Apps)
            }
        } catch {
            Write-Host "No se pudo leer apps.json, se usará el catálogo por omisión." -ForegroundColor Yellow
        }
    }
    $appsDef = @($script:DefaultApps)
    Guardar-Catalogo -Apps $appsDef
    return $appsDef
}
$script:Apps = Cargar-Catalogo
Set-Variable -Name Apps -Scope Script -Value $script:Apps
function Editar-Catalogo {
    UI-Titulo -Titulo "Editor de catálogo" -Subtitulo "Archivo: $($script:ConfigFile)"
    Write-Host "Opciones del catálogo:" -ForegroundColor White
    Write-Host ""
    Write-Host "  1) Eliminar aplicaciones seleccionadas" -ForegroundColor Cyan
    Write-Host "  2) Eliminar TODO el catálogo"           -ForegroundColor Cyan
    Write-Host "  3) Agregar una aplicación manualmente"  -ForegroundColor Cyan
    Write-Host "  4) Regenerar catálogo por omisión"      -ForegroundColor DarkYellow
    Write-Host "  0) Volver"                              -ForegroundColor Yellow
    Write-Host ""
    UI-Hint "Este catálogo es portable: copia apps.json a otra PC para reinstalar lo mismo."
    $op = Ask "Opción"
    switch ($op) {
            "1" {
            Choco-Listar  # o Winget-Listar, solo para mostrar índices
            $sel  = Ask "Números a eliminar (ej. 1,3,5)"
            $nums = $sel -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' }
            if ($nums.Count -eq 0) {
                Write-Host "Nada que eliminar." -ForegroundColor Yellow
                return
            }
            $indices = @()
            foreach ($n in $nums) {
                $idx = [int]$n - 1
                if ($idx -ge 0 -and $idx -lt $Apps.Count) {
                    Write-Host "Marcando para eliminar: $($Apps[$idx].Nombre)" -ForegroundColor DarkYellow
                    $indices += $idx
                } else {
                    Write-Host "Índice fuera de rango: $n" -ForegroundColor Yellow
                }
            }
            if ($indices.Count -eq 0) {
                Write-Host "No se encontraron índices válidos para eliminar." -ForegroundColor Yellow
                return
            }
            Eliminar-AppsPorIndices -Indices $indices
            Write-Host "Catálogo actualizado." -ForegroundColor Green
        }
        "2" {
            $conf = Ask "Esto dejará el catálogo vacío. ¿Seguro? (S/N)"
            if ($conf -match '^[sSyY]$') {
                $script:Apps = @()
                Set-Variable -Name Apps -Scope Script -Value $script:Apps
                Guardar-Catalogo -Apps $Apps
                Write-Host "Catálogo vacío guardado." -ForegroundColor Green
            }
        }
        "3" {
            Agregar-App-Manual
        }
        "4" {
            $conf = Ask "Se perderán cambios y se volverá al catálogo por omisión. ¿Continuar? (S/N)"
            if ($conf -match '^[sSyY]$') {
                $script:Apps = @($script:DefaultApps)
                Set-Variable -Name Apps -Scope Script -Value $script:Apps
                Guardar-Catalogo -Apps $Apps
                Write-Host "Catálogo restaurado a los valores por omisión." -ForegroundColor Green
            }
        }
        default { return }
    }
}
function Eliminar-AppsPorIndices {
    param(
        [int[]]$Indices
    )
    if (-not $Indices -or $Indices.Count -eq 0) { return }
    $Indices = $Indices | Sort-Object -Unique
    $nuevo = @()
    for ($i = 0; $i -lt $Apps.Count; $i++) {
        if ($Indices -notcontains $i) {
            $nuevo += $Apps[$i]
        }
    }
    $script:Apps = $nuevo
    Set-Variable -Name Apps -Scope Script -Value $script:Apps
    Guardar-Catalogo -Apps $Apps
}
function Agregar-App-Manual {
    UI-Titulo -Titulo "Agregar aplicación al catálogo" -Subtitulo "apps.json"
    $nombre = Ask "Nombre descriptivo de la aplicación"
    if ([string]::IsNullOrWhiteSpace($nombre)) { Write-Host "Nombre vacío, cancelado." -ForegroundColor Yellow; return }

    $chocoId  = Ask "Chocolatey ID (vacío si no aplica)"
    $wingetId = Ask "winget ID (vacío si no aplica)"

    # Obtener secciones existentes
    $secciones = $Apps | Select-Object -ExpandProperty Seccion -Unique | Sort-Object
    Write-Host "`nSecciones existentes:" -ForegroundColor White
    $i = 1
    foreach ($s in $secciones) {
        Write-Host "  $i) $s"
        $i++
    }
    Write-Host "  N) Crear nueva sección" -ForegroundColor Cyan
    Write-Host ""
    $selSec = Ask "Elige sección (número) o N"

    $seccionFinal = $null
    if ($selSec -match '^[nN]$') {
        $seccionFinal = Ask "Nombre de la nueva sección"
        if ([string]::IsNullOrWhiteSpace($seccionFinal)) {
            Write-Host "Sección vacía, cancelado." -ForegroundColor Yellow
            return
        }
    }
    elseif ($selSec -match '^\d+$') {
        $idx = [int]$selSec - 1
        if ($idx -ge 0 -and $idx -lt $secciones.Count) {
            $seccionFinal = $secciones[$idx]
        } else {
            Write-Host "Índice inválido, cancelado." -ForegroundColor Yellow
            return
        }
    }
    else {
        Write-Host "Entrada inválida, cancelado." -ForegroundColor Yellow
        return
    }

    $newApp = @{
        Seccion = $seccionFinal
        Nombre  = $nombre
        ChocoId = $chocoId
        WingetId= $wingetId
    }
    $Apps += New-Object PSObject -Property $newApp
    Guardar-Catalogo -Apps $Apps
    Write-Host "`nAplicación agregada al catálogo." -ForegroundColor Green
}
function Crear-Catalogo-Desde-Instaladas {
    param([string]$gestor)
    UI-Titulo -Titulo "Crear catálogo desde apps instaladas" -Subtitulo "Gestor: $gestor"
    $conf = Ask "Esto sobrescribirá el catálogo actual. ¿Continuar? (S/N)"
    if ($conf -notmatch '^[sSyY]$') { return }
    $nuevas = @()
    if ($gestor -eq "winget") {
        Write-Host "Leyendo aplicaciones instaladas con winget..." -ForegroundColor Cyan
        $raw = winget list --source winget | Select-Object -Skip 1
        foreach ($line in $raw) {
            $txt = $line.Trim()
            if (-not $txt) { continue }
            $cols = $txt -split "\s{2,}"
            if ($cols.Count -ge 2) {
                $nombre = $cols[0]
                $id     = $cols[1]
                $app = @{
                    Seccion = "Auto (winget)"
                    Nombre  = $nombre
                    ChocoId = ""
                    WingetId= $id
                }
                $nuevas += New-Object PSObject -Property $app
            }
        }
    }
    elseif ($gestor -eq "choco") {
        Write-Host "Leyendo aplicaciones instaladas con Chocolatey..." -ForegroundColor Cyan
        $raw = choco list --local-only --limit-output | Where-Object { $_ -match '\|' }
        foreach ($line in $raw) {
            $cols = $line -split "\|"
            if ($cols.Count -ge 2) {
                $nombre = $cols[0]
                $ver    = $cols[1]
                $app = @{
                    Seccion = "Auto (choco)"
                    Nombre  = $nombre
                    ChocoId = $nombre
                    WingetId= ""
                }
                $nuevas += New-Object PSObject -Property $app
            }
        }
    }
    if ($nuevas.Count -eq 0) {
        Write-Host "No se encontraron aplicaciones instaladas o no se pudo leer la lista." -ForegroundColor Yellow
        return
    }
    $backup = "$($script:ConfigFile).bak.$((Get-Date).ToString('yyyyMMddHHmmss'))"
    if (Test-Path $script:ConfigFile) {
        Copy-Item $script:ConfigFile $backup -Force
        Write-Host "Respaldo creado: $backup" -ForegroundColor DarkGray
    }

    $script:Apps = $nuevas
    Set-Variable -Name Apps -Scope Script -Value $script:Apps
    Guardar-Catalogo -Apps $Apps
    Write-Host "Catálogo reemplazado por la lista de aplicaciones instaladas." -ForegroundColor Green
}
function Choco-Listar {
  Write-Host "`nCatálogo disponible (Chocolatey IDs):`n" -ForegroundColor Cyan
  Write-Host "Archivo de catálogo: $($script:ConfigFile)" -ForegroundColor DarkGray
  $half = [math]::Ceiling($Apps.Count / 2)
  for ($i = 0; $i -lt $half; $i++) {
    $leftIndex  = $i
    $rightIndex = $i + $half
    $leftApp  = $Apps[$leftIndex]
    $leftText = "[{0,2}] {1,-30} -> {2,-25} [{3}]" -f ($leftIndex + 1), $leftApp.Nombre, $leftApp.ChocoId, $leftApp.Seccion
    if ($rightIndex -lt $Apps.Count) {
      $rightApp  = $Apps[$rightIndex]
      $rightText = "[{0,2}] {1,-30} -> {2} [{3}]" -f ($rightIndex + 1), $rightApp.Nombre, $rightApp.ChocoId, $rightApp.Seccion
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
    Run-WithProgress -Title "Chocolatey: instalando $id" -Command "choco install $id -y"
  }
}
function Winget-Instalar { param([string[]]$ids)
  foreach ($id in $ids) {
    if ([string]::IsNullOrEmpty($id)) { continue }
    Run-WithProgress -Title "winget: instalando $id" -Command "winget install --id `"$id`" --accept-package-agreements --accept-source-agreements --disable-interactivity"
  }
}
function Choco-ActualizarTodo {
  Run-WithProgress -Title "Chocolatey: actualizar TODO" -Command "choco upgrade all -y"
}
function Winget-ActualizarTodo {
  Run-WithProgress -Title "winget: actualizar orígenes" -Command "winget source update"
  Run-WithProgress -Title "winget: upgrade --all" -Command "winget upgrade --all --accept-package-agreements --accept-source-agreements --disable-interactivity"
}
function Elegir-Gestor {
  UI-Titulo -Titulo "Instalador de Aplicaciones" -Subtitulo "Elegir gestor de paquetes"
  Write-Host "Elige el gestor de paquetes:" -ForegroundColor White
  Write-Host ""
  Write-Host "  1) Chocolatey" -ForegroundColor Cyan
  Write-Host "  2) winget"     -ForegroundColor Cyan
  Write-Host "  0) Salir"      -ForegroundColor Yellow
  Write-Host ""
  UI-Hint "Consejo: si no sabes cuál usar, empieza por Chocolatey (1)."
  $op = Ask "Opción"
  Write-Host "Catálogo actual: $($script:ConfigFile)" -ForegroundColor DarkGray
  Write-Host "Puedes copiar este archivo a otra PC para reinstalar las mismas aplicaciones." -ForegroundColor DarkGray
  if ($op -eq "1") { return "choco" }
  if ($op -eq "2") { return "winget" }
  if ($op -eq "0") { return $null }
  Write-Host "Opción no válida." -ForegroundColor Yellow
  Pausa
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
    UI-Titulo -Titulo "Menú principal" -Subtitulo "Gestor activo: $gestor"
    Write-Host "Acciones disponibles:" -ForegroundColor White
    Write-Host ""
    Write-Host "  1) Listar catálogo"                         -ForegroundColor Cyan
    Write-Host "  2) Instalar TODO el catálogo"               -ForegroundColor Cyan
    Write-Host "  3) Instalar apps seleccionadas"             -ForegroundColor Cyan
    Write-Host "  4) Actualizar TODO (ya instaladas)"         -ForegroundColor Cyan
    Write-Host "  5) Actualizar PowerShell (7 recomendado)"   -ForegroundColor Cyan
    Write-Host "  6) Buscar paquete e instalar"               -ForegroundColor Cyan
    Write-Host "  7) Editar catálogo (archivo apps.json)"     -ForegroundColor Cyan
    Write-Host "  8) Crear catálogo desde apps instaladas"    -ForegroundColor DarkYellow
    Write-Host ""
    Write-Host "  9) Cambiar de gestor"                       -ForegroundColor DarkYellow
    Write-Host "  0) Salir"                                   -ForegroundColor Yellow
    Write-Host ""
    UI-Hint "Escribe el número de la opción y presiona [Enter]."
    $acc = Ask "Opción"
    if ($acc -eq "1") {
      if ($gestor -eq "choco") { Choco-Listar } else { Winget-Listar }
      Pausa
    }
    elseif ($acc -eq "2") {
      $ids = @()
      foreach ($a in $Apps) {
        if ($gestor -eq "choco") { $ids += $a.ChocoId } else { $ids += $a.WingetId }
      }
      if ($gestor -eq "choco") { Choco-Instalar -ids $ids } else { Winget-Instalar -ids $ids }
      Pausa
    }
    elseif ($acc -eq "3") {
      if ($gestor -eq "choco") { Choco-Listar } else { Winget-Listar }
      $sel  = Ask "Escribe los números separados por coma (ej. 1,3,5)"
      $nums = $sel -split "," | ForEach-Object { $_.Trim() } | Where-Object { $_ -match '^\d+$' }

      if ($nums.Count -eq 0) {
        Write-Host "Selección vacía o inválida." -ForegroundColor Yellow
      } else {
        $ids = @()
        foreach ($n in $nums) {
          $idx = [int]$n - 1
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
    elseif ($acc -eq "5") {
      Actualizar-PowerShell -gestor $gestor
      Pausa
    }
    elseif ($acc -eq "6") {
      Buscar-Paquete -gestor $gestor
    }
    elseif ($acc -eq "7") {
      Editar-Catalogo
      Pausa
    }
    elseif ($acc -eq "8") {
      Crear-Catalogo-Desde-Instaladas -gestor $gestor
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
      Pausa
    }
  }
}
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
