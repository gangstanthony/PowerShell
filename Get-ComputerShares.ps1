# do NOT need admin rights

#''; net view | ? {$_ -match '^\\\\'} | % {$_.trim()} | % {if (ping1 $_.substring(2)) {net view $_}} | ? {$_ -and $_ -notmatch 'no entries|not found'} | % {if ($_ -match 'succ') {"`n"} else {$_}}

# also, check into gwmi win32_share

function Get-ComputerShares {
    param(
        [string[]]$comps
    )
    
    if (!$comps) {Throw 'No comps.'}
    
    $i = 1
    $total = $comps.Count
    $starttime = Get-Date
    $lasttime = Get-Date
    foreach ($comp in $comps) {
    
        $currtime = $((Get-Date) - $starttime) -replace '\..*'
        $time = $currtime.split(':')
        $avg = (([int]$time[0] * 60 * 60) + ([int]$time[1] * 60) + [int]$time[2]) / $i
        $last = ($((Get-Date) - $lasttime) -replace '\..*').split(':')
        $last = ([int]$last[0] * 60 * 60) + ([int]$last[1] * 60) + [int]$last[2]
        $left = $total - $i
    
        if ($total -gt 1) {
            Write-Progress `
                -Activity "Get-ComputerShares $(Get-Date -f yyyy-MM-dd_HH:mm:ss) Total: $currtime Avg: $('{0:N2}' -f $avg) Last: $('{0:N0}' -f $last) ETA: $('{0:N2}' -f (($avg * $left) / 60)) min ($(((get-date).AddSeconds($avg*$left) -f '') -replace '^[^ ]+ '))" `
                -Status "$i of $total ($left left) [$('{0:N0}' -f (($i/$total)*100))%]" `
                -CurrentOperation "COMP: $comp" `
                -PercentComplete (($i/$total)*100)
            $i++
        }
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

                $obj = New-Object psobject
                $obj | Add-Member -MemberType NoteProperty -Name IP -Value $ip
                $obj | Add-Member -MemberType NoteProperty -Name Computer -Value $(if ($name) {$name} else {$comp})
                $obj | Add-Member -MemberType NoteProperty -Name ShareName -Value $sharename
                $obj | Add-Member -MemberType NoteProperty -Name Type -Value $type
                $obj | Add-Member -MemberType NoteProperty -Name Comment -Value $comment
                $obj
            }
        }
    }
}
