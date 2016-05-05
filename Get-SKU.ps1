## INFO
# get SystemSKU of remote computer
# (gwmi -n root\wmi ms_systeminformation).systemsku

function Get-SKU {
    param (
        [object]$comps = $env:COMPUTERNAME
    )
    
    foreach ($computer in $comps) {
        try {
            # (gp 'HKLM:\HARDWARE\DESCRIPTION\System\BIOS').SystemSku
            # reg query \\$computer\HKLM\HARDWARE\DESCRIPTION\System\BIOS /v SystemSku
            [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$computer).OpenSubKey('HARDWARE\DESCRIPTION\System\BIOS').GetValue('SystemSku')
        } catch {
            try {
                # WMIC /NODE: "`"$computer"`" /NAMESPACE:\\root\wmi path MS_SystemInformation
                (Get-WMIObject -Namespace root\wmi -Class MS_SystemInformation -ComputerName $computer).SystemSKU
            } catch {
                return 'Error'
            }
        }
    }
}
