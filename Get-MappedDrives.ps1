function Get-MappedDrives {
    param (
        $computer = $env:COMPUTERNAME
    )

    $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('Users', $computer)
    $reg.GetSubKeyNames() | ? {$_ -match '\d{4,5}$'} | % {
        $sid = $_
        $reg.OpenSubKey("$sid\Network").GetSubKeyNames() | % {
            New-Object psobject -Property @{
                Computer = $computer
                User = ([System.Security.Principal.SecurityIdentifier]($sid)).Translate([System.Security.Principal.NTAccount]).Value
                DriveLetter = $_
                Map = $reg.OpenSubKey("$sid\Network\$_").GetValue('RemotePath')
            }
        }
    }
}
