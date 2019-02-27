# https://www.reddit.com/r/PowerShell/comments/4elioe/import_csv_and_copy_files_leaving_directories/

# another example by me
# https://www.reddit.com/r/PowerShell/comments/4ipnnu/looking_for_some_assistance/

# another example for renaming
# http://stackoverflow.com/a/37351062/4589490

# another example for renaming with regex
# https://www.reddit.com/r/PowerShell/comments/4kacos/how_to_rename_a_certain_part_of_a_filefolders_name/d3dgsg4

# another example with recommendation to Copy-File function (byte progress)
# http://stackoverflow.com/questions/37823283/powershell-copying-multiple-files/37825934#37825934

<# https://www.reddit.com/r/PowerShell/comments/7d6dma/copyitem_not_copying_extensions_when_used_with/
# you can use this instead of md
$DateToCompare = (Get-Date).AddDays(-1)
$Source = "C:\Copy From\"
$Destination "C:\Copy To"
$Files = GCI $Source -Recurse -include *.xls,*.xlsx,*.txt | where{$_.LastWriteTime -gt $DateToCompare}
Foreach($File in $Files){
    $FinalFileName = $Destination + $File.FullName.Substring($Source.Length)
    IF($File.PSISContainer -eq $True){New-Item -Type Directory -Path $FinalFileName -Force}
    ELSE{New-Item -Type File -Path $FinalFileName -Force}
    Copy-Item $File.FullName $FinalFileName
}
#>

# THIS IS THE FILE COPY YOU ARE LOOKING FOR
# copy files and keep folder structure - with progress (optional)

# define source and destination folders
$source = 'C:\temp\music'
$dest = 'C:\temp\new'

# exclude these folders
$exclude = '\\my (?:music|pictures)\\'

# get all files in source (not empty directories)
$files = (Get-ChildItem $source -Recurse -File).where{$_.FullName -notmatch $exclude}

$index = 0
$total = $files.Count
$starttime = $lasttime = Get-Date
$results = $files | % {
    $index++
    $currtime = (Get-Date) - $starttime
    $avg = $currtime.TotalSeconds / $index
    $last = ((Get-Date) - $lasttime).TotalSeconds
    $left = $total - $index
    $WrPrgParam = @{
        Activity = (
            "Copying files $(Get-Date -f s)",
            "Total: $($currtime -replace '\..*')",
            "Avg: $('{0:N2}' -f $avg)",
            "Last: $('{0:N2}' -f $last)",
            "ETA: $('{0:N2}' -f ($avg * $left / 60))",
            "min ($([string](Get-Date).AddSeconds($avg*$left) -replace '^.* '))"
        ) -join ' '
        Status = "$index of $total ($left left) [$('{0:N2}' -f ($index / $total * 100))%]"
        CurrentOperation = "File: $_"
        PercentComplete = ($index/$total)*100
    }
    Write-Progress @WrPrgParam
    $lasttime = Get-Date

    # build destination path for this file
    $destdir = Join-Path $dest $($(Split-Path $_.fullname) -replace [regex]::Escape($source))

    # if it doesn't exist, create it
    if (!(Test-Path $destdir)) {
        $null = md $destdir
    }

    # if the file.txt already exists, rename it to file-1.txt and so on
    $num = 1
    $base = $_.basename
    $ext = $_.extension
    $newname = Join-Path $destdir "$base$ext"
    while (Test-Path $newname) {
        $newname = Join-Path $destdir "$base-$num$ext"
        $num++
    }

    # log the source and destination files to the $results variable
    New-Object psobject -Property @{
        SourceFile = $_.fullname
        DestFile = $newname
    }

    # finally, copy the file to its new location
    copy $_.fullname $newname
}
