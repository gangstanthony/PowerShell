function Get-User {
    param (
        $comps = $env:COMPUTERNAME,
        [switch]$wmi = $false
    )
    
    foreach ($computer in $comps) {
        if (!$wmi) {
            Get-ChildItem \\$Computer\c$\users -Directory -Exclude '*$*' | % {dir $_.FullName ntuser.dat* -Force -ea  0} | sort LastWriteTime -Descending | select @{n='Computer';e={$Computer}}, @{n='User';e={Split-Path (Split-Path $_.FullName) -Leaf}}, LastWriteTime | ? user -notmatch '\.net'| group computer, user | % {$_.group | select -f 1}
        } else {
            try {
                (gwmi win32_computerSystem -ComputerName $computer).username
            } catch [System.Exception] {
                try {
                    [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$computer).OpenSubKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI').getvalue('LastLoggedOnUser')
                    gwmi Win32_NetworkLoginProfile -ComputerName $computer
                } catch [System.Exception] {
                    return 'Error'
                }
            }
        }
    }
}
