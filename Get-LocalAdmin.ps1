# adsi error fix
# http://stackoverflow.com/questions/31949541/print-local-group-members-in-powershell-5-0

function Get-LocalAdmin {
    Param (
        $comp = $env:COMPUTERNAME,
        [ValidateSet('adsi', 'wmi')]
        $method = 'adsi'
    )

    if ($method -eq 'wmi') { # takes crazy long because it lists every group (even many domain groups) then finds the Administrators group
        Get-WmiObject -Query 'SELECT GroupComponent, PartComponent FROM Win32_GroupUser' -ComputerName $comp | ? GroupComponent -Like '*"Administrators"' | % {
            [pscustomobject]@{
                Computer = $_.partcomponent -replace '^\\\\([^\\]+).*', '$1'
                User = $_.partcomponent –replace '.+Domain\=(.+)\,Name\=(.+)$', '$1\$2' -replace '"'
            }
        }
    } else { # adsi
        $group = [ADSI]"WinNT://$comp/Administrators"
        $group.Invoke('Members') | % {
            [pscustomobject]@{
                Computer = $comp
                #User = $_.GetType().InvokeMember('Name', 'GetProperty', $null, $_, $null) # gives error
                #User = $_.GetType.Invoke().InvokeMember('Name', 'GetProperty', $null, $_, $null) # works, but other way is shorter
                User = ([ADSI]$_).InvokeGet('Name')
            }
        }
    }
}
