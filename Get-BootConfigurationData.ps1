# https://www.reddit.com/r/PowerShell/comments/4fyfau/does_anyone_know_of_a_module_or_wrapper_for/

# must be admin

function Get-BootConfigurationData {
    param (
        $bcdeditpath = (Join-Path $env:SystemRoot 'system32\bcdedit.exe')
    )

    $bootconfigurationdata = iex $bcdeditpath
    $bootconfigurationdata += ''

    $hash = $null
    $result = foreach ($line in $bootconfigurationdata) {
        if ($line -eq '') {
            if ($hash) {
                [pscustomobject]$hash
            }
            $hash = @{}
            continue
        }
        if ($line.startswith('-----')) { continue }
        if ($line.startswith('Windows Boot')) {
            $hash.Add('Type', $line)
        } else {
            $name = $line.Substring(0, $line.IndexOf(' '))
            $value = $line.Substring($line.IndexOf(' ')).trim()
            $hash.Add($name, $value)
        }
    }

    $props = $result | % {gm -in $_ -ty *property} | % name | select -u | sort

    $result | select $props
}
