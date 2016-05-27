# https://thesurlyadmin.com/2014/08/04/getting-directory-information-fast/
# https://gallery.technet.microsoft.com/Get-AlphaFSChildItems-ff95f60f

# check here for single file copy
# http://serverfault.com/questions/52983/robocopy-transfer-file-and-not-folder
# https://social.technet.microsoft.com/Forums/windowsserver/en-US/580695ae-0128-4df4-af2b-b11a6c985b22/move-files?forum=winserverpowershell
#RoboCopy c:\source c:\destination myfile.txt /move
#RoboCopy c:\source c:\destination *.txt /move

# fix: write-verbose
# 
# List files (and folders) -recursively
# Input: Array of folder paths
# Output: PSObject; FullName, Date, Size; Sorted by FullName
# 
# FullName        Size        Date
# --------        ----        ----
# C:\bootmgr      398156      2012/07/26 03:44:30
# 
# Notes:
# This will not show dirs unless recursive
# Directory must not end in '\'
# also, maybe add something to show size in appropriate b/kb/mb/gb
# could use [pscustomobject][ordered]@{}
# 
# /L = List only – don’t copy, timestamp or delete any files.
# /S = copy Subdirectories, but not empty ones.
# /NJH = No Job Header.
# /BYTES = Print sizes as bytes.
# /FP = include Full Pathname of files in the output.
# /NC = No Class – don’t log file classes.
# /NDL = No Directory List – don’t log directory names.
# /TS = include source file Time Stamps in the output.
# /XJ = eXclude Junction points. (normally included by default)
# /R:0 = number of Retries on failed copies: default 1 million.
# /W:0 = Wait time between retries: default is 30 seconds.
# 
# robocopy .\ null /l /e /njh /ndl /bytes /fp /nc /ts /xj /r:0 /w:0

function Get-Files {
    param (
        [string]$Path = $PWD,
        [string[]]$Include,
        [switch]$Recurse,
        [switch]$FullName,
        [switch]$Directory,
        [switch]$File,
        [ValidateSet('Robocopy', 'Dir', 'EnumerateFiles', 'AlphaFS')]
        [string]$Method = 'Robocopy',
        [string]$AlphaFSPath = (Join-Path $env:windir 'AlphaFS.dll')
    )
    
    begin {
        if ($Directory -and $File) {
            throw 'Cannot use both -Directory and -File at the same time.'
        }

        $Path = Resolve-Path $Path

        function CreateFolderObject {
            $name = New-Object System.Text.StringBuilder
            $null = $name.Append((Split-Path $matches.FullName -Leaf))
            if (-not $name.ToString().EndsWith('\')) {
                $null = $name.Append('\')
            }
            [pscustomobject]@{
                FullName = $matches.FullName
                DirectoryName = Split-Path $matches.FullName
                Name = $name.ToString()
                Size = $null
                Extension = '[Directory]'
                DateModified = $null
            }
        }
    }

    process {
        if ($Method -eq 'Robocopy') {
            $params = '/L', '/NJH', '/BYTES', '/FP', '/NC', '/TS', '/XJ', '/R:0', '/W:0'
            if ($Recurse) {$params += '/E'}
            if ($Include) {$params += $Include}
            foreach ($dir in $Path) {
                foreach ($line in $(robocopy $dir NULL $params)) {
                    # folder
                    if (!$File -and $line -match '\s+\d+\s+(?<FullName>.*\\)$') {
                        if ($Include) {
                            if ($matches.FullName -like "*$($include.replace('*',''))*") {
                                if ($FullName) {
                                    $matches.FullName
                                } else {
                                    CreateFolderObject
                                }
                            }
                        } else {
                            if ($FullName) {
                                $matches.FullName
                            } else {
                                CreateFolderObject
                            }
                        }

                    # file
                    } elseif (!$Directory -and $line -match '(?<Size>\d+)\s(?<Date>\S+\s\S+)\s+(?<FullName>.*[^\\])$') {
                        if ($FullName) {
                            $matches.FullName
                        } else {
                            $name = Split-Path $matches.FullName -Leaf
                            [pscustomobject]@{
                                FullName = $matches.FullName
                                DirectoryName = Split-Path $matches.FullName
                                Name = $name
                                Size = [int64]$matches.Size
                                Extension = $(if ($name.IndexOf('.') -ne -1) {'.' + $name.split('.')[-1]} else {'[None]'})
                                DateModified = $matches.Date
                            }
                        }
                    } else {
                        # Uncomment to see all lines that were not matched in the regex above.
                        #Write-host $line
                    }
                }
            }
        } elseif ($Method -eq 'Dir') {
            $params = @('/a-d', '/-c') # ,'/TA' for last access time instead of date modified (default)
            if ($Recurse) { $params += '/S' }
            foreach ($dir in $Path) {
                foreach ($line in $(cmd /c dir $dir $params)) {
                    switch -Regex ($line) {

                        # folder
                        'Directory of (?<Folder>.*)' {
                            $lastDirName = -join ($matches.Folder, '\')
                        }

                        # file
                        '(?<Date>.* [ap]m) +(?<Size>.*?) (?<Name>.*)' {
                            [pscustomobject]@{
                                Folder = $CurrentDir
                                Name = $Matches.Name
                                Size = $Matches.Size
                                LastWriteTime = [datetime]$Matches.Date
                            }
                        }
                    }
                }
            }
        } elseif ($Method -eq 'AlphaFS') {
            ipmo $AlphaFSPath
            if ($Recurse) {
                $searchOption = 'AllDirectories'
            } else {
                $searchOption = 'TopDirectoryOnly'
            }
            if ($FullName) {
                [Alphaleonis.Win32.Filesystem.Directory]::EnumerateFiles($Path, '*.*', $searchOption)
            } else {
                [Alphaleonis.Win32.Filesystem.Directory]::EnumerateFiles($Path, '*.*', $searchOption) | % {
                    [Alphaleonis.Win32.Filesystem.File]::GetFileSystemEntryInfo($_)
                }
            }
        } elseif ($Method -eq 'EnumerateFiles') {
            if ($Recurse) {
                $searchOption = 'AllDirectories'
            } else {
                $searchOption = 'TopDirectoryOnly'
            }
            if ($FullName) {
                [System.IO.Directory]::EnumerateFiles($Path, '*.*', $searchOption) | % {$_}
            } else {
                [System.IO.Directory]::EnumerateFiles('c:\temp') | % {
                    [System.IO.FileInfo]::new($_)
                }
            }
        }
    }
}
