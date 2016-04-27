# http://stackoverflow.com/questions/15797198/powershell-get-a-list-of-network-machines
# switch -regex (NET.EXE VIEW) { "^\\\\(?<Name>\S+)\s+" {$matches.Name}}
# $shares = $(switch -regex (net view) { '^\\\\(?<Name>\S+)' {$matches.Name}}) | % {net view $_}

# do NOT need admin rights
# not reliable. tried once on ca-nor1-sb10, nothing, tried again, got results... :/

# check all computers that show up on the network
#''; net view | ? {$_ -match '^\\\\'} | % {$_.trim()} | % {if (ping1 $_.substring(2)) {net view $_}} | ? {$_ -and $_ -notmatch 'no entries|not found'} | % {if ($_ -match 'succ') {"`n"} else {$_}}

# need admin rights for this option
#gwmi win32_share -comp 'lt-40132' | select pscomputername, type, name, caption, description | ft -a

function Get-ComputerShares {
    param (
        [string]$comp = $env:COMPUTERNAME
    )
    
    if (!$comp) { throw 'No comps.' }

    $ping = New-Object System.Net.NetworkInformation.Ping
    try {
        $result = $ping.Send($comp)
    } catch {
        $result = $null
    }

    $sharename = $type = $comment = $ip = '-'
    if ($result.Status -eq 'Success') {
        # get the ip address
        $ip = $result.Address.ToString()

        # THE MAIN COMMAND
        $netview = iex "cmd /c net view $comp 2>&1" | ? {$_}

        # if there are less than 5 lines, no shares found
        if ($netview.count -lt 5) {
            [pscustomobject]@{
                Computer = $comp
                IP = $ip
                ShareName = $sharename
                Type = $type
                Comment = $comment
            }
            return
        }

        $netview = $netview | ? {$_  -match '\s{2}'} | select -Skip 1

        foreach ($line in $netview) {
            $line = $line -split '\s{2,}'

            $sharename = $line[0]
            $type = $line[1]
            $comment = $line[2]

            [pscustomobject]@{
                Computer = $comp
                IP = $ip
                ShareName = $sharename
                Type = $type
                Comment = $comment
            }
        }
    } else {
        [pscustomobject]@{
            Computer = $comp
            IP = $ip
            ShareName = $sharename
            Type = $type
            Comment = $comment
        }
    }
}
