<#
.example
    Create-DesktopPin -name "google drive" -path "c:\users\name\google drive"

.example
    Create-DesktopPin -name "google drive" -delete # -force
#>

function Create-DesktopPin {
    param (
        $name,
        $path,
        [switch]$delete,
        [switch]$force
    )

    if ($delete) {
        $item = dir "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\" | ? {(Get-ItemProperty $_.pspath).'(default)' -ceq $name}
        $guid = (Split-Path $item.name -Leaf).trim('{}')
        if (!$guid) {
            throw "Could not find: $name"
        } else {
            if (!$force) {
                $createdby = (Get-ItemProperty $item.PSPath).CreatedBy
                if ($createdby -ne 'Create-DesktopPin') {
                    $answer = Read-Host 'Looks like this Pin was not created by Create-DesktopPin. Delete anyway? y/[N]'
                    if ($answer -ne 'y') {
                        return
                    }
                }
            }
        }
        
        $null = reg delete "HKCU\Software\Classes\CLSID\{$guid}" /f
        $null = reg delete "HKCU\Software\Classes\Wow6432Node\CLSID\{$guid}" /f
        $null = reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{$guid}" /f
        $null = reg delete "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{$guid}" /f
    } else {
        if (!(New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
            throw 'you are not admin'
        }

        [String] $GUID = [guid]::NewGuid().ToString()
        $guid

        $null = reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\HideDesktopIcons\NewStartPanel" /v "{$guid}" /t REG_DWORD /d "1" /f
        $null = reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{$guid}" /ve /t REG_SZ /d $name /f
        $null = reg add "HKCU\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Desktop\NameSpace\{$guid}" /v "CreatedBy" /t REG_SZ /d "Create-DesktopPin" /f

        $null = reg add "HKCU\Software\Classes\CLSID\{$guid}" /ve /t REG_SZ /d $name /f
        $null = reg add "HKCU\Software\Classes\CLSID\{$guid}" /v "System.IsPinnedToNamespaceTree" /t REG_DWORD /d "1" /f
        $null = reg add "HKCU\Software\Classes\CLSID\{$guid}" /v "SortOrderIndex" /t REG_DWORD /d "66" /f
        $null = reg add "HKCU\Software\Classes\CLSID\{$guid}\InProcServer32" /ve /t REG_EXPAND_SZ /d "%%SYSTEMROOT%%\system32\shell32.dll" /f
        $null = reg add "HKCU\Software\Classes\CLSID\{$guid}\ShellFolder" /v "FolderValueFlags" /t REG_DWORD /d "40" /f
        $null = reg add "HKCU\Software\Classes\CLSID\{$guid}\ShellFolder" /v "Attributes" /t REG_DWORD /d "4034920525" /f
        #$null = reg add "HKCU\Software\Classes\CLSID\{$guid}\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files (x86)\Google\Drive\googledrivesync.exe,0" /f
        $null = reg add "HKCU\Software\Classes\CLSID\{$guid}\DefaultIcon" /ve /t REG_SZ /d "%%SystemRoot%%\System32\shell32.dll,3" /f
        $null = reg add "HKCU\Software\Classes\CLSID\{$guid}\Instance" /v "CLSID" /t REG_SZ /d "{0E5AAE11-A475-4c5b-AB00-C66DE400274E}" /f
        $null = reg add "HKCU\Software\Classes\CLSID\{$guid}\Instance\InitPropertyBag" /v "Attributes" /t REG_DWORD /d "17" /f
        $null = reg add "HKCU\Software\Classes\CLSID\{$guid}\Instance\InitPropertyBag" /v "TargetFolderPath" /t REG_SZ /d $path /f

        $null = reg add "HKCU\Software\Classes\Wow6432Node\CLSID\{$guid}" /ve /t REG_SZ /d $name /f
        $null = reg add "HKCU\Software\Classes\Wow6432Node\CLSID\{$guid}" /v "System.IsPinnedToNamespaceTree" /t REG_DWORD /d "1" /f
        $null = reg add "HKCU\Software\Classes\Wow6432Node\CLSID\{$guid}" /v "SortOrderIndex" /t REG_DWORD /d "66" /f
        $null = reg add "HKCU\Software\Classes\Wow6432Node\CLSID\{$guid}\InProcServer32" /ve /t REG_EXPAND_SZ /d "%%SYSTEMROOT%%\system32\shell32.dll" /f
        $null = reg add "HKCU\Software\Classes\Wow6432Node\CLSID\{$guid}\ShellFolder" /v "FolderValueFlags" /t REG_DWORD /d "40" /f
        $null = reg add "HKCU\Software\Classes\Wow6432Node\CLSID\{$guid}\ShellFolder" /v "Attributes" /t REG_DWORD /d "4034920525" /f
        #$null = reg add "HKCU\Software\Classes\Wow6432Node\CLSID\{$guid}\DefaultIcon" /ve /t REG_SZ /d "C:\Program Files (x86)\Google\Drive\googledrivesync.exe,0" /f
        $null = reg add "HKCU\Software\Classes\Wow6432Node\CLSID\{$guid}\DefaultIcon" /ve /t REG_SZ /d "%%SystemRoot%%\System32\shell32.dll,3" /f
        $null = reg add "HKCU\Software\Classes\Wow6432Node\CLSID\{$guid}\Instance" /v "CLSID" /t REG_SZ /d "{0E5AAE11-A475-4c5b-AB00-C66DE400274E}" /f
        $null = reg add "HKCU\Software\Classes\Wow6432Node\CLSID\{$guid}\Instance\InitPropertyBag" /v "Attributes" /t REG_DWORD /d "17" /f
        $null = reg add "HKCU\Software\Classes\Wow6432Node\CLSID\{$guid}\Instance\InitPropertyBag" /v "TargetFolderPath" /t REG_SZ /d $path /f
    }
}
