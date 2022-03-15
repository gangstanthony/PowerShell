# to get primary or secondary
# $addresses = Get-ProxyAddresses | select *, @{n='IsSecondary';e={if ($_.addr.startswith('smtp')) {$true} else {$false}}}

# to get those that do not have a secondary
# $addresses | group name | ? count -eq 1 | % group

function Get-ProxyAddresses {
    Connect-AzureAD | Out-Null
    
    #$accts = $(Get-MsolUser -All; Get-MsolGroup -All)
    $accts = $(Get-AzureADUser -All:$true; Get-AzureADGroup -All:$true)

    $(foreach ($acct in $accts) {
        if ($acct.lastdirsynctime) {
            $sync = 'AD'
        } else {
            $sync = 'o365'
        }

        if ($acct.signinname) {
            $type = 'User'

            $signinname = [pscustomobject]@{
                Name = $acct.DisplayName
                Sync = $sync
                Type = $type
                Addr = $acct.signinname.trim()
            }
        } else {
            $type = 'Group'
        }

        if ($acct.userprincipalname) {
            $upn = [pscustomobject]@{
                Name = $acct.DisplayName
                Sync = $sync
                Type = $type
                Addr = $acct.userprincipalname.trim()
            }
        }

        $proxy = @(foreach ($addr in $acct.proxyaddresses) {
            [pscustomobject]@{
                Name = $acct.displayname
                Sync = $sync
                Type = $type
                Addr = $addr.trim()
            }
        })

        if (('smtp:' + $signinname.Addr) -notin $proxy.addr) {
            $proxy += $signinname
        }

        if (('smtp:' + $upn.addr) -notin $proxy.addr) {
            $proxy += $upn
        }

        foreach ($altEA in $acct.AlternateEmailAddresses) {
            $alt = [pscustomobject]@{
                Name = $acct.DisplayName
                Sync = $sync
                Type = $type
                Addr = $altEA.trim()
            }

            if (('smtp:' + $alt.addr) -notin $proxy.addr) {
                $proxy += $alt
            }
        }

        $proxy

    }) | select * -Unique
}
