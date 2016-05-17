## INFO
# find last logged on user of remote computer

# https://www.reddit.com/r/PowerShell/comments/448gdx/noob_need_help_getting_a_list_with_all_xp/

# get-ciminstance is the successor, but it doesn't work for me...
# http://powershell.com/cs/forums/t/23349.aspx

# (gp "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI").lastloggedonuser
# reg query \\$computer\HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI /v LastLoggedOnUser
# [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$computer).OpenSubKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI').getvalue('LastLoggedOnUser')

# (gwmi win32_loggedonuser).antecedent # this is remote connections, not necessarily logons. includes computers and users connected to print servers

<# all these give about the same information. the first two might give more
$server = 'localhost'

# IDENTICAL
query session /server:$server
qwinsta /server:$server

# IDENTICAL
query user /server:$server
quser /server:$server

qprocess explorer.exe /server:$server
#>

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
