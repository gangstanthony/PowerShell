# this is my own learning of accessing the registry on remote computers.
# for a more complete solution, i recommend https://psremoteregistry.codeplex.com/

function Set-RemoteRegistry {
    param (
        $comp = $env:COMPUTERNAME,
        [ValidateSet('ClassesRoot', 'CurrentUser', 'LocalMachine', 'Users', 'PerformanceData', 'CurrentConfig', 'DynData')]
        [string]$hive = 'LocalMachine',
        [string]$key = $(Throw 'No Key provided'),
        [ValidateSet('Binary', 'DWord', 'ExpandString', 'MultiString', 'None', 'QWord', 'String', 'Unknown')]
        [string]$type,
        [string]$value = $(Throw 'No Value provided'),
        [string]$data,
        [switch]$delete = $false
    )

    $registry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($hive, $comp).OpenSubKey($key, [Microsoft.Win32.RegistryKeyPermissionCheck]::ReadWriteSubTree)

    if (!$delete) {
        try {
            $registry.SetValue($value, $data, $type)
            [pscustomobject]@{
                Computer = $comp;
                    Hive = $hive;
                     Key = $key;
                   Value = $value;
                    Data = $data;
                    Type = $type;
                  Delete = $delete
            }
        } catch {
            write-error $error[0]
            return
        }
    } else {
        try {
            $registry.DeleteValue($value)
            [pscustomobject]@{
                Computer = $comp;
                    Hive = $hive;
                     Key = $key;
                   Value = $value;
                    Data = $data;
                    Type = $type;
                  Delete = $delete
            }
        } catch {
            write-error $error[0]
            return
        }
    }
}

function Get-RemoteRegistry {
    param (
        $comps = $env:COMPUTERNAME,
        [ValidateSet('ClassesRoot', 'CurrentUser', 'LocalMachine', 'Users', 'PerformanceData', 'CurrentConfig', 'DynData')]
        [string]$hive = 'LocalMachine',
        [string[]]$keys = '',
        $subs = $true
    )

    foreach ($comp in $comps) {
        $registry = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey($hive, $comp)
        foreach ($key in $keys) {
            if ($subs) {
                $subkeys = $registry.OpenSubKey($key).GetSubKeyNames()
                foreach ($subkey in $subkeys) {
                    try{ $subregistry = $registry.OpenSubKey("$key\$subkey") }catch{}
                    $hash = @{}
                    $hash.Add('RegKeyName', $subkey)
                    try{ $hash.Add('RegKeyParent', $key) }catch{}
                    try{ $hash.Add('RegKeyChildren', $subregistry.GetSubKeyNames()) }catch{}
                    try{ $names = $subregistry.GetValueNames() }catch{}
                    foreach ($name in ($names | ? {$_})) {
                        $hash.Add($name, $(
                            [pscustomobject]@{
                                Type = $subregistry.GetValueKind($name)
                                Value = $subregistry.GetValue($name)
                            }
                        ))
                    }
                    [pscustomobject]$hash
                }
            } else {
                try{ $subregistry = $registry.OpenSubKey($key) }catch{}
                $hash = @{}
                $hash.Add('RegKeyName', $(Split-Path $subregistry -Leaf))
                try{ $hash.Add('RegKeyParent', $(Join-Path $hive (Split-Path $key))) }catch{}
                try{ $hash.Add('RegKeyChildren', $subregistry.GetSubKeyNames()) }catch{}
                try{ $names = $subregistry.GetValueNames() }catch{}
                foreach ($name in ($names | ? {$_})) {
                    $hash.Add($name, $(
                        [pscustomobject]@{
                            Type = $subregistry.GetValueKind($name)
                            Value = $subregistry.GetValue($name)
                        }
                    ))
                }
                [pscustomobject]$hash
            }
        }
    }
}
