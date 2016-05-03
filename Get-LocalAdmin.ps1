# adsi error fix
# http://stackoverflow.com/questions/31949541/print-local-group-members-in-powershell-5-0

# https://www.reddit.com/r/PowerShell/comments/4hmpj6/organising_outfile/

function Get-LocalAdmin {
    param (
        $comp = $env:COMPUTERNAME,
        [ValidateSet('AccountManagement', 'ADSI', 'WMI')]
        $method = 'AccountManagement'
    )

    if ($method -eq 'AccountManagement') {
        Add-Type -AssemblyName System.DirectoryServices.AccountManagement
        $ctype = [System.DirectoryServices.AccountManagement.ContextType]::Machine
        $idtype = [System.DirectoryServices.AccountManagement.IdentityType]::SamAccountName
        $context = New-Object -TypeName System.DirectoryServices.AccountManagement.PrincipalContext -ArgumentList $ctype, $comp
        try{ $obj = [System.DirectoryServices.AccountManagement.GroupPrincipal]::FindByIdentity($context, $idtype, 'Administrators') }catch{}
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
    } else { # takes crazy long because it lists every group (even many domain groups) then finds the Administrators group
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
