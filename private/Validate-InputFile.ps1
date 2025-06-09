function Validate-InputFile {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$FilePath
    )

    if (-not (Test-Path -LiteralPath $FilePath -PathType Leaf)) {
        throw "File not found: $FilePath"
    }

    $extension = [System.IO.Path]::GetExtension($FilePath).ToLower()
    if ($extension -notin @('.mp4', '.mov', '.mkv', '.avi')) {
        throw "Unsupported file format: $extension. Supported formats: .mp4, .mov, .mkv, .avi"
    }

    return $true
}