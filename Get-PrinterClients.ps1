# KNOWN ISSUES:
# only finds printers that are *NOT* locally hosted
# if looking for all possible printers, might have to use Get-PrinterHosts as well
# 
# REQUIRES:
# admin rights

function Get-PrinterClients {
    Param (
        [string]$comp = $env:COMPUTERNAME
    )
    
    if (!$comp) { throw 'No comp.' }

    $ping = New-Object System.Net.NetworkInformation.Ping
    try {
        $result = $ping.Send($comp)
    } catch {
        $result = $null
    }

    if ($result.Status -eq 'Success') {
        $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('Users', $comp)
        [string[]]$users = $reg.GetSubKeyNames() | ? {$_ -match '-\d{5}$'}
        foreach ($user in $users) {
            try {
                $printers = $reg.OpenSubKey("$user\printers\connections").GetSubKeyNames()
            } catch {
                $printers = '-'
            }

            if ($printers -ne '-') {
                $printers = @($printers | % {$_.Substring(2).Replace(',', '\').ToUpper()} | select -Unique) -join '; '
            }

            [pscustomobject]@{
                Computer = $comp
                IP = $result.Address.ToString()
                User = ([System.Security.Principal.SecurityIdentifier]($user)).Translate([System.Security.Principal.NTAccount]).Value
                Printer = $printers
            }
        }
    } else {
        [pscustomobject]@{
            Computer = $comp
            IP = '-'
            User = '-'
            Printer = '-'
        }
    }
}
