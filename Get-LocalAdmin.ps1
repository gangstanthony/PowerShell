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

function Get-LocalAdmin {
    param (
        $comp = $env:COMPUTERNAME,
        [ValidateSet('AccountManagement', 'ADSI', 'WMI')]
        $method = 'ADSI'
    )

    if ($method -eq 'AccountManagement') {
        Add-Type -AssemblyName System.DirectoryServices.AccountManagement
        $ctype = [System.DirectoryServices.AccountManagement.ContextType]::Machine
        $idtype = [System.DirectoryServices.AccountManagement.IdentityType]::SamAccountName
        $context = New-Object System.DirectoryServices.AccountManagement.PrincipalContext -ArgumentList $ctype, $comp
        try{ $obj = [System.DirectoryServices.AccountManagement.GroupPrincipal]::FindByIdentity($context, $idtype, 'Administrators') }catch{ continue }
        $obj.Members | % {
            [pscustomobject]@{
                Computer = $comp
                Domain = $_.Context.Name
                User = $_.samaccountname
            }
        }
    } elseif ($method -eq 'ADSI') { # adsi
        $group = [ADSI]"WinNT://$comp/Administrators"
        $group.Invoke('Members') | % {
            $path = ([adsi]$_).path
            [pscustomobject]@{
                Computer = $comp
                Domain = $(Split-Path (Split-Path $path) -Leaf)
                User = $(Split-Path $path -Leaf)
                #User = $_.GetType().InvokeMember('Name', 'GetProperty', $null, $_, $null) # gives error: Error while invoking GetType. Could not find member.
                #User = $_.GetType.Invoke().InvokeMember('Name', 'GetProperty', $null, $_, $null) # works, but other way is shorter
                #User = ([ADSI]$_).InvokeGet('Name') # no longer using this way
            }
        }
    } elseif ($method -eq 'WMI') { # takes crazy long because it lists every group (even many domain groups) then finds the Administrators group
        Get-WmiObject -Query 'SELECT GroupComponent, PartComponent FROM Win32_GroupUser' -ComputerName $comp | ? GroupComponent -Like '*"Administrators"' | % {
            $_.partcomponent -match '\\(?<computer>[^\\]+)\\.+\.domain="(?<domain>.+)",name="(?<name>.+)"' | Out-Null
            [pscustomobject]@{
                Computer = $matches.computer
                Domain = $matches.domain
                User = $matches.name
            }
        }
    }
}
