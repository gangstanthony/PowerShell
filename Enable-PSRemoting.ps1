# Requires the PSRemoteRegistry module
# https://psremoteregistry.codeplex.com/

# https://blogs.technet.microsoft.com/heyscriptingguy/2006/06/21/how-can-i-use-windows-powershell-to-start-a-service-on-a-remote-computer/

# https://gallery.technet.microsoft.com/scriptcenter/Enable-PSRemoting-Remotely-6cedfcb0

function Enable-PSRemoting {
    param (
        [string[]]$Computers = (Read-Host 'Enter computer name'),
        [switch]$ShowSkipped
    )
    
    if (!$Computers) {Throw 'No computer name entered.'}
    
    $services = 'WinRM', 'RasAuto', 'RpcLocator', 'RemoteRegistry', 'RemoteAccess'
    $skipped = @()
    
    Import-Module PSRemoteRegistry
    foreach ($computer in $Computers) {
        $live = Test-Connection -Quiet $computer -Count 1 -ea 0
        if (!$live) {
            $skipped += $computer
        } else {
            foreach ($service in $services) {
                Set-Service $service -startuptype Automatic -passthru -computername $computer
                Set-Service $service -status Running -passthru -computername $computer
            }
            
            $computer |
                New-RegKey -Key 'SOFTWARE\Microsoft\PowerShell\1\ShellIds' -Name ScriptedDiagnostics -PassThru |
                Set-RegString -Value 'ExecutionPolicy' -Data Unrestricted -Force -PassThru |
                Set-RegString -Key 'SOFTWARE\Microsoft\PowerShell\1\ShellIds\Microsoft.PowerShell' -Value ExecutionPolicy -Data Unrestricted -Force
        }
    }
    
    if ($ShowSkipped -and $skipped) {
        Write-Host ''
        Write-Host 'Test-Connection failed for the following computers:'
        $skipped
    }
}
