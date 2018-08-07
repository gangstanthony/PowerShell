$a1 = New-Object System.Collections.ArrayList
$a2 = New-Object System.Collections.ArrayList
$a3 = New-Object System.Collections.ArrayList
$a4 = New-Object System.Collections.ArrayList
$a5 = New-Object System.Collections.ArrayList
$a6 = New-Object System.Collections.ArrayList
$a7 = New-Object System.Collections.ArrayList

1..100 | % {
    [void]$a1.add((Measure-Command {
        $b = ps
        $b.processname
        rv b
    }).ticks)

    [void]$a2.add((Measure-Command {
        $b = ps
        foreach ($p in $b) {$p.ProcessName}
        rv b
        rv p
    }).ticks)
    
    [void]$a3.add((Measure-Command {
        $b = ps
        @($b).foreach{$_.processname}
        rv b
    }).ticks)

    [void]$a4.add((Measure-Command {
        $b = ps
        $b | % {$_.processname}
        rv b
    }).ticks)

    [void]$a5.add((Measure-Command {
        $b = ps
        $b | select -ExpandProperty processname
        rv b
    }).ticks)
    
    [void]$a6.add((Measure-Command {
        $b = ps
        $b | % processname
        rv b
    }).ticks)

    [void]$a7.add((Measure-Command {
        $b = ps
        ($b).{processname}
        rv b
    }).ticks)
}

"Method, Time
`$b.processname,                          $($a1 | measure -Average | % {$_.average.tostring('000000.000')})
foreach (`$p in `$b) {`$p.ProcessName},   $($a2 | measure -Average | % {$_.average.tostring('000000.000')})
@(`$b).foreach{`$_.processname},          $($a3 | measure -Average | % {$_.average.tostring('000000.000')})
`$b | % {`$_.processname},                $($a4 | measure -Average | % {$_.average.tostring('000000.000')})
`$b | select -ExpandProperty processname, $($a5 | measure -Average | % {$_.average.tostring('000000.000')})
`$b | % processname,                      $($a6 | measure -Average | % {$_.average.tostring('000000.000')})
(`$b).{processname},                      $($a7 | measure -Average | % {$_.average.tostring('000000.000')})
" | ConvertFrom-Csv | sort time | ft -AutoSize

# Method                                  Time      
# ------                                  ----      
# ($b).{processname}                      045282.490
# $b.processname                          046808.160
# foreach ($p in $b) {$p.ProcessName}     047262.740
# @($b).foreach{$_.processname}           064141.560
# $b | % {$_.processname}                 084606.420
# $b | select -ExpandProperty processname 094024.470
# $b | % processname                      101501.620
