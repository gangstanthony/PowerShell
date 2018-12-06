## INFO
# find last logged on user of remote computer

# https://www.reddit.com/r/PowerShell/comments/448gdx/noob_need_help_getting_a_list_with_all_xp/

# get-ciminstance is the successor, but it doesn't work for me...
# http://powershell.com/cs/forums/t/23349.aspx

# (gp "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI").lastloggedonuser
# reg query \\$computer\HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI /v LastLoggedOnUser
# [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$computer).OpenSubKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI').getvalue('LastLoggedOnUser')

# (gwmi win32_loggedonuser).antecedent # this is remote connections, not necessarily logons. includes computers and users connected to print servers

# get remote computer idle time!
# http://stackoverflow.com/questions/38664300/log-off-multiple-idle-users

<#
$owners = @{}
gwmi win32_process -computer $env:computername -Filter 'name = "explorer.exe"' | % {$owners[$_.handle] = $_.getowner().user}
get-process -computer $env:computername explorer | % {$owners[$_.id.tostring()]}
#>

<# all give about the same information. the first two might give more
# https://www.reddit.com/r/PowerShell/comments/4dwqlc/crypto_tripwire_-_help_with_script/d1v0jg5?context=3
(quser) -replace '\s{2,}', ',' | ConvertFrom-Csv
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
        [string]$comp = $env:COMPUTERNAME,
        [ValidateSet('computersystem', 'process', 'dir')]
        $method = 'computersystem'
    )
    
    switch ($method) {
        'dir' {
            Get-ChildItem \\$comp\c$\users -Directory -Exclude '*$*' | % {Get-ChildItem $_.FullName ntuser.dat* -Force -ea 0} | sort LastWriteTime -Descending | select @{n='Computer';e={$comp}}, @{n='User';e={Split-Path (Split-Path $_.FullName) -Leaf}}, LastWriteTime | ? user -notmatch '\.net'| group computer, user | % {$_.group | select -f 1}
        }

        'computersystem' {
            try {
                (Get-WmiObject win32_computerSystem -ComputerName $comp).username
            } catch {
                try {
                    [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $comp).OpenSubKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Authentication\LogonUI').getvalue('LastLoggedOnUser')
                    Get-WmiObject Win32_NetworkLoginProfile -ComputerName $comp
                } catch {
                    'Error'
                }
            }
        }

        'process' {
            $owners = @{}
            Get-WmiObject win32_process -Filter 'name = "explorer.exe"' -ComputerName $comp | % {$owners[$_.handle] = $_.getowner().user}
            Get-Process explorer -ComputerName $comp | % {$owners[$_.id.tostring()]}
        }
    }
}
