# http://stackoverflow.com/questions/2434133/progress-during-large-file-copy-copy-item-write-progress
# https://stackoverflow.com/questions/13883404/custom-robocopy-progress-bar-in-powershell

# TODO
# allow input of an array of fullpaths. right now it can only do a whole folder (recurse) or single file.

# NOTE!
# * RECURSE is always forced
# * When copying a single file, you cannot specify a destination file name, only the destination path.
# * When copying a folder, the source folder is created inside the destinination folder.
# * Looks like this is not a typical file copy... data is copied, but not timestamp. (is acl copied?)
#     after running this, i had to do robocopy (src) (dst) /copy:t to copy the timestamp.

function Copy-File {
    param (
        [string]$Path,
        [string]$Destination,
        [switch]$Overwrite
    )

    # do this regardless of whether the source is a file or a folder
    # might be able to just use Get-ChildItem
    $files = Get-ChildItem $Path -Recurse -File

    $source = (Resolve-Path (Split-Path $Path)).ProviderPath

    $Destination = (Resolve-Path $Destination).ProviderPath

    [long]$allbytes = ($files | measure -Sum length).Sum
    [long]$total1 = 0 # bytes done

    $index = 0
    $filescount = $files.Count
    $sw1 = [System.Diagnostics.Stopwatch]::StartNew()
    foreach ($file in $files) {
        $filefullname = $file.fullname
        
        $index++

        # build destination path for this file
        $destdir = Join-Path $Destination $($(Split-Path $filefullname).Replace($source, ''))

        # if it doesn't exist, create it
        if (!(Test-Path $destdir)) {
            $null = md $destdir
        }

        # if the file.txt already exists, rename it to file-1.txt and so on
        $num = 1
        $base = $file.name -replace "$($file.extension)$"
        $ext = $file.extension
        $destfile = Join-Path $destdir "$base$ext"

        if (!$overwrite) {
            while (Test-Path $destfile) {
                $destfile = Join-Path $destdir "$base-$num$ext"
                $num++
            }
        }

        $ffile = [io.file]::OpenRead($filefullname)
        $DestinationFile = [io.file]::Create($destfile)

        $sw2 = [System.Diagnostics.Stopwatch]::StartNew()
        [byte[]]$buff = New-Object byte[] (4096 * 1024) # 4MB?
        [long]$total2 = [long]$count = 0

        do {
            # copy src file to dst file, so many bytes at a time
            $count = $ffile.Read($buff, 0, $buff.Length)
            $DestinationFile.Write($buff, 0, $count)

            # this is just write-progress
            # uses stopwatch instead of get-date to determine how long is left
            $total2 += $count
            $total1 += $count
            if ($ffile.Length -gt 1) {
                $pctcomp2 = $total2 / $ffile.Length * 100
            } else {
                $pctcomp2 = 100
            }
            [int]$secselapsed2 = [int]($sw2.elapsedmilliseconds.ToString()) / 1000
            if ($secselapsed2 -ne 0) {
                [single]$xferrate = $total2 / $secselapsed2 / 1mb
            } else {
                [single]$xferrate = 0.0
            }
            if ($total % 1mb -eq 0) {
                if ($pctcomp2 -gt 0) {
                    [int]$secsleft2 = $secselapsed2 / $pctcomp2 * 100 - $secselapsed2
                } else {
                    [int]$secsleft2 = 0
                }
                $pctcomp1 = $total1 / $allbytes * 100
                [int]$secselapsed1 = [int]($sw1.elapsedmilliseconds.ToString()) / 1000
                if ($pctcomp1 -gt 0) {
                    [int]$secsleft1 = $secselapsed1 / $pctcomp1 * 100 - $secselapsed1
                } else {
                    [int]$secsleft1 = 0
                }
                $WrPrgParam1 = @{
                    Id = 1
                    Activity = "$('{0:N2}' -f $pctcomp1)% $index of $filescount ($($filescount - $index) left)"
                    Status = $filefullname
                    PercentComplete = $pctcomp1
                    SecondsRemaining = $secsleft1
                }
                Write-Progress @WrPrgParam1
                $WPparams2 = @{
                    Id = 2
                    Activity = (('{0:N2}' -f $pctcomp2) + '% Copying file @ ' + '{0:n2}' -f $xferrate + ' MB/s')
                    Status = $destfile
                    PercentComplete = $pctcomp2
                    SecondsRemaining = $secsleft2
                }
                Write-Progress @WPparams2
            }
        } while ($count -gt 0)

        $sw2.Stop()
        $sw2.Reset()
        $ffile.Close()
        $DestinationFile.Close()
    }
    $sw1.Stop()
    $sw1.Reset()
}

# Copy-File 'C:\temp\test1' 'C:\temp\test2'
