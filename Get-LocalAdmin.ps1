# wmi
# https://gallery.technet.microsoft.com/scriptcenter/Get-remote-machine-members-bc5faa57

# adsi
# https://social.technet.microsoft.com/Forums/windowsserver/en-US/7bf4e490-0f3f-4a33-8350-2e78a869f1ed/list-remote-local-admins?forum=winserverpowershell
# https://www.reddit.com/r/PowerShell/comments/49oemk/how_to_display_only_those_lines_that_contain/
# https://www.petri.com/use-powershell-to-find-local-groups-and-members
# https://learn-powershell.net/2013/08/11/get-all-members-of-a-local-group-using-powershell/

# adsi fix
# http://stackoverflow.com/questions/31949541/print-local-group-members-in-powershell-5-0

# AccountManagement method
# http://stackoverflow.com/questions/30202452/list-all-local-administrator-accounts-excluding-domain-admin-and-local-admin
# http://blogs.msmvps.com/richardsiddaway/2009/04/21/user-module-local-account/
# https://github.com/lazywinadmin/PowerShell/blob/master/TOOL-Get-LocalGroupMember/Get-LocalGroupMember.ps1

# examples
# https://www.reddit.com/r/PowerShell/comments/4hmpj6/organising_outfile/d2rfrbs

# change local admin pw
# https://community.spiceworks.com/scripts/show/2978-change-local-user-password-for-remote-computers
# $user = [adsi]"WinNT://$computer/administrator,user"
# $user.SetPassword($decodedpassword)
# $user.SetInfo()

<##### VALIDATE ADMIN CREDENTIALS
# https://www.reddit.com/r/PowerShell/comments/4i1q5w/how_can_i_run_this_static_method_on_a_remote/
$comp = $env:computername
Add-Type -AssemblyName System.DirectoryServices.AccountManagement
$DS = New-Object System.DirectoryServices.AccountManagement.PrincipalContext([System.DirectoryServices.AccountManagement.ContextType]::Machine, $comp)
write-host $ds.ConnectedServer
$DS.ValidateCredentials('Admin', "'")
#>

function Get-LocalAdmin {
    param (
        $comp = $env:COMPUTERNAME,
        [ValidateSet('AccountManagement', 'ADSI', 'WMI')]
        $method = 'ADSI',
        [ValidateSet('Administrators', 'Remote Desktop Users')]
        $groupname = 'Administrators'
    )

    if ($method -eq 'AccountManagement') {
        Add-Type -AssemblyName System.DirectoryServices.AccountManagement
        $ctype = [System.DirectoryServices.AccountManagement.ContextType]::Machine
        $idtype = [System.DirectoryServices.AccountManagement.IdentityType]::SamAccountName
        $context = New-Object System.DirectoryServices.AccountManagement.PrincipalContext -ArgumentList $ctype, $comp
        try{ $obj = [System.DirectoryServices.AccountManagement.GroupPrincipal]::FindByIdentity($context, $idtype, $groupname) }catch{ continue }
        $obj.Members | % {
            [pscustomobject]@{
                Computer = $comp
                Domain = $_.Context.Name
                User = $_.samaccountname
            }
        }
    } elseif ($method -eq 'ADSI') { # adsi
        $group = [ADSI]"WinNT://$comp/$groupname"
        $group.Invoke('Members') | % {
            $path = ([adsi]$_).path
            [pscustomobject]@{
                Computer = $comp
                Domain = $(Split-Path (Split-Path $path) -Leaf)
                User = $(Split-Path $path -Leaf)
                #User = $_.GetType().InvokeMember('Name', 'GetProperty', $null, $_, $null) # gives error: Error while invoking GetType. Could not find member.
                #User = $_.GetType.Invoke().InvokeMember('Name', 'GetProperty', $null, $_, $null) # works, but other way is shorter
                #User = ([ADSI]$_).InvokeGet('Name') # works fine, I'm just no longer using this way
            }
        }
    } elseif ($method -eq 'WMI') { # takes crazy long because it lists every group (even many domain groups) then finds the Administrators group
        Get-WmiObject -Query 'SELECT GroupComponent, PartComponent FROM Win32_GroupUser' -ComputerName $comp | ? GroupComponent -Like "*`"$groupname`"" | % {
            $_.partcomponent -match '\\(?<computer>[^\\]+)\\.+\.domain="(?<domain>.+)",name="(?<name>.+)"' | Out-Null
            [pscustomobject]@{
                Computer = $matches.computer
                Domain = $matches.domain
                User = $matches.name
            }
        }
    }
}

<# adsi
$servers = Get-Content C:\Users\ExplainLikeImFly\Desktop\List.txt

$groups = 'Administrators', 'Remote Desktop Users'

$results = foreach ($server in $servers) {
    foreach ($group in $groups) {
        $obj = [ADSI]"WinNT://$server/$group"
        $obj.Invoke('Members') | % {
            $path = ([adsi]$_).path
            [pscustomobject]@{
                Computer = $server
                Group = $group
                Domain = $(Split-Path (Split-Path $path) -Leaf)
                User = $(Split-Path $path -Leaf)
            }
        }
    }
}

$results
#>

<# AccountManagement
$servers = Get-Content C:\Users\ExplainLikeImFly\Desktop\List.txt

$groups = 'Administrators', 'Remote Desktop Users'

Add-Type -AssemblyName System.DirectoryServices.AccountManagement
$ctype = [System.DirectoryServices.AccountManagement.ContextType]::Machine
$idtype = [System.DirectoryServices.AccountManagement.IdentityType]::SamAccountName

$results = foreach ($server in $servers) {
    $context = New-Object -TypeName System.DirectoryServices.AccountManagement.PrincipalContext -ArgumentList $ctype, $server
    foreach ($group in $groups) {
        try {
            $obj = [System.DirectoryServices.AccountManagement.GroupPrincipal]::FindByIdentity($context, $idtype, $group)
        }catch{
            continue
        }
        $obj.Members | % {
            [pscustomobject]@{
                Computer = $server
                Group = $group
                Domain = $_.Context.Name
                User = $_.samaccountname
            }
        }
    }
}

$results
#>

<# wmi
$servers = Get-Content C:\Users\ExplainLikeImFly\Desktop\List.txt

$groups = 'Administrators', 'Remote Desktop Users'

$results = foreach ($server in $servers) {
    foreach ($group in $groups) {
        Get-WmiObject -Query 'SELECT GroupComponent, PartComponent FROM Win32_GroupUser' -ComputerName $server | ? GroupComponent -Like "*`"$group`"" | % {
            $_.partcomponent -match '\\(?<computer>[^\\]+)\\.+\.domain="(?<domain>.+)",name="(?<name>.+)"' | Out-Null
            [pscustomobject]@{
                Computer = $matches.computer
                Group = $group
                Domain = $matches.domain
                User = $matches.name
            }
        }
    }
}

$results
#>
