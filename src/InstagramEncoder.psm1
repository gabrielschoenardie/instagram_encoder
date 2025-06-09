# InstagramEncoder.psm1
#Requires -Version 5.1

# Import private functions
$privateFunctions = Get-ChildItem -Path "$PSScriptRoot\Private" -Filter "*.ps1" -Recurse -ErrorAction SilentlyContinue
foreach ($function in $privateFunctions) {
    try {
        . $function.FullName
    }
    catch {
        Write-Error "Failed to import function $($function.FullName): $_"
    }
}

<#
.SYNOPSIS
    Converts videos to formats optimized for Instagram.

.DESCRIPTION
    Converts videos to H.264 format optimized for Instagram Reels, Stories, or Feed.
    Supports both CRF (Constant Rate Factor) and Two-Pass encoding modes,
    with automatic adjustment for vertical (9:16) or horizontal (16:9) aspect ratios.

.PARAMETER InputPath
    Path to the input video file. Supported formats: .mp4, .mov, .mkv, .avi

.PARAMETER Resolution
    Target resolution for the output video. Use 1080x1920 for vertical (9:16, Reels/Stories)
    or 1920x1080 for horizontal (16:9, Feed) videos.

.PARAMETER EncodingMode
    Encoding mode to use: 'CRF' for quality-based encoding or 'Two-Pass' for bitrate-based encoding.

.PARAMETER CRFValue
    The Constant Rate Factor value (17-22). Lower values mean higher quality and larger files.
    Only used when EncodingMode is set to 'CRF'.

.PARAMETER Bitrate
    Target bitrate for Two-Pass encoding (e.g., '3000k', '6000k').
    Only used when EncodingMode is set to 'Two-Pass'.

.PARAMETER OutputDirectory
    Directory where the encoded video will be saved. If not specified, defaults to
    'convertidos_h264_instagram_avancado' in the current directory.

.EXAMPLE
    Start-InstagramEncoder -InputPath "C:\videos\myvideo.mp4" -Resolution "1080x1920" -EncodingMode "CRF" -CRFValue 18

.EXAMPLE
    Start-InstagramEncoder -InputPath "C:\videos\myvideo.mp4" -Resolution "1920x1080" -EncodingMode "Two-Pass" -Bitrate "3000k"

.NOTES
    Requires FFmpeg to be installed and available in the system PATH.
    Author: Your Name
    Version: 1.0.0
#>
function Start-InstagramEncoder {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [ValidateScript({
            if (-not (Test-Path -LiteralPath $_ -PathType Leaf)) {
                throw "File not found: $_"
            }
            $extension = [System.IO.Path]::GetExtension($_).ToLower()
            if ($extension -notin @('.mp4', '.mov', '.mkv', '.avi')) {
                throw "Unsupported file format: $extension. Supported formats: .mp4, .mov, .mkv, .avi"
            }
            return $true
        })]
        [string]$InputPath,

        [Parameter(Mandatory = $true)]
        [ValidatePattern('^(\d+)x(\d+)$')]
        [ValidateScript({
            $resolution = $_ -split 'x'
            $width = [int]$resolution[0]
            $height = [int]$resolution[1]
            
            # Check for 16:9 or 9:16 aspect ratio (with a small tolerance)
            $ratio = $width / $height
            $isVertical = [Math]::Abs($ratio - (9/16)) -lt 0.01
            $isHorizontal = [Math]::Abs($ratio - (16/9)) -lt 0.01
            
            if (-not ($isVertical -or $isHorizontal)) {
                throw "Resolution must have a 16:9 or 9:16 aspect ratio. Valid examples: 1920x1080 or 1080x1920"
            }
            return $true
        })]
        [string]$Resolution,

        [Parameter(Mandatory = $true)]
        [ValidateSet('CRF', 'Two-Pass')]
        [string]$EncodingMode,

        [Parameter(Mandatory = $false)]
        [ValidateScript({
            if ($EncodingMode -eq 'CRF' -and ($_ -lt 17 -or $_ -gt 22)) {
                throw "CRF value must be between 17 and 22"
            }
            return $true
        })]
        [int]$CRFValue = 18,

        [Parameter(Mandatory = $false)]
        [ValidateScript({
            if ($EncodingMode -eq 'Two-Pass' -and -not ($_ -match '^\d+k$')) {
                throw "Bitrate must be in the format: <number>k (e.g., 3000k)"
            }
            return $true
        })]
        [string]$Bitrate = "3000k",

        [Parameter(Mandatory = $false)]
        [string]$OutputDirectory = "convertidos_h264_instagram_avancado"
    )

    Begin {
        # Verify FFmpeg is installed
        try {
            $ffmpegVersion = & ffmpeg -version
            Write-Verbose "FFmpeg detected: $($ffmpegVersion[0])"
        }
        catch {
            throw "FFmpeg is not installed or not available in the system PATH. Please install FFmpeg and try again."
        }

        # Create output directories
        $outputPath = Join-Path -Path (Get-Location) -ChildPath $OutputDirectory
        $logsDirectory = Join-Path -Path $outputPath -ChildPath "ffmpeg_logs"
        
        if (-not (Test-Path -Path $outputPath)) {
            New-Item -Path $outputPath -ItemType Directory -Force | Out-Null
            Write-Verbose "Created output directory: $outputPath"
        }
        
        if (-not (Test-Path -Path $logsDirectory)) {
            New-Item -Path $logsDirectory -ItemType Directory -Force | Out-Null
            Write-Verbose "Created logs directory: $logsDirectory"
        }

        # Parse resolution
        $resolutionParts = $Resolution -split 'x'
        $width = [int]$resolutionParts[0]
        $height = [int]$resolutionParts[1]
        $isVertical = $width -lt $height

        # Determine the appropriate video filter based on aspect ratio
        if ($isVertical) {
            $videoFilter = "scale=if(gt(a,9/16),1080,-2):if(gt(a,9/16),-2,1920):flags=lanczos,format=yuv420p"
            Write-Verbose "Using vertical (9:16) video filter"
        }
        else {
            $videoFilter = "scale=if(gt(a,16/9),1920,-2):if(gt(a,16/9),-2,1080):flags=lanczos,format=yuv420p"
            Write-Verbose "Using horizontal (16:9) video filter"
        }

        # Prepare output filename
        $inputFileInfo = Get-Item -LiteralPath $InputPath
        $outputFileName = "{0}_INSTA_H264_ADV.mp4" -f $inputFileInfo.BaseName
        $outputFilePath = Join-Path -Path $outputPath -ChildPath $outputFileName
        
        Write-Verbose "Input file: $InputPath"
        Write-Verbose "Output file: $outputFilePath"
    }

    Process {
        # Build FFmpeg arguments based on encoding mode
        $baseParams = @(
            "-i", "`"$InputPath`"",
            "-c:v", "libx264",
            "-preset", "slow",
            "-tune", "film",
            "-profile:v", "high",
            "-level", "4.1",
            "-pix_fmt", "yuv420p",
            "-color_primaries", "bt709",
            "-color_trc", "bt709",
            "-colorspace", "bt709",
            "-r", "30",
            "-g", "30",
            "-keyint_min", "30",
            "-sc_threshold", "0",
            "-vf", "`"$videoFilter`"",
            "-x264-params", "`"bf=3:b_strategy=2:refs=5:coder=ac:aq-mode=2:psy-rd=1.0:0.15`""
        )

        if ($EncodingMode -eq 'CRF') {
            Write-Verbose "Using CRF encoding mode with value: $CRFValue"
            
            # Log file for CRF mode
            $logFile = Join-Path -Path $logsDirectory -ChildPath "$($inputFileInfo.BaseName)_crf.log"
            
            # Add CRF-specific parameters
            $crfParams = $baseParams + @(
                "-crf", "$CRFValue",
                "-c:a", "aac",
                "-b:a", "192k",
                "-ar", "48000",
                "-ac", "2",
                "-y", "`"$outputFilePath`""
            )
            
            # Execute FFmpeg with CRF parameters
            Write-Verbose "Starting CRF encoding..."
            $process = Start-Process -FilePath "ffmpeg" -ArgumentList $crfParams -NoNewWindow -PassThru -RedirectStandardError $logFile
            
            # Wait for the process to complete
            $process.WaitForExit()
            
            # Check if FFmpeg succeeded
            if ($process.ExitCode -ne 0) {
                Write-Error "FFmpeg encoding failed with exit code $($process.ExitCode). See log file for details: $logFile"
                return $false
            }
        }
        else { # Two-Pass encoding
            Write-Verbose "Using Two-Pass encoding mode with bitrate: $Bitrate"
            
            # Log files for two-pass encoding
            $logFile1 = Join-Path -Path $logsDirectory -ChildPath "$($inputFileInfo.BaseName)_pass1.log"
            $logFile2 = Join-Path -Path $logsDirectory -ChildPath "$($inputFileInfo.BaseName)_pass2.log"
            
            # First pass parameters
            $pass1Params = $baseParams + @(
                "-b:v", "$Bitrate",
                "-pass", "1",
                "-an",
                "-f", "null",
                "NUL"
            )
            
            # Second pass parameters
            $pass2Params = $baseParams + @(
                "-b:v", "$Bitrate",
                "-pass", "2",
                "-c:a", "aac",
                "-b:a", "192k",
                "-ar", "48000",
                "-ac", "2",
                "-y", "`"$outputFilePath`""
            )
            
            # Execute first pass
            Write-Verbose "Starting Two-Pass encoding (Pass 1)..."
            $process1 = Start-Process -FilePath "ffmpeg" -ArgumentList $pass1Params -NoNewWindow -PassThru -RedirectStandardError $logFile1
            
            # Wait for the first pass to complete
            $process1.WaitForExit()
            
            # Check if the first pass succeeded
            if ($process1.ExitCode -ne 0) {
                Write-Error "FFmpeg first pass failed with exit code $($process1.ExitCode). See log file for details: $logFile1"
                return $false
            }
            
            # Execute second pass
            Write-Verbose "Starting Two-Pass encoding (Pass 2)..."
            $process2 = Start-Process -FilePath "ffmpeg" -ArgumentList $pass2Params -NoNewWindow -PassThru -RedirectStandardError $logFile2
            
            # Wait for the second pass to complete
            $process2.WaitForExit()
            
            # Check if the second pass succeeded
            if ($process2.ExitCode -ne 0) {
                Write-Error "FFmpeg second pass failed with exit code $($process2.ExitCode). See log file for details: $logFile2"
                return $false
            }
        }
    }

    End {
        if (Test-Path -LiteralPath $outputFilePath) {
            Write-Output "Encoding completed successfully!"
            Write-Output "Output file: $outputFilePath"
            return $true
        }
        else {
            Write-Error "Encoding process completed, but output file not found: $outputFilePath"
            return $false
        }
    }
}


Export-ModuleMember -Function 'Start-InstagramEncoder'