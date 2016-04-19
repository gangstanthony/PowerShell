function Get-User {
    param (
        $comps = $env:COMPUTERNAME,
        [Parameter(ValidateSet=('process', 'dir', 'computersystem'))]
        $method = 'process'
    )
    
    foreach ($computer in $comps) {
        if ($method -eq 'dir') {
            Get-ChildItem \\$Computer\c$\users -Directory -Exclude '*$*' | % {dir $_.FullName ntuser.dat* -Force -ea  0} | sort LastWriteTime -Descending | select @{n='Computer';e={$Computer}}, @{n='User';e={Split-Path (Split-Path $_.FullName) -Leaf}}, LastWriteTime | ? user -notmatch '\.net'| group computer, user | % {$_.group | select -f 1}
        } elseif ($method -eq 'computersystem') {
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
        } else {
            $owners = @{}
            gwmi win32_process -ComputerName $computer -Filter 'name = "explorer.exe"' | % {$owners[$_.handle] = $_.getowner().user}
            get-process -ComputerName $computer explorer | % {$owners[$_.id.tostring()]}
        }
    }
}
