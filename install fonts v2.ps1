[CmdletBinding()]
param ()

Start-Transcript -Path $(Join-Path $env:TEMP "InstallFont.log")

# Helper function
function Install-Font {
    [CmdletBinding()]
    param (
        # Path which points to font file (*.otf / *.ttf)
        [Parameter(Mandatory)]
        [ValidateScript( { Test-Path $_ })]
        [string]
        $FontPath
    )
    
    begin {
        $supportedFonts = @{
            ".otf" = "OpenType"
            ".ttf" = "TrueType"
        }
    }
    
    process {
        try {
            $font = Get-Item -Path $FontPath
            $fontType = $font.Extension
    
            if ($supportedFonts.Keys -contains $fontType) {
                
                Write-Output "'$($font.Name)' is $($supportedFonts[$fontType]) font"
                
                # Copy and reference font
                $fontRegistryLocation = "HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
                $null = Copy-Item -Path $font.FullName -Destination "C:\Windows\Fonts\" -Force -EA Stop
                $null = New-ItemProperty -Name "$($font.BaseName) ($($supportedFonts[$fontType]))" -Path $fontRegistryLocation -PropertyType string -Value $font.Name -Force -EA Stop
    
                Write-Output "Installed font '$($font.Name)'"
            }
            else {
                Write-Warning "Unrecognized font type '$($fontType)' $($font.Name)"
            }
        }
        catch {
            Write-Error $_
        }
    }
}

# Main script
$fontFolderName = "fonts"
$potentialFonts = Get-ChildItem -Path $(Join-Path $PSScriptRoot $fontFolderName)

foreach ($font in $potentialFonts) {
    Install-Font -FontPath $font.FullName
}

Stop-Transcript
