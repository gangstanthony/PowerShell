# http://learningpcs.blogspot.com/2012/07/powershell-v3-check-file-headers.html
# https://en.wikipedia.org/wiki/List_of_file_signatures
# http://www.garykessler.net/library/file_sigs.html

function Get-Header {
    param (
        [string]$path,
        [int]$bits = 4
    )
    
    $path = Resolve-FullPath $path

    try {
        # Get content of each file (up to 4 bytes) for analysis
        $HeaderAsHexString = New-Object System.Text.StringBuilder
        [Byte[]](Get-Content -Path $path -TotalCount $bits -Encoding Byte -ea Stop) | % {
            if (("{0:X}" -f $_).length -eq 1) {
                $null = $HeaderAsHexString.Append('0{0:X}' -f $_)
            } else {
                $null = $HeaderAsHexString.Append('{0:X}' -f $_)
            }
        }

        $HeaderAsHexString.ToString()
    } catch {}
}
