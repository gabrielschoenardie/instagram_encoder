# ======================
# Conversor PowerShell → MP4 H.264 para Instagram
# ======================
# 1) Garanta que este arquivo (.ps1) esteja salvo em UTF-8 sem BOM.
# 2) Se você executar no VSCode/ISE, $PSScriptRoot irá apontar para a pasta do script.
# 3) Se não estiver no console, usamos [Environment]::CurrentDirectory como fallback.

# +----------------------------------------------+
# | 1. Importar assemblies de UI                 |
# +----------------------------------------------+
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# ===========================
# 2. Função auxiliar: Invoke-FFmpeg
# ===========================
function Invoke-FFmpeg {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string] $Arguments,

        [Parameter(Mandatory=$true)]
        [string] $PassName,            # ex: "Pass 1", "Pass 2", "CRF Pass"
        [Parameter(Mandatory=$true)]
        [string] $CurrentFileName      # Somente para exibir no log
    )

    # Configura o ProcessStartInfo para o ffmpeg
    $processInfo = New-Object System.Diagnostics.ProcessStartInfo
    # Se o ffmpeg não estiver no PATH, defina o caminho absoluto aqui:
    # Exemplo: $processInfo.FileName = "C:\FFmpeg\bin\ffmpeg.exe"
    $processInfo.FileName = "ffmpeg"
    $processInfo.Arguments = $Arguments
    $processInfo.RedirectStandardError  = $true
    $processInfo.RedirectStandardOutput = $true
    $processInfo.UseShellExecute        = $false
    $processInfo.CreateNoWindow         = $true

    # Coleta a saída de erro padrão (STDERR) de forma assíncrona
    $stdErrBuilder = [System.Text.StringBuilder]::new()
    $errorHandler = {
        param($sender, $e)
        if ($e.Data) {
            [void] $stdErrBuilder.AppendLine($e.Data)
        }
    }

    $process = New-Object System.Diagnostics.Process
    $process.StartInfo = $processInfo
    $process.add_ErrorDataReceived($errorHandler)
    # Se quiser capturar STDOUT também, faça add_OutputDataReceived similar:
    # $process.add_OutputDataReceived({ param($sender, $e) if ($e.Data) { ... } })

    try {
        $process.Start() | Out-Null
        $process.BeginErrorReadLine()
        # $process.BeginOutputReadLine()   # ativar se estiver capturando STDOUT

        $process.WaitForExit()
    }
    catch {
        [System.Windows.Forms.MessageBox]::Show(
            "EXCEÇÃO ao iniciar/monitorar o FFmpeg (`"$PassName`" → `$CurrentFileName`):`n$($_.Exception.Message)",
            "Erro Crítico ao Chamar FFmpeg",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        return $false
    }

    # Se o código de saída do FFmpeg for diferente de zero → erro
    if ($process.ExitCode -ne 0) {
        $outputErr = $stdErrBuilder.ToString()
        [System.Windows.Forms.MessageBox]::Show(
            "FFmpeg retornou código $($process.ExitCode) no passo `"$PassName`" para o arquivo `"$CurrentFileName`".`n`nSaída de erro:`n$outputErr",
            "Erro na Execução do FFmpeg",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Error
        )
        return $false
    }

    # Se tudo ocorreu bem:
    Write-Host "FFmpeg [$PassName] para [$CurrentFileName] concluído com sucesso."
    return $true

function Validate-Input {
    <#
    .SYNOPSIS
    Valida arquivos e parâmetros antes da conversão.

    .DESCRIPTION
    Garante que os caminhos selecionados existem, possuem extensões suportadas e
    que o ffmpeg está disponível no PATH. Opcionalmente valida faixas de CRF ou
    Bitrate quando informados.

    .PARAMETER Files
    Lista de arquivos a validar.

    .PARAMETER UseCRF
    Indica se o modo CRF está ativo.

    .PARAMETER CRFValue
    Valor CRF a ser verificado (17–22).

    .PARAMETER Bitrate
    Bitrate para validação no modo two-pass (ex.: 3000k).
    #>
    [CmdletBinding()]
    param(
        [string[]] $Files,
        [switch]   $UseCRF,
        [int]      $CRFValue,
        [string]   $Bitrate
    )

    $allowedExt = '.mp4','.mov','.mkv','.avi','.wmv','.flv'
    foreach ($file in $Files) {
        if (-not (Test-Path $file)) {
            Write-Error "Arquivo não encontrado: $file"
            return $false
        }
        $ext = [IO.Path]::GetExtension($file)
        if ($allowedExt -notcontains $ext.ToLower()) {
            Write-Error "Extensão não suportada: $file"
            return $false
        }
    }

    if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
        Write-Error "ffmpeg não localizado no PATH"
        return $false
    }

    if ($UseCRF) {
        if ($PSBoundParameters.ContainsKey('CRFValue')) {
            if ($CRFValue -lt 17 -or $CRFValue -gt 22) {
                Write-Error "Valor CRF deve estar entre 17 e 22. Recebido: $CRFValue"
                return $false
            }
        }
    } else {
        if ($PSBoundParameters.ContainsKey('Bitrate')) {
            if ($Bitrate -notmatch '^\d+k$') {
                Write-Error "Bitrate inválido: $Bitrate"
                return $false
            }
        }
    }
    return $true
}


# =====================
# 3. Construção do formulário (UI)
# =====================
$form = New-Object System.Windows.Forms.Form
$form.Text            = "Conversor de Vídeo para Instagram - H.264 Avançado"
$form.Size            = New-Object System.Drawing.Size(600,450)
$form.StartPosition   = "CenterScreen"
$form.BackColor       = [System.Drawing.Color]::FromArgb(30,30,30)
$form.ForeColor       = [System.Drawing.Color]::White
$form.FormBorderStyle = [System.Windows.Forms.FormBorderStyle]::FixedDialog
$form.MaximizeBox     = $false

# Título
$lblTitle = New-Object System.Windows.Forms.Label
$lblTitle.Text     = "→ Selecione os vídeos e clique em Converter"
$lblTitle.Font     = New-Object System.Drawing.Font("Segoe UI",14,[System.Drawing.FontStyle]::Bold)
$lblTitle.ForeColor= [System.Drawing.Color]::White
$lblTitle.Location = New-Object System.Drawing.Point(20,20)
$lblTitle.AutoSize = $true
$form.Controls.Add($lblTitle)

# Botão “Selecionar Vídeo”
$btnSelect = New-Object System.Windows.Forms.Button
$btnSelect.Text     = "📂 Selecionar Vídeos..."
$btnSelect.Font     = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
$btnSelect.BackColor= [System.Drawing.Color]::FromArgb(50,50,50)
$btnSelect.ForeColor= [System.Drawing.Color]::White
$btnSelect.FlatStyle= "Flat"
$btnSelect.Location = New-Object System.Drawing.Point(20,60)
$btnSelect.Size     = New-Object System.Drawing.Size(150,35)
$form.Controls.Add($btnSelect)

# ListBox para mostrar arquivos selecionados
$listBox = New-Object System.Windows.Forms.ListBox
$listBox.Location      = New-Object System.Drawing.Point(20,110)
$listBox.Size          = New-Object System.Drawing.Size(540,80)
$listBox.Font          = New-Object System.Drawing.Font("Segoe UI",9)
$listBox.SelectionMode = [System.Windows.Forms.SelectionMode]::MultiExtended
$form.Controls.Add($listBox)

# Grupo de “Configurações Avançadas”
$gbSettings = New-Object System.Windows.Forms.GroupBox
$gbSettings.Text     = "Configurações Avançadas"
$gbSettings.Font     = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
$gbSettings.ForeColor= [System.Drawing.Color]::White
$gbSettings.Location = New-Object System.Drawing.Point(20,200)
$gbSettings.Size     = New-Object System.Drawing.Size(540,130)
$form.Controls.Add($gbSettings)

# CheckBox: Usar CRF
$chkCRF = New-Object System.Windows.Forms.CheckBox
$chkCRF.Text     = "Usar CRF em vez de 2-pass"
$chkCRF.Font     = New-Object System.Drawing.Font("Segoe UI",9)
$chkCRF.ForeColor= [System.Drawing.Color]::White
$chkCRF.Location = New-Object System.Drawing.Point(10,25)
$chkCRF.Size     = New-Object System.Drawing.Size(200,20)
$chkCRF.Checked  = $true
$gbSettings.Controls.Add($chkCRF)

# CheckBox: Cortar para 59s
$chkCut = New-Object System.Windows.Forms.CheckBox
$chkCut.Text     = "Cortar para até 59s"
$chkCut.Font     = New-Object System.Drawing.Font("Segoe UI",9)
$chkCut.ForeColor= [System.Drawing.Color]::White
$chkCut.Location = New-Object System.Drawing.Point(10,55)
$chkCut.Size     = New-Object System.Drawing.Size(200,20)
$gbSettings.Controls.Add($chkCut)

# CheckBox: Vídeo vertical
$chkVertical = New-Object System.Windows.Forms.CheckBox
$chkVertical.Text     = "Converter para formato Vertical (9:16)"
$chkVertical.Font     = New-Object System.Drawing.Font("Segoe UI",9)
$chkVertical.ForeColor= [System.Drawing.Color]::White
$chkVertical.Location = New-Object System.Drawing.Point(10,85)
$chkVertical.Size     = New-Object System.Drawing.Size(300,20)
$gbSettings.Controls.Add($chkVertical)

# Botão “Converter”
$btnConvert = New-Object System.Windows.Forms.Button
$btnConvert.Text     = "▶ Iniciar Conversão"
$btnConvert.Font     = New-Object System.Drawing.Font("Segoe UI",9,[System.Drawing.FontStyle]::Bold)
$btnConvert.BackColor= [System.Drawing.Color]::FromArgb(30,144,255)
$btnConvert.ForeColor= [System.Drawing.Color]::White
$btnConvert.FlatStyle= "Flat"
$btnConvert.Location = New-Object System.Drawing.Point(400,350)
$btnConvert.Size     = New-Object System.Drawing.Size(160,35)
$form.Controls.Add($btnConvert)

# Barra de progresso (inicialmente 0)
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20,357)
$progressBar.Size     = New-Object System.Drawing.Size(360,20)
$progressBar.Minimum  = 0
$progressBar.Maximum  = 100
$progressBar.Value    = 0
$form.Controls.Add($progressBar)

# Label de status
$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text      = "Status: Aguardando..."
$statusLabel.Location  = New-Object System.Drawing.Point(20,390)
$statusLabel.Size      = New-Object System.Drawing.Size(550,20)
$statusLabel.Font      = New-Object System.Drawing.Font("Segoe UI",9)
$statusLabel.ForeColor = [System.Drawing.Color]::White
$form.Controls.Add($statusLabel)

# ===========================
# 4. Eventos de UI
# ===========================

# 4.1 – Ao clicar em “Selecionar Vídeos”: abre diálogo e preenche o ListBox
$btnSelect.Add_Click({
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Multiselect = $true
    $dialog.Filter      = "Arquivos de vídeo|*.mp4;*.mov;*.mkv;*.avi;*.wmv;*.flv"

    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $listBox.Items.Clear()
        foreach ($filename in $dialog.FileNames) {
            $listBox.Items.Add($filename)
        }
        $statusLabel.Text = "Status: `($($listBox.Items.Count) vídeos selecionados`)"
    }
})

# 4.2 – Ao clicar em “Converter”: prepara pastas, monta argumentos e chama Invoke-FFmpeg
$btnConvert.Add_Click({
    # 4.2.1 – Valida seleção de vídeos
    if ($listBox.Items.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show(
            "Selecione ao menos um vídeo antes de converter.",
            "Atenção",
            [System.Windows.Forms.MessageBoxButtons]::OK,
            [System.Windows.Forms.MessageBoxIcon]::Warning
        )
        return
    }

    # 4.2.2 – Descobrir pasta do script (fallback para CurrentDirectory)
    if ($PSScriptRoot) {
        $scriptDirectory = $PSScriptRoot
    } elseif ($MyInvocation.MyCommand.Definition) {
        $scriptDirectory = Split-Path -Parent $MyInvocation.MyCommand.Definition
    } else {
        $scriptDirectory = [Environment]::CurrentDirectory
    }

    # 4.2.3 – Criar pasta de saída
    $outputDirBaseName = "convertidos_h264_instagram_avancado"
    $outputDir = Join-Path -Path $scriptDirectory -ChildPath $outputDirBaseName
    if (-not (Test-Path $outputDir -PathType Container)) {
        try {
            New-Item -ItemType Directory -Path $outputDir -Force -ErrorAction Stop | Out-Null
        } catch {
            [System.Windows.Forms.MessageBox]::Show(
                "Falha ao criar pasta de saída em:`n$outputDir`n`n`$_",
                "Erro de Diretório",
                [System.Windows.Forms.MessageBoxButtons]::OK,
                [System.Windows.Forms.MessageBoxIcon]::Error
            )
            return
        }
    }

    # 4.2.4 – Criar pasta de logs
    $logFileDir = Join-Path -Path $outputDir -ChildPath "ffmpeg_logs"
    if (-not (Test-Path $logFileDir -PathType Container)) {
        try {
            New-Item -ItemType Directory -Path $logFileDir -Force -ErrorAction Stop | Out-Null
        } catch {
            Write-Warning "Não foi possível criar diretório de logs em: $logFileDir"
        }
    }

    # 4.2.5 – Configurações fixas do x264 / áudio
    $PresetX264         = "slow"
    $TargetFPS          = 30
    $gopValue           = $TargetFPS
    $keyintMinValue     = $TargetFPS
    $scThresholdValue   = 0
    $VideoProfile       = "high"
    $VideoLevel         = "4.1"
    $PixFmt             = "yuv420p"
    $ColorPrimaries     = "bt709"
    $ColorTrc           = "bt709"
    $Colorspace         = "bt709"
    $Tune               = "film"
    # Evitar escapes complicados: envolver em aspas simples e usar aspas duplas dentro
    $x264FineTuneParams = '-bf 3 -b_strategy 2 -refs 5 -coder ac -aq-mode 2 -psy-rd "1.0:0.15"'
    $AudioCodec         = "aac"
    $AudioBitrate       = "192k"
    $AudioSampleRate    = "48000"
    $AudioChannels      = 2

    # 4.2.6 – Laço sobre cada arquivo selecionado
    $totalFiles = $listBox.Items.Count
    $fileCounter = 0

    # Para manter UI responsiva, podemos usar um Job → Exemplo abaixo:
    $listaArquivos = @()
    foreach ($f in $listBox.Items) { $listaArquivos += $f }

    $crfValue = 17
    $twoPassBitrate = '3000k'
    $validationOK = Validate-Input -Files $listaArquivos -UseCRF:$chkCRF.Checked -CRFValue $crfValue -Bitrate $twoPassBitrate
    if (-not $validationOK) {
        $statusLabel.Text = 'Erro na validação dos arquivos.'
        return
    }


    # (A) VERSÃO SIMPLES: Bloqueia a UI, mas mostra progressBar com DoEvents
    foreach ($videoPath in $listaArquivos) {
        $fileCounter++
        $baseFileName = [System.IO.Path]::GetFileNameWithoutExtension($videoPath)
        $outputFile   = Join-Path $outputDir "$($baseFileName)_INSTA_H264_ADV.mp4"
        $passLogFile  = Join-Path $logFileDir "$($baseFileName)_passlog"

        # Montar filtro de video (vertical vs horizontal)
        if ($chkVertical.Checked) {
            # Vídeo vertical (9:16)
            $vfScale = 'scale=if(gt(a,9/16),1080,-2):if(gt(a,9/16),-2,1920):flags=lanczos'
        } else {
            # Vídeo horizontal (16:9)
            $vfScale = 'scale=if(gt(a,16/9),1920,-2):if(gt(a,16/9),-2,1080):flags=lanczos'
        }
        $VideoFilter = "$vfScale,format=$PixFmt"

        # Montar opções de corte (CRF ou 2-pass)
        $cutOptions = if ($chkCut.Checked) { @("-ss","00:00:00","-t","00:00:59") } else { @() }

        if ($chkCRF.Checked) {
            # *** Passo único (CRF) ***
            $argList = @()
            $argList += $cutOptions
            $argList += @(
                "-i", "`"$videoPath`"",
                "-c:v", "libx264",
                "-preset", $PresetX264,
                "-tune", $Tune,
                "-profile:v", $VideoProfile,
                "-level", $VideoLevel,
                "-pix_fmt", $PixFmt,
                "-color_primaries", $ColorPrimaries,
                "-color_trc", $ColorTrc,
                "-colorspace", $Colorspace,
                "-crf", "17",
                "-r", $TargetFPS,
                "-g", $gopValue,
                "-keyint_min", $keyintMinValue,
                "-sc_threshold", $scThresholdValue,
                "-vf", "`"$VideoFilter`"",
                "-x264-params", "`"$x264FineTuneParams`"",
                "-c:a", $AudioCodec,
                "-b:a", $AudioBitrate,
                "-ar", $AudioSampleRate,
                "-ac", $AudioChannels,
                "-y", "`"$outputFile`""
            )

            $argsString = $argList -join " "
            $sucesso = Invoke-FFmpeg -Arguments $argsString -PassName "CRF Pass" -CurrentFileName $baseFileName
            if ($sucesso) { $fileCounter++ }
        }
        else {
            # *** 2-Pass (mais “padrão” de qualidade constante) ***
            # Pass 1
            $pass1 = @()
            $pass1 += $cutOptions
            $pass1 += @(
                "-i", "`"$videoPath`"",
                "-c:v", "libx264",
                "-preset", $PresetX264,
                "-tune", $Tune,
                "-profile:v", $VideoProfile,
                "-level", $VideoLevel,
                "-pix_fmt", $PixFmt,
                "-color_primaries", $ColorPrimaries,
                "-color_trc", $ColorTrc,
                "-colorspace", $Colorspace,
                "-b:v", "3000k",            # Exemplo de bitrate do 1º pass
                "-r", $TargetFPS,
                "-g", $gopValue,
                "-keyint_min", $keyintMinValue,
                "-sc_threshold", $scThresholdValue,
                "-vf", "`"$VideoFilter`"",
                "-x264-params", "`"$x264FineTuneParams`"",
                "-pass", "1",
                "-an",
                "-f", "null", "NUL"
            )
            $argsPass1 = $pass1 -join " "
            $sucessoPass1 = Invoke-FFmpeg -Arguments $argsPass1 -PassName "Pass 1" -CurrentFileName $baseFileName
            if (-not $sucessoPass1) { continue }

            # Pass 2
            $pass2 = @()
            $pass2 += $cutOptions
            $pass2 += @(
                "-i", "`"$videoPath`"",
                "-c:v", "libx264",
                "-preset", $PresetX264,
                "-tune", $Tune,
                "-profile:v", $VideoProfile,
                "-level", $VideoLevel,
                "-pix_fmt", $PixFmt,
                "-color_primaries", $ColorPrimaries,
                "-color_trc", $ColorTrc,
                "-colorspace", $Colorspace,
                "-b:v", "3000k",
                "-r", $TargetFPS,
                "-g", $gopValue,
                "-keyint_min", $keyintMinValue,
                "-sc_threshold", $scThresholdValue,
                "-vf", "`"$VideoFilter`"",
                "-x264-params", "`"$x264FineTuneParams`"",
                "-pass", "2",
                "-c:a", $AudioCodec,
                "-b:a", $AudioBitrate,
                "-ar", $AudioSampleRate,
                "-ac", $AudioChannels,
                "-y", "`"$outputFile`""
            )
            $argsPass2 = $pass2 -join " "
            $sucessoPass2 = Invoke-FFmpeg -Arguments $argsPass2 -PassName "Pass 2" -CurrentFileName $baseFileName
            if ($sucessoPass2) { $fileCounter++ }
        }

        # Atualiza progresso
        $percent = [math]::Floor(($fileCounter / $totalFiles) * 100)
        if ($percent -gt 100) { $percent = 100 }
        if ($percent -lt 0) { $percent = 0 }
        $progressBar.Value = $percent
        [System.Windows.Forms.Application]::DoEvents()
        $statusLabel.Text = "Processando `$baseFileName`: $percent% concluído."
    }

    # 4.2.7 – Fim do loop de arquivos
    if ($fileCounter -eq 0) {
        $statusLabel.Text = "Nenhum arquivo convertido com sucesso."
    } elseif ($fileCounter -lt $totalFiles) {
        $statusLabel.Text = "$fileCounter de $totalFiles arquivos convertidos (alguns falharam)."
    } else {
        $statusLabel.Text = "$fileCounter de $totalFiles arquivos convertidos com sucesso."
    }
    [System.Windows.Forms.MessageBox]::Show(
        "Processo concluído! Verifique a pasta de saída e os logs em:`n$outputDir",
        "Concluído",
        [System.Windows.Forms.MessageBoxButtons]::OK,
        [System.Windows.Forms.MessageBoxIcon]::Information
    )
    $progressBar.Value = 0
})

# Quando fechar o formulário, interrompe o script
$form.Add_FormClosing({
    # Aqui você pode colocar código para cancelar jobs em background, se usou algum.
})

$form.Topmost = $true
[void] $form.ShowDialog()
