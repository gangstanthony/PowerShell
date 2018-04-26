# check the first version of this file for more info


# don't accidentally run this
return

# requires get-files, alphafs.dll, and write-object

# this will skip files over 200mb

$srcRoot = "C:\temp\news"
$dstRoot = "C:\temp\new"

$logDir = "C:\temp\log"

if (!(Test-Path $srcRoot)) {
    throw "Source path '$srcRoot' does not exist!"
}

if (!(Test-Path $logDir)) {
    Write-Warning "Path '$logDir' does not exist! Creating..."
    try {
        md $logDir | Out-Null
    } catch {
        throw $_
    }
}

if (!(Test-Path $dstRoot)) {
    Write-Warning "Path '$dstRoot' does not exist! Creating..."
    try {
        md $dstRoot | Out-Null
    } catch {
        throw $_
    }
}

# get all the files
Write-Host "$(date -f yyyyMMdd-HHmmss) Getting all the source files..."
$srcFiles =  Get-Files $srcRoot -Recurse -Method AlphaFS # -AlphaFSdllPath c:\temp\alphafs.dll

$date = Get-Date -f yyyyMMdd-HHmmss

$usedDrives = [io.driveinfo]::getdrives() | % {$_.name[0]}
$alpha = [char[]](65..90)
$availDrives = (diff $usedDrives $alpha).inputobject
if (@($availDrives).Count -lt 2) { Throw 'subst needs at least two drive letters available - one for source and one for destination. just in case' }
$srcSubstDrive = $availDrives[0] + ':'
$dstSubstDrive = $availDrives[1] + ':'

# progress setup
$index = 0
$total = @($srcFiles).Count
$starttime = $lasttime = Get-Date

# uses properties: filesize, lastmodified, filename, fullpath
$results = foreach ($file in $srcFiles) {
    # progress
    $index++
    $currtime = (Get-Date) - $starttime
    $avg = $currtime.TotalSeconds / $index
    $last = ((Get-Date) - $lasttime).TotalSeconds
    $left = $total - $index
    $WrPrgParam = @{
        Activity = (
            "working $(Get-Date -f s)",
            "Total: $($currtime -replace '\..*')",
            "Avg: $('{0:N2}' -f $avg)",
            "Last: $('{0:N2}' -f $last)",
            "ETA: $('{0:N2}' -f ($avg * $left / 60))",
            "min ($([string](Get-Date).AddSeconds($avg*$left) -replace '^.* '))"
        ) -join ' '
        Status = "$index of $total ($left left) [$('{0:N2}' -f ($index / $total * 100))%]"
        CurrentOperation = "item: $($file.fullpath)"
        PercentComplete = $index / $total * 100
    }
    Write-Progress @WrPrgParam
    $lasttime = Get-Date

    # clear our temp drive letter
    subst $srcSubstDrive /d | Out-Null
    subst $dstSubstDrive /d | Out-Null


    ### SOURCE


    $srcpath = $srcfile = $srcdir = $srcend = $srcsplit = $srcextra = $srcstop = $null

    # if file name is too long
    if ($file.fullpath.length -gt 240)
    {
        # get parent path of file
        $srcpath = Split-Path $file.fullpath

        # path length has to be less than 258 to subst?
        $srcextra = $null
        if ($srcpath.length -gt 240)
        {
            $srcextra = New-Object System.Collections.ArrayList
            $srcsplit = $srcpath.Split('\')
            $srcstop = 2
            while ($srcpath.length -gt 240)
            {
                $srcend = $srcsplit.count - $srcstop
                $srcpath = [string]::Join('\', $srcsplit[0..$srcend])
                $srcstop++
            }
            $srcextra = [string]::Join('\', $srcsplit[($srcend + 1)..($srcend + $srcstop)])
        }

        # create temproary drive mapping to our current path
        subst $srcSubstDrive $srcpath

        # add back the subdirectory that we cut off if necessary
        if ($srcextra)
        {
            $srcfile = Join-Path (Join-Path $srcSubstDrive $srcextra) $file.filename
        }
        else
        {
            $srcfile = Join-Path $srcSubstDrive $file.filename
        }
    }
    else
    {
        $srcfile = $file.fullpath
    }

    $srcdir = Split-Path $srcfile


    ### DESTINATION


    $dstdir = $dstfile = $dstpath = $dstend = $dstsplit = $dstextra = $dststop = $null
    
    # build destination path for this file
    $dstdir = Join-Path $dstRoot $($(Split-Path $file.fullpath) -replace [regex]::Escape($srcRoot))
    $dstfile = Join-Path $dstdir $file.FileName

    # if file name is too long
    if ($dstfile.length -gt 240)
    {
        # get parent path of file
        $dstpath = Split-Path $dstfile

        # path length has to be less than 258 to subst?
        $dstextra = $null
        if ($dstpath.length -gt 240)
        {
            $dstextra = New-Object System.Collections.ArrayList
            $dstsplit = $dstpath.Split('\')
            $dststop = 2
            while ($dstpath.length -gt 240)
            {
                $dstend = $dstsplit.count - $dststop
                $dstpath = [string]::Join('\', $dstsplit[0..$dstend])
                $dststop++
            }
            $dstextra = [string]::Join('\', $dstsplit[($dstend + 1)..($dstend + $dststop)])
        }

        # if dstpath doesn't exist, we can't subst
        if (!(Test-Path $dstpath)) {
            Write-Warning "Path '$dstpath' does not exist! Creating..."
            try {
                md $dstpath | Out-Null
            } catch {
                throw $_
            }
        }

        # create temproary drive mapping to our current path
        subst $dstSubstDrive $dstpath

        # add back the subdirectory that we cut off if necessary
        if ($dstextra)
        {
            $dstfile = Join-Path (Join-Path $dstSubstDrive $dstextra) $file.filename
        }
        else
        {
            $dstfile = Join-Path $dstSubstDrive $file.filename
        }
    }
    else
    {
        # $dstfile = $dstfile
    }

    $dstdir = Split-Path $dstfile

    if (!(Test-Path $dstdir)) {
        Write-Warning "Path '$dstdir' does not exist! Creating..."
        try {
            md $dstdir | Out-Null
        } catch {
            throw $_
        }
    }


    ### DO WORK


    $err     = 'N/A'
    $exists  = 'N/A'
    $srcsize = $file.FileSize
    $srcdate = date $file.LastModified
    $dstsize = 'N/A'
    $dstinfo = 'N/A'
    $dstsize = 'N/A'
    $dstdate = 'N/A'
    $newer   = 'N/A'

    try
    {
        # see if it goes faster if i skip files that already exist...
        # ...src files change over time, so i might want to always overwrite in the future
        # trying bitstransfer for larger files
        if (!(Test-Path $dstfile)) {
            # finally, copy the file to its new location
            if (($srcsize/1mb) -gt (200mb/1mb)) {
                # if its that big, skip it - it ain't happenin...
                #Start-BitsTransfer $srcfile $dstfile
            } else {
                copy $srcfile $dstfile
            }

            $exists = $false
        } else {
            $dstinfo = gi $dstfile
            $dstsize = $dstinfo.length
            $dstdate = $dstinfo.LastWriteTime

            # skip if both files have the same date
            if ($srcdate -eq $dstdate) {
                $newer = 'Same'
            } else {
                ## don't skip if src is larger than dst # no longer applies # if ($srcsize -gt $dstsize) # ...might change this to if src -gt 0 and dst -eq 0
                # don't skip if source is newer
                if ($srcdate -gt $dstdate) {
                    if (($srcsize/1mb) -gt (200mb/1mb)) {
                        # if its that big, skip it - it ain't happenin...
                        #Start-BitsTransfer $srcfile $dstfile
                    } else {
                        # backup to my computer just in case
                        #$tmpfile = $dstfile -replace [regex]::Escape('[redacted(originalrootdirectory)]'), '[redacted(newrootdirectory)]'
                        #touch Split-Path $tmpfile
                        #copy $dstfile $tmpfile

                        #MessageBox -Title 'hold up!' -Message "$dstfile`n$tmpfile`n$srcfile"

                        copy $srcfile $dstfile
                    }
                    $newer = $true
                } else {
                    #####
                    # copy it anyway
                    #####
                    #copy $srcfile $dstfile
                    $newer = $false
                }
            }
            $exists = $true
        }
    }
    catch
    {
        write-host $_
        $err = $_
    }


    ### LOGGING

    
    $obj = [pscustomobject]@{
        FullPath = $file.fullpath
        SrcFile  = $srcfile
        SrcDrive = $srcSubstDrive
        SrcPath  = $srcpath
        SrcExtra = $srcextra
        SrcDir   = $srcdir
        DstFile  = $dstfile
        DstDrive = $dstSubstDrive
        DstPath  = $dstpath
        DstExtra = $dstextra
        DstDir   = $dstdir
        Error    = $err
        Exists   = $exists
        SrcSize  = $srcsize
        DstSize  = $dstsize
        Newer    = $newer
        SrcWrite = $srcdate
        DstWrite = $dstdate
    }

    $obj

    Write-Object $obj
    Write-Host ''

    #####
    $obj | Export-Csv $(Join-Path $logDir "$date-Copy.csv") -NoTypeInformation -Append
    #####

    # un-map the drive (whether we mapped it or not, just to be sure)
    subst $srcSubstDrive /d | Out-Null
    subst $dstSubstDrive /d | Out-Null
}

# errors and did not copy
$results | ? {($_.error -ne 'n/a') -or ($_.srcsize -gt 0 -and $_.dstsize -eq 0)} | Export-Csv $(Join-Path $logDir "$date-Error.csv") -NoTypeInformation
