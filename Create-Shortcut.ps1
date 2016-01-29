# Create-Shortcut
# 
# Create-Shortcut -Source C:\temp\test.txt -DestinationLnk C:\temp\test.txt.lnk
# 
# Arguments
# Description
# FullName
# Hotkey
# IconLocation = '%SystemRoot%\system32\SHELL32.dll,16' # printer
# RelativePath
# TargetPath
# WindowStyle
# WorkingDirectory

function Create-Shortcut {
    param (
        [string]$Source,
        [string]$DestinationLnk,
        [string]$Arguments
    )

    BEGIN {
        $WshShell = New-Object -ComObject WScript.Shell
    }

    PROCESS {
        if (!$Source) {Throw 'No Source'}
        if (!$DestinationLnk) {Throw 'No DestinationLnk'}

        $Shortcut = $WshShell.CreateShortcut($DestinationLnk)
        $Shortcut.TargetPath = $Source
        if ($Arguments) {
            $Shortcut.Arguments = $Arguments
        }
        $Shortcut.Save()
    }

    END {
        function Release-Ref ($ref) {
            ([System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.__ComObject]$ref) -gt 0)
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
        }
        $Shortcut, $WshShell | % {$null = Release-Ref $_}
    }
}
