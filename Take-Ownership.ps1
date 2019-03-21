## INFO
# Take ownership then full control of every item in a folder recursively

## NOTES
# takeown.exe /A /F $Folder
# takeown /f '\\computername\c$\Users\sam' /r /d y
# cacls '\\computername\c$\Users\sam' /e /c /t /g domain\sam:f system:f everyone:f

# copy subinacl.exe
# copy $env:USERPROFILE\Downloads\subinacl\subinacl.exe \\$comp\c$\windows\system32

function Take-Ownership {
    param (
        [String]$Folder,
        [switch]$Everyone,
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
