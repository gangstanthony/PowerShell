function Get-MappedDrives {
    param (
        $computer = $env:COMPUTERNAME
    )

    Get-RemoteRegistry -hive 'users' -comps $computer | ? {$_.RegKeyName -match '\d{4,5}$'} | % {
        $sid = $_.regkeyname
        Get-RemoteRegistry -hive Users -keys "$sid\Network" -comps $computer |
          select `
            @{n='Computer';e={$computer}},
            @{n='User';e={([System.Security.Principal.SecurityIdentifier]($sid)).Translate([System.Security.Principal.NTAccount]).Value}},
            @{n='DriveLetter';e={$_.RegKeyName}},
            @{n='Map';e={$_.RemotePath.Value}}
    }
}
