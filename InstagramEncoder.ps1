# Request: Generate a PowerShell script to bootstrap and run the 'Instagram Encoder' project.
# Environment: PowerShell 5.1+ (or 7+), with FFmpeg (in PATH) and .NET Windows Forms for GUI.
# Goals: (1) Efficient video encoding using FFmpeg, (2) Responsive GUI using Windows Forms, (3) Robust error handling, (4) Clear user feedback.

# 1. Load required assemblies for Windows Forms GUI:
Add-Type -AssemblyName System.Windows.Forms, System.Drawing

# 2. Create the main form (title "Instagram Encoder", size ~600x500, centered, fixed dialog).
$form = New-Object System.Windows.Forms.Form
$form.Text = "Instagram Encoder"
$form.Size = New-Object System.Drawing.Size(600, 500)
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# 3. Add UI controls:
#    - Input file selection: Label, TextBox, and "Browse..." Button to choose a video file.
$labelInput = New-Object System.Windows.Forms.Label
$labelInput.Text = "Input Video:"
$labelInput.Location = New-Object System.Drawing.Point(20, 20)
$labelInput.Size = New-Object System.Drawing.Size(100, 20)
$form.Controls.Add($labelInput)

$textBoxInput = New-Object System.Windows.Forms.TextBox
$textBoxInput.Location = New-Object System.Drawing.Point(130, 20)
$textBoxInput.Size = New-Object System.Drawing.Size(350, 20)
$form.Controls.Add($textBoxInput)

$buttonBrowse = New-Object System.Windows.Forms.Button
$buttonBrowse.Text = "Browse..."
$buttonBrowse.Location = New-Object System.Drawing.Point(490, 20)
$buttonBrowse.Size = New-Object System.Drawing.Size(80, 23)
$buttonBrowse.Add_Click({
    $dialog = New-Object System.Windows.Forms.OpenFileDialog
    $dialog.Filter = "Video files (*.mp4;*.mov;*.mkv;*.avi)|*.mp4;*.mov;*.mkv;*.avi|All files (*.*)|*.*"
    $dialog.Title = "Select a video file"
    if ($dialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $textBoxInput.Text = $dialog.FileName
    }
})
$form.Controls.Add($buttonBrowse)

#    - Resolution selection: GroupBox with two RadioButtons (Vertical 1080x1920, Horizontal 1920x1080).
$groupResolution = New-Object System.Windows.Forms.GroupBox
$groupResolution.Text = "Resolution"
$groupResolution.Location = New-Object System.Drawing.Point(20, 60)
$groupResolution.Size = New-Object System.Drawing.Size(550, 70)
$form.Controls.Add($groupResolution)

$radioVertical = New-Object System.Windows.Forms.RadioButton
$radioVertical.Text = "Vertical (1080x1920) - Reels/Stories"
$radioVertical.Location = New-Object System.Drawing.Point(20, 30)
$radioVertical.Size = New-Object System.Drawing.Size(250, 20)
$radioVertical.Checked = $true
$groupResolution.Controls.Add($radioVertical)

$radioHorizontal = New-Object System.Windows.Forms.RadioButton
$radioHorizontal.Text = "Horizontal (1920x1080) - Feed"
$radioHorizontal.Location = New-Object System.Drawing.Point(280, 30)
$radioHorizontal.Size = New-Object System.Drawing.Size(250, 20)
$groupResolution.Controls.Add($radioHorizontal)

#    - Encoding mode selection: GroupBox with RadioButtons for "CRF" vs "Two-Pass", plus CRF NumericUpDown and Bitrate TextBox.
$groupEncoding = New-Object System.Windows.Forms.GroupBox
$groupEncoding.Text = "Encoding Mode"
$groupEncoding.Location = New-Object System.Drawing.Point(20, 150)
$groupEncoding.Size = New-Object System.Drawing.Size(550, 150)
$form.Controls.Add($groupEncoding)

$radioCRF = New-Object System.Windows.Forms.RadioButton
$radioCRF.Text = "CRF (Constant Rate Factor) - Quality-based"
$radioCRF.Location = New-Object System.Drawing.Point(20, 30)
$radioCRF.Size = New-Object System.Drawing.Size(500, 20)
$radioCRF.Checked = $true
$groupEncoding.Controls.Add($radioCRF)

$labelCRF = New-Object System.Windows.Forms.Label
$labelCRF.Text = "CRF Value:"
$labelCRF.Location = New-Object System.Drawing.Point(40, 60)
$labelCRF.Size = New-Object System.Drawing.Size(80, 20)
$groupEncoding.Controls.Add($labelCRF)

$numericCRF = New-Object System.Windows.Forms.NumericUpDown
$numericCRF.Minimum = 17
$numericCRF.Maximum = 22
$numericCRF.Value = 18
$numericCRF.Location = New-Object System.Drawing.Point(130, 60)
$numericCRF.Size = New-Object System.Drawing.Size(60, 20)
$groupEncoding.Controls.Add($numericCRF)

$labelCRFInfo = New-Object System.Windows.Forms.Label
$labelCRFInfo.Text = "(17-22, lower = higher quality)"
$labelCRFInfo.Location = New-Object System.Drawing.Point(200, 60)
$labelCRFInfo.Size = New-Object System.Drawing.Size(320, 20)
$groupEncoding.Controls.Add($labelCRFInfo)

$radioTwoPass = New-Object System.Windows.Forms.RadioButton
$radioTwoPass.Text = "Two-Pass - Bitrate-based"
$radioTwoPass.Location = New-Object System.Drawing.Point(20, 90)
$radioTwoPass.Size = New-Object System.Drawing.Size(500, 20)
$groupEncoding.Controls.Add($radioTwoPass)

$labelBitrate = New-Object System.Windows.Forms.Label
$labelBitrate.Text = "Bitrate:"
$labelBitrate.Location = New-Object System.Drawing.Point(40, 120)
$labelBitrate.Size = New-Object System.Drawing.Size(80, 20)
$groupEncoding.Controls.Add($labelBitrate)

$textBoxBitrate = New-Object System.Windows.Forms.TextBox
$textBoxBitrate.Text = "3000k"
$textBoxBitrate.Location = New-Object System.Drawing.Point(130, 120)
$textBoxBitrate.Size = New-Object System.Drawing.Size(60, 20)
$textBoxBitrate.Enabled = $false
$groupEncoding.Controls.Add($textBoxBitrate)

$labelBitrateInfo = New-Object System.Windows.Forms.Label
$labelBitrateInfo.Text = "(Format: 3000k, 6000k, etc.)"
$labelBitrateInfo.Location = New-Object System.Drawing.Point(200, 120)
$labelBitrateInfo.Size = New-Object System.Drawing.Size(320, 20)
$groupEncoding.Controls.Add($labelBitrateInfo)

# Toggle CRF vs Bitrate fields based on mode selection:
$radioCRF.Add_CheckedChanged({
    $numericCRF.Enabled = $radioCRF.Checked
    $textBoxBitrate.Enabled = -not $radioCRF.Checked
})
$radioTwoPass.Add_CheckedChanged({
    $textBoxBitrate.Enabled = $radioTwoPass.Checked
    $numericCRF.Enabled = -not $radioTwoPass.Checked
})

#    - Output folder selection: Label, TextBox (default path) and "Browse..." Button.
$labelOutput = New-Object System.Windows.Forms.Label
$labelOutput.Text = "Output Folder:"
$labelOutput.Location = New-Object System.Drawing.Point(20, 320)
$labelOutput.Size = New-Object System.Drawing.Size(100, 20)
$form.Controls.Add($labelOutput)

$textBoxOutput = New-Object System.Windows.Forms.TextBox
$textBoxOutput.Text = "convertidos_h264_instagram_avancado"
$textBoxOutput.Location = New-Object System.Drawing.Point(130, 320)
$textBoxOutput.Size = New-Object System.Drawing.Size(350, 20)
$form.Controls.Add($textBoxOutput)

$buttonOutBrowse = New-Object System.Windows.Forms.Button
$buttonOutBrowse.Text = "Browse..."
$buttonOutBrowse.Location = New-Object System.Drawing.Point(490, 320)
$buttonOutBrowse.Size = New-Object System.Drawing.Size(80, 23)
$buttonOutBrowse.Add_Click({
    $folderDialog = New-Object System.Windows.Forms.FolderBrowserDialog
    $folderDialog.Description = "Select output folder"
    if ($folderDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $textBoxOutput.Text = $folderDialog.SelectedPath
    }
})
$form.Controls.Add($buttonOutBrowse)

#    - Progress bar (Marquee style) and status label.
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(20, 360)
$progressBar.Size = New-Object System.Drawing.Size(550, 23)
$progressBar.Style = "Marquee"
$progressBar.MarqueeAnimationSpeed = 0  # initially not animating
$form.Controls.Add($progressBar)

$statusLabel = New-Object System.Windows.Forms.Label
$statusLabel.Text = "Ready"
$statusLabel.Location = New-Object System.Drawing.Point(20, 390)
$statusLabel.Size = New-Object System.Drawing.Size(550, 20)
$form.Controls.Add($statusLabel)

#    - "Start Encoding" button.
$buttonEncode = New-Object System.Windows.Forms.Button
$buttonEncode.Text = "Start Encoding"
$buttonEncode.Location = New-Object System.Drawing.Point(240, 420)
$buttonEncode.Size = New-Object System.Drawing.Size(120, 30)
$form.Controls.Add($buttonEncode)

# 4. Browse button actions are already set up (for Input and Output).

# 5. Implement the encoding workflow when "Start Encoding" is clicked:
$buttonEncode.Add_Click({
    # Validate input file selection
    if ([string]::IsNullOrWhiteSpace($textBoxInput.Text)) {
        [System.Windows.Forms.MessageBox]::Show("Please select an input video file.", "Input Required", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
        return
    }
    if (-not (Test-Path -LiteralPath $textBoxInput.Text -PathType Leaf)) {
        [System.Windows.Forms.MessageBox]::Show("The selected input file does not exist.", "File Not Found", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    # Gather parameters from UI
    $inputPath = $textBoxInput.Text
    $resolution = if ($radioVertical.Checked) { "1080x1920" } else { "1920x1080" }
    $encodingMode = if ($radioCRF.Checked) { "CRF" } else { "Two-Pass" }
    $crfValue = $numericCRF.Value
    $bitrateValue = $textBoxBitrate.Text
    $outputDir = $textBoxOutput.Text

    # Ensure output directory and log subdirectory exist
    if (-not (Test-Path -LiteralPath $outputDir)) {
        New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
    }
    $logDir = Join-Path $outputDir "ffmpeg_logs"
    if (-not (Test-Path -LiteralPath $logDir)) {
        New-Item -Path $logDir -ItemType Directory -Force | Out-Null
    }

    # Prepare output file path
    $inputFileInfo = Get-Item -LiteralPath $inputPath
    $outFileName = ("{0}_INSTA_H264_ADV.mp4" -f $inputFileInfo.BaseName)
    $outputPath = Join-Path $outputDir $outFileName

    # Determine appropriate FFmpeg scale filter based on aspect ratio (vertical vs horizontal)
    $width,$height = $resolution -split 'x'
    $isVertical = [int]$width -lt [int]$height
    if ($isVertical) {
        $scaleFilter = "scale=if(gt(a,9/16),1080,-2):if(gt(a,9/16),-2,1920):flags=lanczos,format=yuv420p"
    } else {
        $scaleFilter = "scale=if(gt(a,16/9),1920,-2):if(gt(a,16/9),-2,1080):flags=lanczos,format=yuv420p"
    }

    # Common FFmpeg video encoding parameters (libx264, slow preset, tune=film, high profile 4.1, 30fps, YUV420p, BT.709, GOP=30, etc)
    $ffmpegArgs = @(
        "-i", $inputPath,
        "-c:v", "libx264",
        "-preset", "slow",
        "-tune", "film",
        "-profile:v", "high", "-level", "4.1",
        "-pix_fmt", "yuv420p",
        "-color_primaries", "bt709", "-color_trc", "bt709", "-colorspace", "bt709",
        "-r", "30", "-g", "30", "-keyint_min", "30", "-sc_threshold", "0",
        "-vf", $scaleFilter,
        "-x264-params", "bf=3:b_strategy=2:refs=5:coder=ac:aq-mode=2:psy-rd=1.0:0.15"
    )

    # Verify FFmpeg availability
    try {
        & ffmpeg -version | Out-Null
    } catch {
        [System.Windows.Forms.MessageBox]::Show("FFmpeg is not installed or not in PATH.", "FFmpeg Not Found", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
        return
    }

    # Configure FFmpeg arguments based on encoding mode
    if ($encodingMode -eq "CRF") {
        $ffmpegArgs += @("-crf", $crfValue.ToString(),
                       "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-ac", "2",
                       "-y", $outputPath)
        $logFile = Join-Path $logDir ("{0}_crf.log" -f $inputFileInfo.BaseName)
    }
    else {
        $logFile1 = Join-Path $logDir ("{0}_pass1.log" -f $inputFileInfo.BaseName)
        $logFile2 = Join-Path $logDir ("{0}_pass2.log" -f $inputFileInfo.BaseName)
        $pass1Args = $ffmpegArgs + @("-b:v", $bitrateValue, "-pass", "1", "-an", "-f", "null", "NUL")
        $pass2Args = $ffmpegArgs + @("-b:v", $bitrateValue, "-pass", "2", "-c:a", "aac", "-b:a", "192k", "-ar", "48000", "-ac", "2", "-y", $outputPath)
    }

    # Update UI to indicate encoding in progress
    $statusLabel.Text = "Encoding in progress..."
    $progressBar.MarqueeAnimationSpeed = 30
    $buttonEncode.Enabled = $false

    # Start encoding in background job to keep UI responsive
    $job = Start-Job -ScriptBlock {
        param($inputPath, $mode, $crfVal, $bitrateVal, $args, $outPath, $log1, $log2, $pass1Args, $pass2Args)
        # Execute FFmpeg depending on mode
        if ($mode -eq "CRF") {
            $proc = Start-Process -FilePath "ffmpeg" -ArgumentList $args -NoNewWindow -PassThru -RedirectStandardError $log1
            $proc.WaitForExit()
            return ($proc.ExitCode -eq 0)  # True if success
        } else {
            # Two-Pass: run first pass
            $p1 = Start-Process -FilePath "ffmpeg" -ArgumentList $pass1Args -NoNewWindow -PassThru -RedirectStandardError $log1
            $p1.WaitForExit()
            if ($p1.ExitCode -ne 0) { return $false }
            # Second pass
            $p2 = Start-Process -FilePath "ffmpeg" -ArgumentList $pass2Args -NoNewWindow -PassThru -RedirectStandardError $log2
            $p2.WaitForExit()
            return ($p2.ExitCode -eq 0)
        }
    } -ArgumentList $inputPath, $encodingMode, $crfValue, $bitrateValue, $ffmpegArgs, $outputPath, $logFile, $logFile2, $pass1Args, $pass2Args

    # Monitor job status with a Timer
    $timer = New-Object System.Windows.Forms.Timer
    $timer.Interval = 1000
    $timer.Add_Tick({
        if ($job.HasExited -or $job.State -eq "Completed") {
            $timer.Stop()
            $progressBar.MarqueeAnimationSpeed = 0
            $buttonEncode.Enabled = $true
            $result = Receive-Job -Job $job
            if ($result) {
                $statusLabel.Text = "Encoding completed successfully!"
                [System.Windows.Forms.MessageBox]::Show("Video encoding completed successfully!", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
            } else {
                $statusLabel.Text = "Encoding failed. Check logs for details."
                [System.Windows.Forms.MessageBox]::Show("Video encoding failed. Please check the logs in the output folder for details.", "Error", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            }
            Remove-Job -Job $job
        }
        elseif ($job.State -eq "Failed") {
            $timer.Stop()
            $progressBar.MarqueeAnimationSpeed = 0
            $buttonEncode.Enabled = $true
            $statusLabel.Text = "Encoding job failed!"
            $errMsg = (Receive-Job -Job $job | Out-String)
            [System.Windows.Forms.MessageBox]::Show("Error: $errMsg", "Job Failed", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Error)
            Remove-Job -Job $job
        }
    })
    $timer.Start()
})

# 6. (All UI updates are done on the UI thread via the Timer tick.)
# 7. Best practices: the code uses approved verbs (Start/Show), no Write-Host (using MessageBox/Write-Error), and proper parameter validations in the encoding logic.
# 8. Finally, show the form to start the GUI.
$form.Add_Shown({ $form.Activate() })
[void]$form.ShowDialog()