## INFO
# find firewall status of remote computer

function Get-Firewall {
    param (
        [object]$comps = $env:COMPUTERNAME
    )
    
    foreach ($computer in $comps) {
        try {
            # $status = (gp 'HKLM:\SYSTEM\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\DomainProfile').EnableFirewall
            # reg query \\$computer\HKLM\SYSTEM\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\DomainProfile /v EnableFirewall
            $status = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $computer).OpenSubKey('SYSTEM\ControlSet001\Services\SharedAccess\Parameters\FirewallPolicy\DomainProfile').GetValue('EnableFirewall')
            
            [bool]$status
        } catch [System.Exception] {
            return 'Error'
        }
    }
}
