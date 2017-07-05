# examples
# http://stackoverflow.com/questions/37038378/powershell-using-alphafs-to-capture-path-names-longer-than-259-characters/37039096#37039096
# https://community.spiceworks.com/topic/1529112-path-too-long-error?page=1#entry-5663147
# https://www.reddit.com/r/PowerShell/comments/4jzm8g/running_into_long_folderfile_name_issues_can_i/d3azd0v

$source = 'c:\temp\new'

# get-childitem will break on path too long, so use AlfaFS
# here is how i use it: https://github.com/gangstanthony/PowerShell/blob/master/Get-Files.ps1
# here is another example: https://gallery.technet.microsoft.com/Get-AlphaFSChildItems-ff95f60f
# here is where to download it: http://alphafs.alphaleonis.com/index.html
$files = Get-Files $source -Recurse -Method AlphaFS # -AlphaFSdllPath <# insert path to dll you downloaded #>

# get available drives in case dealing with long file names
# we can map a drive to a long file path so it is short enough for powershell to handle
$drives = [io.driveinfo]::getdrives() | % {$_.name[0]}
$alpha = [char[]](65..90)
$avail = (diff $drives $alpha).inputobject
$sourcedrive = $avail[0] + ':'
$destdrive = $avail[1] + ':' # not used in this example, but you can use it if you are copying files to a destination with a path that is too long

$result = foreach ($file in $files)
{
    # if filename is longer than 240 characters,
    # map a drive to the current path to shorten the filename
    
    # clear our temp drive letter
    subst $sourcedrive /d | Out-Null

    # prepare variables
    # !obviously, rename $path if you're using it elsewhere in your script!
    $path = $newfile = $null

    # if file name is too long
    if ($file.fullpath.length -gt 240)
    {
        # get parent path of file
        $path = Split-Path $file.fullpath

        # path length has to be less than 258 to subst?
        $extra = $null
        if ($path.length -gt 240)
        {
            $extra = New-Object System.Collections.ArrayList
            $split = $path.Split('\')
            $stop = 2
            while ($path.length -gt 240)
            {
                $end = $split.count - $stop
                $path = [string]::Join('\', $split[0..$end])
                $stop++
            }
            $extra = [string]::Join('\', $split[($end + 1)..($end + $stop)])
        }

        # create temproary drive mapping to our current path
        subst $sourcedrive $path

        # add back the subdirectory that we cut off if necessary
        if ($extra)
        {
            $newfile = Join-Path (Join-Path $sourcedrive $extra) $file.filename
        }
        else
        {
            $newfile = Join-Path $sourcedrive $file.filename
        }
    }
    else
    {
        $newfile = $file.fullpath
    }

    [pscustomobject]@{
        FullPath = $file.fullpath
        NewFile = $newfile
        SourceDrive = $sourcedrive
        Path = $path
        ExtraSubs = $extra
    }

    # un-map the drive (whether we mapped it or not, just to be sure)
    subst $sourcedrive /d | Out-Null
}

$result

# FullPath    : C:\temp\new\aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb\ccccccccccccccccccccccccccccccccccccccccccccccccccccccc
#               cccc\New Text Document.txt
# NewFile     : A:\ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc\New Text Document.txt
# SourceDrive : A:
# Path        : C:\temp\new\aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa\bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
# ExtraSubs   : ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
