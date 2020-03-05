# https://gallery.technet.microsoft.com/scriptcenter/0e43993a-895a-4afe-a2b2-045a5146048a

function Get-LoggedOnUser ($computername = $env:COMPUTERNAME) {
    $regexa = '.+Domain="(.+)",Name="(.+)"$'
    $regexd = '.+LogonId="(\d+)"$'

    $logontype = @{
        0 = 'Local System'
        2 = 'Interactive' #(Local logon)
        3 = 'Network' # (Remote logon)
        4 = 'Batch' # (Scheduled task)
        5 = 'Service' # (Service account logon)
        7 = 'Unlock' #(Screen saver)
        8 = 'NetworkCleartext' # (Cleartext network logon)
        9 = 'NewCredentials' #(RunAs using alternate credentials)
        10 = 'RemoteInteractive' #(RDP\TS\RemoteAssistance)
        11 = 'CachedInteractive' #(Local w\cached credentials)
    }

    $logon_sessions = @(gwmi win32_logonsession -ComputerName $computername)
    $logon_users = @(gwmi win32_loggedonuser -ComputerName $computername)

    $session_user = @{}

    $logon_users | % {
        $_.antecedent -match $regexa > $nul
        $username = $matches[1] + "\" + $matches[2]
        $_.dependent -match $regexd > $nul
        $session = $matches[1]
        $session_user[$session] += $username
    }


    $logon_sessions | % {
        $starttime = [management.managementdatetimeconverter]::todatetime($_.starttime)

        New-Object psobject -Property @{
            Session = $_.logonid
            User = $session_user[$_.logonid]
            Type = $logontype[$_.logontype.tostring()]
            Auth = $_.authenticationpackage
            StartTime = $starttime
        }
    }
}
