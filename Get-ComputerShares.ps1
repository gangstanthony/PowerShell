# do NOT need admin rights

#''; net view | ? {$_ -match '^\\\\'} | % {$_.trim()} | % {if (ping1 $_.substring(2)) {net view $_}} | ? {$_ -and $_ -notmatch 'no entries|not found'} | % {if ($_ -match 'succ') {"`n"} else {$_}}

# also, check into gwmi win32_share

function Get-ComputerShares {
    param(
        [string[]]$comps
    )
    
    BEGIN {
        filter ping1 {
            param (
                [Parameter(ValueFromPipeline=$true)]
                $comps = $env:COMPUTERNAME,
                $n = 1,
                [switch]$showhost
            )

            begin {
                $ping = new-object System.Net.NetworkInformation.Ping
            }

            process {
                if (!$comps) {Throw 'No host provided'}
                foreach ($comp in $comps) {
                    for ($i = 0; $i -lt $n; $i++) {
                        try{ $result = $ping.send($comp, 500) }catch{}
                        switch ($result.status) {
                            'Success' { $success = $true }
                            default { $success = $false }
                        }
                    }

                    if ($showhost) {
                        switch ($success) {
                            $true { "True  $(try{ $result.address.tostring() }catch{ $comp })" }
                            $false { "False $comp" }
                        }
                    } else {
                        switch ($success) {
                            $true { $true }
                            $false { $false }
                        }
                    }
                }
            }
        }
    }

    PROCESS {
        if (!$comps) {Throw 'No comps.'}

        $total = $comps.Count
        $starttime = $lasttime = Get-Date
        foreach ($comp in $comps) {
    
            $index++
            $currtime = (Get-Date) - $starttime
            $avg = $currtime.TotalSeconds / $index
            $last = ((Get-Date) - $lasttime).TotalSeconds
            $left = $total - $index
            Write-Progress `
                -Activity ((
                    "Get-ComputerShares $(Get-Date -f yyyy-MM-dd_HH:mm:ss)",
                    "Total: $($currtime -replace '\..*')",
                    "Avg: $('{0:N2}' -f $avg)",
                    "Last: $('{0:N2}' -f $last)",
                    "ETA: $('{0:N2}' -f (($avg * $left) / 60))",
                    "min ($([string](Get-Date).AddSeconds($avg*$left) -replace '^.* '))"
                ) -join ' ') `
                -Status "$index of $total ($left left) [$('{0:N2}' -f (($index/$total)*100))%]" `
                -CurrentOperation "COMP: $comp" `
                -PercentComplete (($index/$total)*100)
            $lasttime = Get-Date

            if (ping1 $comp) {
            
                # get ip and site name
                $ip = ping1 $comp -showhost
                if ($ip -match '\[') {
                    $ip = $ip -replace '^[^\[]+\[|\]$'
                } else {
                    $ip = $ip -replace '^[^0-9]+'
                }

                # THE MAIN COMMAND
                $netview = cmd /c "net view $comp 2>&1" | ? {$_}

                if ($netview.count -lt 5) { continue }

                $netview = $netview | ? {$_  -match '  '}
                $netview = $netview[1..($netview.count-1)]

                foreach ($line in $netview) {
                    $line = $line -split '  +'
                    $sharename = $line[0]
                    $type = $line[1]
                    $comment = $line[2]

                    [pscustomobject]@{
                        IP = $ip
                        Computer = if ($name) {$name} else {$comp}
                        ShareName = $sharename
                        Type = $type
                        Comment = $comment
                    }
                }
            }
        }
    }
}
