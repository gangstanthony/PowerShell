# https://serverfault.com/questions/429240/how-do-you-manage-network-locations-through-domain-group-policies

function Get-NetworkShortcut {
    param (
        [string]$ComputerName = $env:COMPUTERNAME
    )

    function Get-Shortcut ($path) {
        $WshShell = New-Object -ComObject WScript.Shell
        $Shortcut = $WshShell.CreateShortcut($Path)
        $Shortcut | select *
        function Release-Ref ($ref) {
            ([System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.__ComObject]$ref) -gt 0)
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
        }
        $Shortcut, $WshShell | % {$null = Release-Ref $_}
    }

    $users = dir "\\$ComputerName\c$\users" -Directory | % {$_.Name}

    foreach ($user in $users) {
        $networkshortcuts_path = "\\$ComputerName\c$\users\$user\AppData\Roaming\Microsoft\Windows\Network Shortcuts"
        
        try {
            $folders = dir $networkshortcuts_path -ea stop
        } catch {
            continue
        }

        foreach ($folder in $folders) {
            [pscustomobject]@{
                User = $user
                Name = $folder.name
                Target = (get-shortcut $(join-path $folder.fullname 'target.lnk')).targetpath
            }
        }
    }
}
