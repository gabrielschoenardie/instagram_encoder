@{
    RootModule = 'InstagramEncoder.psm1'
    ModuleVersion = '1.0.0'
    GUID = 'e2a73eff-e454-4abf-8af1-1016d5a5150e'
    Author = 'Your Name'
    CompanyName = 'Your Company'
    Copyright = '(c) 2025. All rights reserved.'
    Description = 'Advanced H.264 video encoder optimized for Instagram'
    PowerShellVersion = '5.1'
    FunctionsToExport = @('Start-InstagramEncoder')
    CmdletsToExport = @()
    VariablesToExport = '*'
    AliasesToExport = @()
    PrivateData = @{
        PSData = @{
            Tags = @('Instagram', 'Video', 'Encoding', 'FFmpeg', 'H264')
            LicenseUri = 'https://github.com/yourusername/instagram_encoder/LICENSE'
            ProjectUri = 'https://github.com/yourusername/instagram_encoder'
            ReleaseNotes = 'Initial release of Instagram Encoder module'
        }
    }
}