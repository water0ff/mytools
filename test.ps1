Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ======================================================
# CONFIGURACION GENERAL
# ======================================================
CLS
$ffmpeg = "ffmpeg"
$audioArgs = "-vn -ac 1 -ar 22050 -b:a 48k"

# ======================================================
# VENTANA PRINCIPAL
# ======================================================
$form = New-Object System.Windows.Forms.Form
$form.Text = "Herramienta de Limpieza y Compresión"
$form.Size = New-Object System.Drawing.Size(760,480)
$form.StartPosition = "CenterScreen"
$form.MaximizeBox = $false

# ======================================================
# TAB CONTROL
# ======================================================
$tabs = New-Object System.Windows.Forms.TabControl
$tabs.Size = '730,430'
$tabs.Location = '10,10'

# ======================================================
# TAB 1 - COMPRESOR AUDIO / VIDEO
# ======================================================
$tabCompress = New-Object System.Windows.Forms.TabPage
$tabCompress.Text = "Compresor FFmpeg"

# Origen
$txtSource = New-Object System.Windows.Forms.TextBox
$txtSource.Location = '20,40'
$txtSource.Size = '560,22'

$btnSource = New-Object System.Windows.Forms.Button
$btnSource.Text = "Origen"
$btnSource.Location = '600,38'

# Destino
$txtDest = New-Object System.Windows.Forms.TextBox
$txtDest.Location = '20,90'
$txtDest.Size = '560,22'

$btnDest = New-Object System.Windows.Forms.Button
$btnDest.Text = "Destino"
$btnDest.Location = '600,88'

# Progreso
$progress = New-Object System.Windows.Forms.ProgressBar
$progress.Location = '20,140'
$progress.Size = '680,25'

$lblProgress = New-Object System.Windows.Forms.Label
$lblProgress.Location = '20,170'
$lblProgress.Size = '680,20'

$btnStart = New-Object System.Windows.Forms.Button
$btnStart.Text = "Iniciar compresión"
$btnStart.Location = '20,200'
$btnStart.Size = '680,35'

# ======================================================
# TAB 2 - LIMPIADOR DE ARCHIVOS
# ======================================================
$tabClean = New-Object System.Windows.Forms.TabPage
$tabClean.Text = "Limpiador de archivos"

$lblCleanPath = New-Object System.Windows.Forms.Label
$lblCleanPath.Text = "Carpeta a limpiar"
$lblCleanPath.Location = '20,30'

$txtCleanPath = New-Object System.Windows.Forms.TextBox
$txtCleanPath.Location = '20,55'
$txtCleanPath.Size = '560,22'

$btnCleanPath = New-Object System.Windows.Forms.Button
$btnCleanPath.Text = "Examinar"
$btnCleanPath.Location = '600,53'

$lblSize = New-Object System.Windows.Forms.Label
$lblSize.Text = "Conservar solo archivos mayores a (MB):"
$lblSize.Location = '20,95'

$numSize = New-Object System.Windows.Forms.NumericUpDown
$numSize.Location = '300,92'
$numSize.Width = 80
$numSize.Minimum = 1
$numSize.Maximum = 5000
$numSize.Value = 1

$btnPreview = New-Object System.Windows.Forms.Button
$btnPreview.Text = "Vista previa"
$btnPreview.Location = '20,130'

$btnClean = New-Object System.Windows.Forms.Button
$btnClean.Text = "Eliminar archivos pequeños"
$btnClean.Location = '140,130'

$list = New-Object System.Windows.Forms.ListView
$list.Location = '20,170'
$list.Size = '680,210'
$list.View = 'Details'
$list.FullRowSelect = $true
$list.Columns.Add("Archivo",520)
$list.Columns.Add("MB",80)

# ======================================================
# DIALOGOS
# ======================================================
$folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog

$btnSource.Add_Click({ if ($folderDialog.ShowDialog() -eq 'OK'){ $txtSource.Text = $folderDialog.SelectedPath } })
$btnDest.Add_Click({ if ($folderDialog.ShowDialog() -eq 'OK'){ $txtDest.Text = $folderDialog.SelectedPath } })
$btnCleanPath.Add_Click({ if ($folderDialog.ShowDialog() -eq 'OK'){ $txtCleanPath.Text = $folderDialog.SelectedPath } })

# ======================================================
# COMPRESION
# ======================================================
$btnStart.Add_Click({
    try {
        if (!(Test-Path $txtSource.Text)) { throw "Origen inválido: $($txtSource.Text)" }
        if (!(Test-Path $txtDest.Text))   { New-Item -ItemType Directory -Path $txtDest.Text -Force | Out-Null }

        # Verifica ffmpeg
        $ff = Get-Command ffmpeg -ErrorAction SilentlyContinue
        if (-not $ff) { throw "No se encontró 'ffmpeg' en el PATH. Instálalo o agrega su ruta." }

        $files = Get-ChildItem $txtSource.Text -Recurse -File -Include *.mp3, *.mp4
        $progress.Minimum = 0
        $progress.Value = 0
        $progress.Maximum = $files.Count

        $progress.Maximum = $files.Count
        $i = 0

        foreach ($file in $files) {
            $i++

            $src = $txtSource.Text.TrimEnd('\') + '\'
            $relative = $file.FullName.Substring($src.Length)
            $outFile = Join-Path $txtDest.Text $relative
            New-Item -ItemType Directory -Path (Split-Path $outFile) -Force | Out-Null

            # ✅ ACTUALIZA UI ANTES DE ffmpeg
            $lblProgress.Text = "Comprimiendo $i de $($files.Count): $($file.Name)"
            $progress.Value = $i
            [System.Windows.Forms.Application]::DoEvents()

            Write-Host "In : $($file.FullName)" -ForegroundColor DarkGray
            Write-Host "Out: $outFile" -ForegroundColor Green

            $args = @("-y", "-i", $file.FullName) + @("-vn","-ac","1","-ar","22050","-b:a","48k") + @($outFile)
            & $ff.Source @args

            if ($LASTEXITCODE -ne 0) { throw "ffmpeg falló con código $LASTEXITCODE en: $($file.FullName)" }
            if (!(Test-Path $outFile)) { throw "ffmpeg terminó pero no se generó: $outFile" }
        }
        [System.Windows.Forms.MessageBox]::Show("Compresión finalizada")
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show($_.Exception.Message,"Error")
    }
})

# ======================================================
# TAB 3 - COMPRESOR DE IMAGENES (ImageMagick)
# ======================================================
$tabImages = New-Object System.Windows.Forms.TabPage
$tabImages.Text = "Compresor de imágenes"

$lblImgSource = New-Object System.Windows.Forms.Label
$lblImgSource.Text = "Carpeta de imágenes"
$lblImgSource.Location = '20,30'

$txtImgSource = New-Object System.Windows.Forms.TextBox
$txtImgSource.Location = '20,55'
$txtImgSource.Size = '560,22'

$btnImgSource = New-Object System.Windows.Forms.Button
$btnImgSource.Text = "Examinar"
$btnImgSource.Location = '600,53'

$lblQuality = New-Object System.Windows.Forms.Label
$lblQuality.Text = "Nivel de compresión"
$lblQuality.Location = '20,95'

$comboQuality = New-Object System.Windows.Forms.ComboBox
$comboQuality.Location = '20,120'
$comboQuality.Width = 300
$comboQuality.DropDownStyle = 'DropDownList'

$comboQuality.Items.Add("85  - casi sin pérdida")
$comboQuality.Items.Add("70  - ideal web")
$comboQuality.Items.Add("60  - nube / archivo")
$comboQuality.Items.Add("40  - archivo extremo")

# 👉 VALOR POR OMISION
$comboQuality.SelectedIndex = 1

$btnImgStart = New-Object System.Windows.Forms.Button
$btnImgStart.Text = "Comprimir imágenes"
$btnImgStart.Location = '20,165'
$btnImgStart.Size = '680,35'

$lblImgStatus = New-Object System.Windows.Forms.Label
$lblImgStatus.Location = '20,210'
$lblImgStatus.Size = '680,25'

$btnImgSource.Add_Click({ if ($folderDialog.ShowDialog() -eq 'OK'){ $txtImgSource.Text = $folderDialog.SelectedPath } })

$btnImgStart.Add_Click({
    try {
        if (!(Test-Path $txtImgSource.Text)) {
            [System.Windows.Forms.MessageBox]::Show("Selecciona una carpeta válida")
            return
        }

        switch ($comboQuality.SelectedIndex) {
            0 { $quality = 85 }
            1 { $quality = 70 }
            2 { $quality = 60 }
            3 { $quality = 40 }
        }

        $images = Get-ChildItem $txtImgSource.Text -Recurse -File -Include *.jpg, *.jpeg, *.png
        $total = $images.Count
        $i = 0

        foreach ($img in $images) {
            $i++
            $lblImgStatus.Text = "Procesando $i de $total : $($img.Name)"
            $form.Refresh()

            magick "$($img.FullName)" -quality $quality "$($img.FullName)"
        }

        [System.Windows.Forms.MessageBox]::Show("Compresión de imágenes finalizada
Calidad usada: $quality")
        $lblImgStatus.Text = "Proceso terminado"
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show($_,"Error")
    }
})

# ======================================================
# LIMPIADOR
# ======================================================
$btnPreview.Add_Click({
    try {
        $list.Items.Clear()
        $limit = $numSize.Value * 1MB

        $files = Get-ChildItem $txtCleanPath.Text -Recurse -File |
            Where-Object { $_.Length -lt $limit }

        foreach ($f in $files) {
            $item = New-Object System.Windows.Forms.ListViewItem($f.FullName)
            $item.SubItems.Add([math]::Round($f.Length/1MB,2))
            $list.Items.Add($item)
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show($_,"Error")
    }
})

$btnClean.Add_Click({
    try {
        if ([System.Windows.Forms.MessageBox]::Show("¿Eliminar estos archivos?","Confirmar","YesNo") -eq 'Yes') {
            foreach ($item in $list.Items) {
                Remove-Item $item.Text -Force
            }
            [System.Windows.Forms.MessageBox]::Show("Limpieza completada")
        }
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show($_,"Error")
    }
})

# ======================================================
# AGREGAR CONTROLES
$tabImages.Controls.AddRange(@($lblImgSource,$txtImgSource,$btnImgSource,$lblQuality,$comboQuality,$btnImgStart,$lblImgStatus))
# ======================================================
$tabCompress.Controls.AddRange(@($txtSource,$btnSource,$txtDest,$btnDest,$progress,$lblProgress,$btnStart))
$tabClean.Controls.AddRange(@($lblCleanPath,$txtCleanPath,$btnCleanPath,$lblSize,$numSize,$btnPreview,$btnClean,$list))

$tabs.TabPages.AddRange(@($tabCompress,$tabClean,$tabImages))
$form.Controls.Add($tabs)
$form.Topmost = $true
$form.ShowDialog()
