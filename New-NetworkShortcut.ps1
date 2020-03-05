# https://serverfault.com/questions/429240/how-do-you-manage-network-locations-through-domain-group-policies

function New-NetworkShortcut {
    param (
        [Parameter(Mandatory=$true)] [string]$Name,
        [Parameter(Mandatory=$true)] [string]$Target,
        [string]$ComputerName = $env:COMPUTERNAME,
        [string]$SAM = $env:USERNAME
    )

    $networkshortcut_name = $Name
    $networkshortcut_target = $Target
    
    # doesn't work in posh v2
    #$networkshortcuts_path = [Environment]::GetFolderPath('NetworkShortcuts')
    $networkshortcuts_path = "\\$ComputerName\c$\users\$SAM\AppData\Roaming\Microsoft\Windows\Network Shortcuts"
    if (!(Test-Path $networkshortcuts_path)) {
        md $networkshortcuts_path
    }

    $networkshortcut_path = "$networkshortcuts_path\$networkshortcut_name"
    $desktopini_path = "$networkshortcut_path\desktop.ini"
    $targetlnk_path = "$networkshortcut_path\target.lnk"

    $desktopini_text = "[.ShellClassInfo]`r`nCLSID2={0AFACED1-E828-11D1-9187-B532F1E9575D}`r`nFlags=2"

    if (Test-Path -Path $networkshortcut_path -PathType Container) {
        Remove-Item -Path $networkshortcut_path -Recurse -Force
    }

    [void](New-Item -Path $networkshortcut_path -ItemType directory)

    Set-ItemProperty -Path $networkshortcut_path -Name Attributes -Value 1

    Out-File -FilePath $desktopini_path -InputObject $desktopini_text -Encoding ascii

    Set-ItemProperty -Path $desktopini_path -Name Attributes -Value 6

    $WshShell = New-Object -com WScript.Shell
    $Shortcut = $WshShell.CreateShortcut($targetlnk_path)
    $Shortcut.TargetPath = $networkshortcut_target
    $Shortcut.Save()
}
