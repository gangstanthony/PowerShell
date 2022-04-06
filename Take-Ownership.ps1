## INFO
# Take ownership then full control of every item in a folder recursively

## NOTES
# takeown.exe /A /F $Folder
# takeown /f '\\computername\c$\Users\sam' /r /d y
# cacls '\\computername\c$\Users\sam' /e /c /t /g domain\sam:f system:f everyone:f

# https://github.com/gangstanthony/PowerShell/blob/master/subinacl.exe?raw=true
<# download and copy subinacl.exe
    $msiurls = @(
        'https://download.microsoft.com/download/1/7/d/17d82b72-bc6a-4dc8-bfaa-98b37b22b367/subinacl.msi'
    ) | select @{n='url';e={$_}}, @{n='name';e={Split-Path $_ -Leaf}}

    foreach ($msiurl in $msiurls) {
        $msisavepath = Join-Path $env:temp $msiurl.name
        Write-Host "Attempting to download $($msiurl.name) to $env:TEMP..."
        iwr $msiurl.url -OutFile $msisavepath

        Write-Host "Attempting to install $msisavepath..."
        try {
            start -wait msiexec "/i $msisavepath /qb"
        } catch { throw $_ }

        Write-Host "Removing downloaded msi $msisavepath"
        Remove-Item $msisavepath
    }

    $exe = Get-ChildItem -Path 'C:\Program Files*\Windows Resource Kits\Tools\subinacl.exe' | select -f 1 -exp fullname
    
    # copy $exe \\$comp\c$\windows\system32
#>

function Take-Ownership {
    param (
        [String]$Folder,
        [switch]$Everyone,
        [switch]$me,
        [switch]$ThisItemOnly,
        [switch]$File,
        [switch]$Revoke
    )

    if ( !$file -and !($Folder.EndsWith('\')) ) {
        $Folder += '\'
    }

    if ($Folder -match ' ') {
        $Folder = '"' + $Folder + '"'
    }

    if ($Everyone) {
        if ($Revoke) {
            if (!$ThisItemOnly) {
                SubInACL.exe /SUBDIRECTORIES $Folder /REVOKE=Everyone
            }
            SubInACL.exe /FILE $Folder /REVOKE=Everyone
        } else {
            SubInACL.exe /FILE $Folder /GRANT=Everyone=F
            if (!$ThisItemOnly) {
                SubInACL.exe /SUBDIRECTORIES $Folder /GRANT=Everyone=F
            }
        }
    } elseif ($me) {
        if ($Revoke) {
            if (!$ThisItemOnly) {
                SubInACL.exe /SUBDIRECTORIES $Folder /REVOKE=$(whoami)
            }
            SubInACL.exe /FILE $Folder /REVOKE=$(whoami)
        } else {
            SubInACL.exe /FILE $Folder /GRANT=$(whoami)=F
            if (!$ThisItemOnly) {
                SubInACL.exe /SUBDIRECTORIES $Folder /GRANT=$(whoami)=F
            }
        }
    } else {
        if ($Revoke) {
            if (!$ThisItemOnly) {
                SubInACL.exe /SUBDIRECTORIES $Folder /REVOKE=Administrators
            }
            SubInACL.exe /FILE $Folder /REVOKE=Administrators
        } else {
            SubInACL.exe /FILE $Folder /GRANT=Administrators=F
            if (!$ThisItemOnly) {
                SubInACL.exe /SUBDIRECTORIES $Folder /GRANT=Administrators=F
            }
        }
    }
}
