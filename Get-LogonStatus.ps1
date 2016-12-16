# https://gallery.technet.microsoft.com/scriptcenter/Get-Remote-Logon-Status-d8c2318a

function Get-LogonStatus ($computer = $env:COMPUTERNAME) {
    $hash = @{
        Computer = $computer
        Name = '-'
        User = '-'
        Status = '-'
    }

    $obj = gwmi win32_computersystem -ComputerName $computer -ea 0
    $hash.User = $obj.username
    $hash.Name = $obj.name

    try {
        epsr $computer

        if ($hash.User -notmatch '^(?:-|not logged on)$' -and (Get-Process logonui -ComputerName $computer -ErrorAction Stop)) {
            $hash.Status = 'Locked'
        }
    } catch {
        if ($hash.User -notmatch '^(?:-|not logged on)$') {
            $hash.Status = 'Logged on'
        } else {
            $hash.Status = 'Not logged on'
        }
    }

    New-Object psobject -Property $hash
}
