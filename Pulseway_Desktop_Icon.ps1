<#
==============================================================================
Create Desktop Icon to Pulseway Support Request
============+=================================================================
 Created: [05/17/2018]
 Author: Ethan Bell
============================================================================== 
 Modified: 
 Modifications: 
==============================================================================
 Purpose: Create a desktop icon in public profile for Pulseway Support Request
 Filename: Pulseway_Desktop_Icon_Support.ps1
==============================================================================
#>
$TargetApplication = "C:\Program Files\Pulseway\pcmontask.exe"
$TargetArguments = " support"
$ShortcutFile = "$env:Public\Desktop\Get Support.lnk"
$WScriptShell = New-Object -ComObject WScript.Shell
$Shortcut = $WScriptShell.CreateShortcut($ShortcutFile)
$Shortcut.TargetPath = $TargetApplication
$Shortcut.Arguments = $TargetArguments
$Shortcut.Save()