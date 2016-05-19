# examples
# http://stackoverflow.com/questions/37038378/powershell-using-alphafs-to-capture-path-names-longer-than-259-characters/37039096#37039096
# https://community.spiceworks.com/topic/1529112-path-too-long-error?page=1#entry-5663147
# https://www.reddit.com/r/PowerShell/comments/4jzm8g/running_into_long_folderfile_name_issues_can_i/d3azd0v

$source = 'c:\temp'

# this will load the Get-Files function which uses robocopy
# feel free to check it out before running the script
try{ iex (iwr https://raw.githubusercontent.com/gangstanthony/PowerShell/master/Get-Files.ps1).content -ea 0 }catch{}

if (!(gcm get-files -ea 0)) { throw 'Command not found: Get-Files' }

$files = Get-Files -Path $source -FullName -File -Recurse

# get available drives in case dealing with long file names
# we can map a drive to a long file path so it is short enough for powershell to handle
$drives = [io.driveinfo]::getdrives() | % {$_.name[0]}
$alpha = [char[]](65..90)
$avail = (diff $drives $alpha).inputobject
$drive = $avail[0] + ':'

# prepare for write-progress
$index = 0
$total = $files.Count
$starttime = $lasttime = Get-Date

$result = foreach ($file in $files) {
    # this is just the write-progress section
    $index++
    $currtime = (Get-Date) - $starttime
    $avg = $currtime.TotalSeconds / $index
    $last = ((Get-Date) - $lasttime).TotalSeconds
    $left = $total - $index
    $WrPrgParam = @{
        Activity = (
            "Get-Files $(Get-Date -f s)",
            "Total: $($currtime -replace '\..*')",
            "Avg: $('{0:N2}' -f $avg)",
            "Last: $('{0:N2}' -f $last)",
            "ETA: $('{0:N2}' -f (($avg * $left) / 60))",
            "min ($([string](Get-Date).AddSeconds($avg*$left) -replace '^.* '))"
        ) -join ' '
        Status = "$index of $total ($left left) [$('{0:N2}' -f (($index/$total)*100))%]"
        CurrentOperation = "FILE: $file"
        PercentComplete = ($index/$total)*100
    }
    Write-Progress @WrPrgParam
    $lasttime = Get-Date

    # if filename is longer than 240 characters,
    # map a drive to the current path to shorten the filename
    $null = subst $drive /d
    $path = $newfile = $null
    if ($file.length -gt 240) {
        $path = Split-Path $file
        subst $drive $path
        $newfile = Join-Path $drive $(Split-Path $file -Leaf)
    }

    [pscustomobject]@{
        File = $file
        NewFile = $newfile
    }

    # un-map the drive (whether we mapped it or not, just to be sure)
    $null = subst $drive /d
}

$result
