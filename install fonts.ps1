# http://superuser.com/questions/201896/how-do-i-install-a-font-from-the-windows-command-prompt
# powershell -executionpolicy bypass ".'.\install fonts.ps1'"

#if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]'Administrator'))
#{
#    Write-Warning "You do not have Administrator rights to run this script!`nPlease re-run this script as an Administrator!"
#    pause
#    Break
#}

# http://blogs.msdn.com/b/virtual_pc_guy/archive/2010/09/23/a-self-elevating-powershell-script.aspx
if (([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([System.Security.Principal.WindowsBuiltInRole]::Administrator)) {
    $Host.UI.RawUI.WindowTitle = $myInvocation.MyCommand.Definition + ' (Elevated)'
    $Host.UI.RawUI.BackgroundColor = 'DarkBlue'
    Clear-Host
} else {
    $newProcess = New-Object Diagnostics.ProcessStartInfo 'PowerShell'
    $newProcess.Arguments = "& '" + $script:MyInvocation.MyCommand.Path + "'"
    $newProcess.Verb = 'runas'
    [Diagnostics.Process]::Start($newProcess)
    exit
}
# Run your code that needs to be elevated here
Write-Host -NoNewLine 'Press any key to continue...'
$null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')

# get fonts from my flash drive
$UFD = [string[]]([io.driveinfo]::getdrives() | % {$_.name} | ? {test-path "$_\TEMPORARY\Helvetica Fonts\helveticaneue"})
$source = Read-Host "Source ($(if ($UFD) {$UFD[0]} else {'?'})) "
if (!$source) {$source = $UFD[0]}
$source = Join-Path $source '\TEMPORARY\Helvetica Fonts\helveticaneue'

# install fonts
$fonts = (New-Object -ComObject Shell.Application).Namespace(0x14)
dir $source | % { $fonts.CopyHere($_.fullname) }

