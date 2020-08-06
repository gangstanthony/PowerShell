# https://winaero.com/blog/add-custom-folders-or-control-panel-applets-to-navigation-pane-in-file-explorer/

<#
.example
    Create-ThisPcPin -name "google drive" -path "c:\users\name\google drive"

.example
    Create-ThisPcPin -name "google drive" -delete # -force
#>

function Create-ThisPcPin {
    param (
        $name,
        $path,
        [switch]$delete,
        [switch]$force
    )

    $sid = ([System.Security.Principal.WindowsIdentity]::GetCurrent()).User.Value

    if ($delete) {
        New-PSDrive -PSProvider Registry -Name HKU -Root HKEY_USERS
        $item = dir "hku:\$sid\Software\Classes\CLSID\" | ? {(Get-ItemProperty $_.pspath).'(default)' -ceq $name}
        $guid = (Split-Path $item.name -Leaf).trim('{}')
        if (!$guid) {
            throw "Could not find: $name"
        } else {
            if (!$force) {
                $createdby = (Get-ItemProperty $item.PSPath).CreatedBy
                if ($createdby -ne 'Create-ThisPcPin') {
                    $answer = Read-Host 'Looks like this Pin was not created by Create-ThisPcPin. Delete anyway? y/[N]'
                    if ($answer -ne 'y') {
                        return
                    }
                }
            }
        }
        Remove-PSDrive hku

        reg delete "HKU\$sid\Software\Classes\CLSID\{$GUID}" /f
        reg delete "HKU\$sid\Software\Classes\WOW6432Node\CLSID\{$GUID}" /f
        reg delete "HKU\$sid\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{$GUID}" /f
        reg delete "HKU\$sid`_Classes\CLSID\{$GUID}" /f
        reg delete "HKU\$sid`_Classes\WOW6432Node\CLSID\{$GUID}" /f
    } else {
        if (!(New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
            throw 'you are not admin'
        }

        [String] $GUID = [guid]::NewGuid().ToString()
    
        $null = reg add "HKU\$sid\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{$GUID}" /ve /t REG_SZ /d $name /f
        $null = reg add "HKU\$sid\Software\Microsoft\Windows\CurrentVersion\Explorer\MyComputer\NameSpace\{$GUID}" /v "CreatedBy" /t REG_SZ /d "Create-ThisPcPin" /f
        $null = reg add "HKU\$sid\Software\Classes\CLSID\{$GUID}" /ve /t REG_SZ /d $name /f
        $null = reg add "HKU\$sid\Software\Classes\CLSID\{$GUID}" /v "{305ca226-d286-468e-b848-2b2e8e697b74} 2" /t REG_DWORD /d "4294967295" /f
        $null = reg add "HKU\$sid\Software\Classes\CLSID\{$GUID}" /v "CreatedBy" /t REG_SZ /d "Create-ThisPcPin" /f
        $null = reg add "HKU\$sid\Software\Classes\CLSID\{$GUID}" /v "DescriptionID" /t REG_DWORD /d "3" /f
        $null = reg add "HKU\$sid\Software\Classes\CLSID\{$GUID}" /v "InfoTip" /t REG_SZ /d $path /f
        $null = reg add "HKU\$sid\Software\Classes\CLSID\{$GUID}" /v "System.IsPinnedtoNameSpaceTree" /t REG_DWORD /d "1" /f
        $null = reg add "HKU\$sid\Software\Classes\CLSID\{$GUID}\DefaultIcon" /ve /t REG_SZ /d "%%SystemRoot%%\System32\shell32.dll,3" /f
        $null = reg add "HKU\$sid\Software\Classes\CLSID\{$GUID}\InProcServer32" /ve /t REG_SZ /d "shdocvw.dll" /f
        $null = reg add "HKU\$sid\Software\Classes\CLSID\{$GUID}\InProcServer32" /v "ThreadingModel" /t REG_SZ /d "Both" /f
        $null = reg add "HKU\$sid\Software\Classes\CLSID\{$GUID}\Instance" /v "CLSID" /t REG_SZ /d "{0afaced1-e828-11d1-9187-b532f1e9575d}" /f
        $null = reg add "HKU\$sid\Software\Classes\CLSID\{$GUID}\Instance\InitPropertyBag" /v "Attributes" /t REG_DWORD /d "21" /f
        $null = reg add "HKU\$sid\Software\Classes\CLSID\{$GUID}\Instance\InitPropertyBag" /v "Target" /t REG_EXPAND_SZ /d $path /f
        $null = reg add "HKU\$sid\Software\Classes\CLSID\{$GUID}\ShellEx\PropertySheetHandlers\tab 1 general" /ve /t REG_SZ /d "{21b22460-3aea-1069-a2dc-08002b30309d}" /f
        $null = reg add "HKU\$sid\Software\Classes\CLSID\{$GUID}\ShellEx\PropertySheetHandlers\tab 2 customize" /ve /t REG_SZ /d "{ef43ecfe-2ab9-4632-bf21-58909dd177f0}" /f
        $null = reg add "HKU\$sid\Software\Classes\CLSID\{$GUID}\ShellEx\PropertySheetHandlers\tab 3 sharing" /ve /t REG_SZ /d "{f81e9010-6ea4-11ce-a7ff-00aa003ca9f6}" /f
        $null = reg add "HKU\$sid\Software\Classes\CLSID\{$GUID}\ShellEx\PropertySheetHandlers\tab 4 security" /ve /t REG_SZ /d "{1f2e5c40-9550-11ce-99d2-00aa006e086c}" /f
        $null = reg add "HKU\$sid\Software\Classes\CLSID\{$GUID}\ShellFolder" /v "Attributes" /t REG_DWORD /d "4034920525" /f
        $null = reg add "HKU\$sid\Software\Classes\CLSID\{$GUID}\ShellFolder" /v "HideAsDeletePerUser" /t REG_SZ /f
        $null = reg add "HKU\$sid\Software\Classes\CLSID\{$GUID}\ShellFolder" /v "WantsFORPARSING" /t REG_SZ /f
        $null = reg add "HKU\$sid\Software\Classes\WOW6432Node\CLSID\{$GUID}" /ve /t REG_SZ /d $name /f
        $null = reg add "HKU\$sid\Software\Classes\WOW6432Node\CLSID\{$GUID}" /v "{305ca226-d286-468e-b848-2b2e8e697b74} 2" /t REG_DWORD /d "4294967295" /f
        $null = reg add "HKU\$sid\Software\Classes\WOW6432Node\CLSID\{$GUID}" /v "CreatedBy" /t REG_SZ /d "Create-ThisPcPin" /f
        $null = reg add "HKU\$sid\Software\Classes\WOW6432Node\CLSID\{$GUID}" /v "DescriptionID" /t REG_DWORD /d "3" /f
        $null = reg add "HKU\$sid\Software\Classes\WOW6432Node\CLSID\{$GUID}" /v "InfoTip" /t REG_SZ /d $path /f
        $null = reg add "HKU\$sid\Software\Classes\WOW6432Node\CLSID\{$GUID}" /v "System.IsPinnedtoNameSpaceTree" /t REG_DWORD /d "1" /f
        $null = reg add "HKU\$sid\Software\Classes\WOW6432Node\CLSID\{$GUID}\DefaultIcon" /ve /t REG_SZ /d "%%SystemRoot%%\System32\shell32.dll,3" /f
        $null = reg add "HKU\$sid\Software\Classes\WOW6432Node\CLSID\{$GUID}\InProcServer32" /ve /t REG_SZ /d "shdocvw.dll" /f
        $null = reg add "HKU\$sid\Software\Classes\WOW6432Node\CLSID\{$GUID}\InProcServer32" /v "ThreadingModel" /t REG_SZ /d "Both" /f
        $null = reg add "HKU\$sid\Software\Classes\WOW6432Node\CLSID\{$GUID}\Instance" /v "CLSID" /t REG_SZ /d "{0afaced1-e828-11d1-9187-b532f1e9575d}" /f
        $null = reg add "HKU\$sid\Software\Classes\WOW6432Node\CLSID\{$GUID}\Instance\InitPropertyBag" /v "Attributes" /t REG_DWORD /d "21" /f
        $null = reg add "HKU\$sid\Software\Classes\WOW6432Node\CLSID\{$GUID}\Instance\InitPropertyBag" /v "Target" /t REG_EXPAND_SZ /d $path /f
        $null = reg add "HKU\$sid\Software\Classes\WOW6432Node\CLSID\{$GUID}\ShellEx\PropertySheetHandlers\tab 1 general" /ve /t REG_SZ /d "{21b22460-3aea-1069-a2dc-08002b30309d}" /f
        $null = reg add "HKU\$sid\Software\Classes\WOW6432Node\CLSID\{$GUID}\ShellEx\PropertySheetHandlers\tab 2 customize" /ve /t REG_SZ /d "{ef43ecfe-2ab9-4632-bf21-58909dd177f0}" /f
        $null = reg add "HKU\$sid\Software\Classes\WOW6432Node\CLSID\{$GUID}\ShellEx\PropertySheetHandlers\tab 3 sharing" /ve /t REG_SZ /d "{f81e9010-6ea4-11ce-a7ff-00aa003ca9f6}" /f
        $null = reg add "HKU\$sid\Software\Classes\WOW6432Node\CLSID\{$GUID}\ShellEx\PropertySheetHandlers\tab 4 security" /ve /t REG_SZ /d "{1f2e5c40-9550-11ce-99d2-00aa006e086c}" /f
        $null = reg add "HKU\$sid\Software\Classes\WOW6432Node\CLSID\{$GUID}\ShellFolder" /v "Attributes" /t REG_DWORD /d "4034920525" /f
        $null = reg add "HKU\$sid\Software\Classes\WOW6432Node\CLSID\{$GUID}\ShellFolder" /v "HideAsDeletePerUser" /t REG_SZ /f
        $null = reg add "HKU\$sid\Software\Classes\WOW6432Node\CLSID\{$GUID}\ShellFolder" /v "WantsFORPARSING" /t REG_SZ /f
        $null = reg add "HKU\$sid`_Classes\CLSID\{$GUID}" /ve /t REG_SZ /d $name /f
        $null = reg add "HKU\$sid`_Classes\CLSID\{$GUID}" /v "{305ca226-d286-468e-b848-2b2e8e697b74} 2" /t REG_DWORD /d "4294967295" /f
        $null = reg add "HKU\$sid`_Classes\CLSID\{$GUID}" /v "CreatedBy" /t REG_SZ /d "Create-ThisPcPin" /f
        $null = reg add "HKU\$sid`_Classes\CLSID\{$GUID}" /v "DescriptionID" /t REG_DWORD /d "3" /f
        $null = reg add "HKU\$sid`_Classes\CLSID\{$GUID}" /v "InfoTip" /t REG_SZ /d $path /f
        $null = reg add "HKU\$sid`_Classes\CLSID\{$GUID}" /v "System.IsPinnedtoNameSpaceTree" /t REG_DWORD /d "1" /f
        $null = reg add "HKU\$sid`_Classes\CLSID\{$GUID}\DefaultIcon" /ve /t REG_SZ /d "%%SystemRoot%%\System32\shell32.dll,3" /f
        $null = reg add "HKU\$sid`_Classes\CLSID\{$GUID}\InProcServer32" /ve /t REG_SZ /d "shdocvw.dll" /f
        $null = reg add "HKU\$sid`_Classes\CLSID\{$GUID}\InProcServer32" /v "ThreadingModel" /t REG_SZ /d "Both" /f
        $null = reg add "HKU\$sid`_Classes\CLSID\{$GUID}\Instance" /v "CLSID" /t REG_SZ /d "{0afaced1-e828-11d1-9187-b532f1e9575d}" /f
        $null = reg add "HKU\$sid`_Classes\CLSID\{$GUID}\Instance\InitPropertyBag" /v "Attributes" /t REG_DWORD /d "21" /f
        $null = reg add "HKU\$sid`_Classes\CLSID\{$GUID}\Instance\InitPropertyBag" /v "Target" /t REG_EXPAND_SZ /d $path /f
        $null = reg add "HKU\$sid`_Classes\CLSID\{$GUID}\ShellEx\PropertySheetHandlers\tab 1 general" /ve /t REG_SZ /d "{21b22460-3aea-1069-a2dc-08002b30309d}" /f
        $null = reg add "HKU\$sid`_Classes\CLSID\{$GUID}\ShellEx\PropertySheetHandlers\tab 2 customize" /ve /t REG_SZ /d "{ef43ecfe-2ab9-4632-bf21-58909dd177f0}" /f
        $null = reg add "HKU\$sid`_Classes\CLSID\{$GUID}\ShellEx\PropertySheetHandlers\tab 3 sharing" /ve /t REG_SZ /d "{f81e9010-6ea4-11ce-a7ff-00aa003ca9f6}" /f
        $null = reg add "HKU\$sid`_Classes\CLSID\{$GUID}\ShellEx\PropertySheetHandlers\tab 4 security" /ve /t REG_SZ /d "{1f2e5c40-9550-11ce-99d2-00aa006e086c}" /f
        $null = reg add "HKU\$sid`_Classes\CLSID\{$GUID}\ShellFolder" /v "Attributes" /t REG_DWORD /d "4034920525" /f
        $null = reg add "HKU\$sid`_Classes\CLSID\{$GUID}\ShellFolder" /v "HideAsDeletePerUser" /t REG_SZ /f
        $null = reg add "HKU\$sid`_Classes\CLSID\{$GUID}\ShellFolder" /v "WantsFORPARSING" /t REG_SZ /f
        $null = reg add "HKU\$sid`_Classes\WOW6432Node\CLSID\{$GUID}" /ve /t REG_SZ /d $name /f
        $null = reg add "HKU\$sid`_Classes\WOW6432Node\CLSID\{$GUID}" /v "{305ca226-d286-468e-b848-2b2e8e697b74} 2" /t REG_DWORD /d "4294967295" /f
        $null = reg add "HKU\$sid`_Classes\WOW6432Node\CLSID\{$GUID}" /v "CreatedBy" /t REG_SZ /d "Create-ThisPcPin" /f
        $null = reg add "HKU\$sid`_Classes\WOW6432Node\CLSID\{$GUID}" /v "DescriptionID" /t REG_DWORD /d "3" /f
        $null = reg add "HKU\$sid`_Classes\WOW6432Node\CLSID\{$GUID}" /v "InfoTip" /t REG_SZ /d $path /f
        $null = reg add "HKU\$sid`_Classes\WOW6432Node\CLSID\{$GUID}" /v "System.IsPinnedtoNameSpaceTree" /t REG_DWORD /d "1" /f
        $null = reg add "HKU\$sid`_Classes\WOW6432Node\CLSID\{$GUID}\DefaultIcon" /ve /t REG_SZ /d "%%SystemRoot%%\System32\shell32.dll,3" /f
        $null = reg add "HKU\$sid`_Classes\WOW6432Node\CLSID\{$GUID}\InProcServer32" /ve /t REG_SZ /d "shdocvw.dll" /f
        $null = reg add "HKU\$sid`_Classes\WOW6432Node\CLSID\{$GUID}\InProcServer32" /v "ThreadingModel" /t REG_SZ /d "Both" /f
        $null = reg add "HKU\$sid`_Classes\WOW6432Node\CLSID\{$GUID}\Instance" /v "CLSID" /t REG_SZ /d "{0afaced1-e828-11d1-9187-b532f1e9575d}" /f
        $null = reg add "HKU\$sid`_Classes\WOW6432Node\CLSID\{$GUID}\Instance\InitPropertyBag" /v "Attributes" /t REG_DWORD /d "21" /f
        $null = reg add "HKU\$sid`_Classes\WOW6432Node\CLSID\{$GUID}\Instance\InitPropertyBag" /v "Target" /t REG_EXPAND_SZ /d $path /f
        $null = reg add "HKU\$sid`_Classes\WOW6432Node\CLSID\{$GUID}\ShellEx\PropertySheetHandlers\tab 1 general" /ve /t REG_SZ /d "{21b22460-3aea-1069-a2dc-08002b30309d}" /f
        $null = reg add "HKU\$sid`_Classes\WOW6432Node\CLSID\{$GUID}\ShellEx\PropertySheetHandlers\tab 2 customize" /ve /t REG_SZ /d "{ef43ecfe-2ab9-4632-bf21-58909dd177f0}" /f
        $null = reg add "HKU\$sid`_Classes\WOW6432Node\CLSID\{$GUID}\ShellEx\PropertySheetHandlers\tab 3 sharing" /ve /t REG_SZ /d "{f81e9010-6ea4-11ce-a7ff-00aa003ca9f6}" /f
        $null = reg add "HKU\$sid`_Classes\WOW6432Node\CLSID\{$GUID}\ShellEx\PropertySheetHandlers\tab 4 security" /ve /t REG_SZ /d "{1f2e5c40-9550-11ce-99d2-00aa006e086c}" /f
        $null = reg add "HKU\$sid`_Classes\WOW6432Node\CLSID\{$GUID}\ShellFolder" /v "Attributes" /t REG_DWORD /d "4034920525" /f
        $null = reg add "HKU\$sid`_Classes\WOW6432Node\CLSID\{$GUID}\ShellFolder" /v "HideAsDeletePerUser" /t REG_SZ /f
        $null = reg add "HKU\$sid`_Classes\WOW6432Node\CLSID\{$GUID}\ShellFolder" /v "WantsFORPARSING" /t REG_SZ /f

        $guid
    }
}
