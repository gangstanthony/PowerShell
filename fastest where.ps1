<# http://powershell.org/wp/forums/topic/send-email-when-numeber-is-greater-than/
Get-Content '.\logfile' | ForEach-Object {
    [void]($_ -match 'TOTAL_TIME=.*')
    $time = ($Matches[0] -split '=')[-1]
    If ([int]$time -gt 9999){Send-MailMessage}
}
#>

$a1 = New-Object System.Collections.ArrayList
$a2 = New-Object System.Collections.ArrayList
$a3 = New-Object System.Collections.ArrayList

1..10 | % {
    [void]$a1.add((Measure-Command {
        @(dir C:\temp -Recurse).where{$_.basename}
    }).ticks)
    
    [void]$a2.add((Measure-Command {
        dir C:\temp -Recurse | ? basename
    }).ticks)

    [void]$a3.add((Measure-Command {
        dir C:\temp -Recurse | ? {$_.basename}
    }).ticks)
}

$a1 | measure -Sum | % {$_.sum}
$a2 | measure -Sum | % {$_.sum}
$a3 | measure -Sum | % {$_.sum}
