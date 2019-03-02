
# https://www.reddit.com/r/PowerShell/comments/9424kw/how_to_create_a_progress_bar_for_anyall/e3hrt6a/?context=3

# need to move seconds left to its own parameter

<# https://www.reddit.com/r/PowerShell/comments/4goous/question_about_modules_info_bar/
$Host.PrivateData.ProgressBackgroundColor = $Host.UI.RawUI.BackgroundColor
$Host.PrivateData.ProgressBackgroundColor = 1..15 | Get-Random
$Host.PrivateData.ProgressForegroundColor = 1..15 | Get-Random
#>

$comps = 1..10
$index = 0
$total = @($comps).Count
$starttime = $lasttime = Get-Date
foreach ($comp in $comps) {
    $index++
    $currtime = (Get-Date) - $starttime
    $avg = $currtime.TotalSeconds / $index
    $last = ((Get-Date) - $lasttime).TotalSeconds
    $left = $total - $index
    $WrPrgParam = @{
        Activity = (
            "<name-of-operation> $(Get-Date -f s)",
            "Total: $($currtime -replace '\..*')",
            "Avg: $('{0:N2}' -f $avg)",
            "Last: $('{0:N2}' -f $last)",
            "ETA: $('{0:N2}' -f ($avg * $left / 60))",
            "min ($([string](Get-Date).AddSeconds($avg*$left) -replace '^.* '))"
        ) -join ' '
        Status = "$index of $total ($left left) [$('{0:N2}' -f ($index / $total * 100))%]"
        CurrentOperation = "ping: $comp"
        PercentComplete = $index / $total * 100
    }
    Write-Progress @WrPrgParam
    $lasttime = Get-Date

    if (0..1 | Get-Random) {
        # can change current operation
        $WrPrgParam.CurrentOperation = "scanning...: $comp"
        Write-Progress @WrPrgParam
        sleep 2
    }

    Write-Host $comp
    sleep -m 3500
}

return

# example 2 using stopwatch
# need to pack in all the same info as the other one
$comps = 1..10
$index = 0
$total = $comps.count
$sw = [System.Diagnostics.Stopwatch]::StartNew()
foreach ($comp in $comps) {
    $index++
    if ($sw.Elapsed.TotalMilliseconds -ge 2000) { # only update progress every 2 seconds
        $WrPrgParam = @{
            Activity = "<name-of-operation> $(date -f s)"
            Status = "$index of $total ($($total - $index) left) [$('{0:N2}' -f ($index / $total * 100))%]"
            CurrentOperation = "COMP: $comp"
            PercentComplete = $index / $total * 100
        }
        Write-Progress @WrPrgParam
        $sw.Reset()
        $sw.Start()
    }

    $WrPrgParam.CurrentOperation = "COMP: $comp"
    Write-Progress @WrPrgParam
    sleep 1
}
