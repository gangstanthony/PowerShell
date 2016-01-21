# check here for single file copy
# http://serverfault.com/questions/52983/robocopy-transfer-file-and-not-folder
# 
# Examples:
#
# Get-Files c:\temp -Recurse | ft -a
#
# Find folders that have more than 245 characters
# Get-Files -Recurse | Select-Object Fullname, @{n='Length';e={$_.FullName.Length}} | Where-Object {$_.fullname.endswith('\')} | Where-Object {$_.Length -gt 245}
#
# Notes:
#
# This will not show dirs unless recursive
# also, maybe add something to show size in appropriate b/kb/mb/gb
# -Include limits the resutls to files only!
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
        [array]$Path = $PWD,
        [array]$Include,
        [switch]$Recurse
    )
    
    $params = '/L', '/NJH', '/BYTES', '/FP', '/NC', '/TS', '/XJ', '/R:0', '/W:0'
    if ($Recurse) {$params += '/E'}
    if ($Include) {$params += $Include}
    foreach ($dir in $Path) {
        foreach ($line in $(robocopy $dir NULL $params)) {
            # folder
            if ($line -match '\s+\d+\s+(?<FullName>.*\\)$') {
                function createobject {
                    [pscustomobject]@{
                        FullName = $matches.FullName
                        DirectoryName = Split-Path $matches.FullName
                        Name = (Split-Path $matches.FullName -Leaf) + '\'
                        Size = $null
                        Extension = $null
                        DateModified = $null
                    }
                }
                
                if ($Include) {
                    if ($matches.Fullname -like "*$($include.replace('*',''))*") {
                        createobject
                    }
                } else {
                    createobject
                }
            # file
            } elseif ($line -match '(?<Size>\d+)\s(?<Date>\S+\s\S+)\s+(?<FullName>.*[^\\])$') {
                [pscustomobject]@{
                    FullName = $matches.FullName
                    DirectoryName = Split-Path $matches.FullName
                    Name = Split-Path $matches.FullName -Leaf
                    Size = [int64]$matches.Size
                    Extension = '.' + ($matches.FullName.split('.')[-1])
                    DateModified = $matches.Date
                }
            } else {
                # Uncomment to see all lines that were not matched in the regex above.
                #Write-host $line
            }
        }
    }
}
