BeforeAll {
    # Import the module
    Import-Module "$PSScriptRoot\..\src\InstagramEncoder.psd1" -Force
}

Describe "Start-InstagramEncoder" {
    Context "Parameter validation" {
        It "Should throw an error when an invalid file path is provided" {
            { Start-InstagramEncoder -InputPath "NonExistentFile.mp4" -Resolution "1080x1920" -EncodingMode "CRF" } | 
                Should -Throw "File not found"
        }

        It "Should throw an error when an invalid resolution format is provided" {
            Mock Test-Path { return $true }
            { Start-InstagramEncoder -InputPath "test.mp4" -Resolution "invalid" -EncodingMode "CRF" } | 
                Should -Throw "Cannot validate argument on parameter 'Resolution'"
        }

        It "Should throw an error when an invalid aspect ratio is provided" {
            Mock Test-Path { return $true }
            { Start-InstagramEncoder -InputPath "test.mp4" -Resolution "800x600" -EncodingMode "CRF" } | 
                Should -Throw "must have a 16:9 or 9:16 aspect ratio"
        }

        It "Should throw an error when CRF value is out of range" {
            Mock Test-Path { return $true }
            { Start-InstagramEncoder -InputPath "test.mp4" -Resolution "1080x1920" -EncodingMode "CRF" -CRFValue 25 } | 
                Should -Throw "CRF value must be between 17 and 22"
        }

        It "Should throw an error when Bitrate format is invalid" {
            Mock Test-Path { return $true }
            { Start-InstagramEncoder -InputPath "test.mp4" -Resolution "1080x1920" -EncodingMode "Two-Pass" -Bitrate "3000" } | 
                Should -Throw "Bitrate must be in the format"
        }
    }
}