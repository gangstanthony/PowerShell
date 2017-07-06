# https://www.reddit.com/r/PowerShell/comments/6lo8b5/config_settings_check/

function Get-Powercfg {
    $schemes = powercfg /l | ? {$_ -match ':'} | % {
        $split = $_ -split ':|\s{2}' | % {$_.trim()}

        $guid = $split[1]
        $name = $split[2]

        $active = $name.endswith('*')

        if ($active) {
            $name = $name.substring(1, $name.length - 4)
        } else {
            $name = $name.substring(1, $name.length - 2)
        }

        [pscustomobject]@{
            GUID = $guid
            Name = $name
            Active = $active
        }
    }

    $props = New-Object System.Collections.ArrayList
    $props.AddRange(@(
        'GUID'
        'Name'
        'Active'
        'SubGUID'
        'SubName'
        'SubAlias'
        'SettingGUID'
        'SettingName'
        'SettingAlias'
    ))

    $results = foreach ($scheme in $schemes) {
        $settings = powercfg /q $scheme.guid
        $settings = $settings.trim()

        $hash = @{
            GUID = $scheme.GUID
            Name = $scheme.Name
            Active = $scheme.Active
        }

        $start = $setsubguid = $subguid = $setsettingalias = 0
        foreach ($line in $settings) {
            if ($line.startswith('Subgroup GUID')) {
                $start = 1
                $split = $line -split ':|\s{2}' | % {$_.trim()}
                $hash.Add('SubGUID', $split[1])
                if ($split[2]) {
                    $hash.Add('SubName', $split[2].substring(1, $split[2].length - 2))
                }
                $subguid = 1
                $setsubguid = 1
            } elseif ($line.StartsWith('GUID Alias') -and $subguid -eq 1) {
                $hash.Add('SubAlias', $line.Split(':', 2)[1].trim())
                $subguid = 0
            } elseif ($line.StartsWith('Power Setting GUID')) {
                if (!$setsubguid) {
                    $i = $back = 0
                    while ($hash.Keys -notcontains 'SubGUID' -and $i -ge 0) {
                        $back++
                        $i = $settings.IndexOf($line) - $back
                        $ln = $settings[$i]
                        if ($ln.startswith('Subgroup GUID')) {
                            $split = $ln -split ':|\s{2}' | % {$_.trim()}
                            $hash.Add('SubGUID', $split[1])
                            if ($split[2]) {
                                $hash.Add('SubName', $split[2].substring(1, $split[2].length - 2))
                            }
                            $setsubguid = 1
                            $ln = $settings[$i + 1]
                            if ($ln.StartsWith('GUID Alias')) {
                                $hash.Add('SubAlias', $ln.Split(':', 2)[1].trim())
                            }
                        }
                    }
                }
                $split = $line -split ':|\s{2}' | % {$_.trim()}
                $hash.Add('SettingGUID', $split[1])
                if ($split[2]) {
                    $hash.Add('SettingName', $split[2].substring(1, $split[2].length - 2))
                }
            } elseif ($line.StartsWith('GUID Alias')) {
                if (!$start) {
                    continue
                }
                $hash.Add('SettingAlias', $line.Split(':', 2)[1].trim())
                $setsettingalias = 1
            } elseif ($line -match ':') {
                if (!$setsettingalias) {
                    $setsettingalias = 1
                    continue
                }
                $split = $line.Split(':', 2).trim()
                $split[0] = $split[0].Replace(' ', '')
                $num = 0
                $new = $split[0] + $num
                while ($hash.Keys -contains $new) {
                    $num++
                    $new = $split[0] + $num
                }
                $hash.Add($new, $split[1])
                if (!$props.Contains($new)) {
                    $props.Add($new) | Out-Null
                }
            } else {
                [pscustomobject]$hash
                $hash = @{
                    GUID = $scheme.GUID
                    Name = $scheme.Name
                    Active = $scheme.Active
                }
                $setsubguid = 0
            }
        }
    }

    $results | select $props
}
