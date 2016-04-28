$a1 = New-Object System.Collections.ArrayList
$a2 = New-Object System.Collections.ArrayList
$a3 = New-Object System.Collections.ArrayList
$a4 = New-Object System.Collections.ArrayList
$a5 = New-Object System.Collections.ArrayList
$a6 = New-Object System.Collections.ArrayList

1..100 | % {
    [void]$a1.add((Measure-Command {
        $b = ps
        $b.processname
    }).ticks)

    [void]$a2.add((Measure-Command {
        $b = ps
        foreach ($p in $b) {$p.ProcessName}
    }).ticks)
    
    [void]$a3.add((Measure-Command {
        $b = ps
        @($b).foreach{$_.processname}
    }).ticks)

    [void]$a4.add((Measure-Command {
        $b = ps
        $b | % {$_.processname}
    }).ticks)

    [void]$a5.add((Measure-Command {
        $b = ps
        $b | select -ExpandProperty processname
    }).ticks)
    
    [void]$a6.add((Measure-Command {
        $b = ps
        $b | % processname
    }).ticks)
}

''
'$b.processname'
$a1 | measure -Sum | % {$_.sum}
''
'foreach ($p in $b) {$p.ProcessName}'
$a2 | measure -Sum | % {$_.sum}
''
'@($b).foreach{$_.processname}'
$a3 | measure -Sum | % {$_.sum}
''
'$b | % {$_.processname}'
$a4 | measure -Sum | % {$_.sum}
''
'$b | select -ExpandProperty processname'
$a5 | measure -Sum | % {$_.sum}
''
'$b | % processname'
$a6 | measure -Sum | % {$_.sum}

<# results
$b.processname
4733275

foreach ($p in $b) {$p.ProcessName}
4771465

@($b).foreach{$_.processname}
6985770

$b | % {$_.processname}
9418136

$b | select -ExpandProperty processname
9657625

$b | % processname
10626175
#>
