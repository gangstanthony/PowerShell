# this is my own learning of accessing the registry on remote computers.
# for a more complete solution, i recommend http://archive.msdn.microsoft.com/PSRemoteRegistry

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
                    $obj = New-Object psobject
                    $obj | Add-Member NoteProperty 'RegKeyName' $subkey
                    try{ $obj | Add-Member NoteProperty 'RegKeyParent' $key }catch{}
                    try{ $obj | Add-Member NoteProperty 'RegKeyChildren' $subregistry.GetSubKeyNames() }catch{}
                    try{ $names = $subregistry.GetValueNames() }catch{}
                    foreach ($name in ($names | ? {$_})) {
                        $obj | Add-Member NoteProperty $name $(
                            $value = New-Object psobject
                            $value | Add-Member NoteProperty 'Type' $subregistry.GetValueKind($name)
                            $value | Add-Member NoteProperty 'Value' $subregistry.GetValue($name)
                            $value
                        )
                    }
                    $obj
                }
            } else {
                try{ $subregistry = $registry.OpenSubKey($key) }catch{}
                $obj = New-Object psobject
                $obj | Add-Member NoteProperty 'RegKeyName' $(Split-Path $key -Leaf)
                try{ $obj | Add-Member NoteProperty 'RegKeyParent' $(Join-Path $hive (Split-Path $key)) }catch{}
                try{ $obj | Add-Member NoteProperty 'RegKeyChildren' $subregistry.GetSubKeyNames() }catch{}
                try{ $names = $subregistry.GetValueNames() }catch{}
                foreach ($name in ($names | ? {$_})) {
                    $obj | Add-Member NoteProperty $name $(
                        $value = New-Object psobject
                        $value | Add-Member NoteProperty 'Type' $subregistry.GetValueKind($name)
                        $value | Add-Member NoteProperty 'Value' $subregistry.GetValue($name)
                        $value
                    )
                }
                $obj
            }
        }
    }
}
