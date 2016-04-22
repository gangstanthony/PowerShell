# more ideas
# https://github.com/sushihangover/SushiHangover-PowerShell/blob/master/Microsoft.PowerShell_profile.ps1

c:
cd\

# Runs all .ps1 files in this module's directory
Get-ChildItem -Path $PSScriptRoot\*.ps1 | Foreach-Object { . $_.FullName }

$env:path = @(
    $env:path
    'C:\Program Files (x86)\Notepad++\'
    'C:\Users\admin\AppData\Local\GitHub\PortableGit_c7e0cbde92ba565cb218a521411d0e854079a28c\cmd'
    'C:\Users\admin\AppData\Local\GitHub\PortableGit_c7e0cbde92ba565cb218a521411d0e854079a28c\usr\bin'
    'C:\Users\admin\AppData\Local\GitHub\PortableGit_c7e0cbde92ba565cb218a521411d0e854079a28c\usr\share\git-tfs'
    'C:\Users\admin\AppData\Local\Apps\2.0\C31EKMVW.15A\TWAQ6XY3.BAX\gith..tion_317444273a93ac29_0003.0000_328216539257acd4'
    'C:\Users\admin\AppData\Local\GitHub\lfs-amd64_1.1.0;C:\WINDOWS\Microsoft.NET\Framework\v4.0.30319'
) -join ';'

# http://blogs.msdn.com/b/powershell/archive/2006/06/24/644987.aspx
Update-TypeData "$PSScriptRoot\My.Types.Ps1xml"

# http://get-powershell.com/post/2008/06/25/Stuffing-the-output-of-the-last-command-into-an-automatic-variable.aspx
function Out-Default {
    try {
        $input | Tee-Object -Variable global:lastobject | Microsoft.PowerShell.Core\Out-Default
    } catch {
        $input | Microsoft.PowerShell.Core\Out-Default
    }
}

function gj { Get-Job | select id, name, state | ft -a }
function sj ($id = '*') { Get-Job $id | Stop-Job; gj }
function rj { Get-Job | ? state -match 'comp' | Remove-Job }

# https://www.reddit.com/r/PowerShell/comments/2x8n3y/getexcuse/
function Get-Excuse {
    (Invoke-WebRequest http://pages.cs.wisc.edu/~ballard/bofh/excuses -OutVariable excuses).content.split([Environment]::NewLine)[(get-random $excuses.content.split([Environment]::NewLine).count)]
}

function fourdigitpw {
    $fpw = 1111
    while ($fpw -split '' | ? {$_} | group | ? count -gt 1) {
        $fpw = -join(1..4 | % {Get-Random -Minimum 0 -Maximum 10})
    }
    $fpw
}

# random password like Asdf1234
function rpw {
    $pw = ''
    while (($pw -split '' | ? {$_} | group).count -ne 8) {
        $pw = -join$($([char](65..90|Get-Random));$(1..3|%{[char](97..122|Get-Random)});$(1..4|%{0..9|Get-Random}))
    }
    $pw
}

# eject removable drives
function ej ([switch]$more) {
    $count = 0
    if ($more) {
        $drives = [io.driveinfo]::getdrives() | ? {$_.drivetype -notmatch 'Network' -and !(dir $_.name users -ea 0)}
    } else {
        $drives = [io.driveinfo]::getdrives() | ? {$_.drivetype -match 'Removable' -and $_.driveformat -match 'fat32'}
    }
    if ($drives) {
        write-host $($drives | select name, volumelabel, drivetype, driveformat, totalsize | ft -a | out-string)
        $letter = Read-Host "Drive letter ($(if ($drives.count -eq 1) {$drives} else {'?'}))"
        if (!$letter) {$letter = $drives.name[0]}
        $eject = New-Object -ComObject Shell.Application
        $eject.Namespace(17).ParseName($($drives | ? name -Match $letter)).InvokeVerb('Eject')
    }
}

#function py { . C:\Python27\python.exe }
function py { . C:\Users\admin\AppData\Local\Programs\Python\Python35-32\python.exe }

function ydl ($song) {cd c:\temp\music; c:\temp\music\youtube-dl.exe --extract-audio --audio-format mp3 -o '%(title)s.%(ext)s' -f 17 $(if ($song) {$song} else {$(get-clipboard)})}

function date {get-date -f 'yyyy-MM-dd_HH.mm.ss'}
# 'yyyyMMdd_HHmmss.fffffff'
# 'yyyy/MM/dd HH:mm:ss.fffffff'

# https://www.reddit.com/r/PowerShell/comments/49ahc1/what_are_your_cool_powershell_profile_scripts/
# http://kevinmarquette.blogspot.com/2015/11/here-is-my-custom-powershell-prompt.html
# https://www.reddit.com/r/PowerShell/comments/46hetc/powershell_profile_config/
$PSLogPath = ("{0}\Documents\WindowsPowerShell\log\{1:yyyyMMdd}-{2}.log" -f $env:USERPROFILE, (Get-Date), $PID)
if (!([System.IO.Directory]::Exists($(Split-Path $PSLogPath)))) { md $(Split-Path $PSLogPath) | Out-Null }
Add-Content -Value "# $(Get-Date) $env:username $env:computername" -Path $PSLogPath
Add-Content -Value "# $(Get-Location)" -Path $PSLogPath
function prompt {
    # KevMar logging
    $LastCmd = Get-History -Count 1
    if ($LastCmd) {
        $lastId = $LastCmd.Id
        Add-Content -Value "# $($LastCmd.StartExecutionTime)" -Path $PSLogPath
        Add-Content -Value "$($LastCmd.CommandLine)" -Path $PSLogPath
        Add-Content -Value '' -Path $PSLogPath
        $howlongwasthat = $LastCmd.EndExecutionTime.Subtract($LastCmd.StartExecutionTime).TotalSeconds
    }
    
    # Kerazy_POSH propmt
    # Get Powershell version information
    $MajorVersion = $PSVersionTable.PSVersion.Major
    $MinorVersion = $PSVersionTable.PSVersion.Minor

    # Detect if the Shell is 32- or 64-bit host
    if ([System.IntPtr]::Size -eq 8) {
        $ShellBits = 'x64 (64-bit)'
    } elseif ([System.IntPtr]::Size -eq 4) {
        $ShellBits = 'x86 (32-bit)'
    }

    # Set Window Title to display Powershell version info, Shell bits, username and computername
    $host.UI.RawUI.WindowTitle = "PowerShell v$MajorVersion.$MinorVersion $ShellBits | $env:USERNAME@$env:COMPUTERNAME"

    # Set Prompt Line 1 - include Date, file path location
    Write-Host(Get-Date -UFormat "%Y/%m/%d %H:%M:%S ($howlongwasthat) | ") -NoNewline -ForegroundColor DarkGreen
    Write-Host(Get-Location) -ForegroundColor DarkGreen

    # Set Prompt Line 2
    # Check for Administrator elevation
    $WId = [System.Security.Principal.WindowsIdentity]::GetCurrent()
    $prp = New-Object System.Security.Principal.WindowsPrincipal($wid)
    $Adm = [System.Security.Principal.WindowsBuiltInRole]::Administrator
    $IsAdmin = $prp.IsInRole($Adm)
    if ($IsAdmin) {        
        Write-Host '# ADMIN # ' -NoNewline -ForegroundColor Cyan
    } else {        
        Write-Host '# User # ' -NoNewline -ForegroundColor DarkCyan
    }
    Write-Host '»' -NoNewLine -ForeGroundColor Green
    ' ' # need this space to avoid the default white PS>
} 

<#
function prompt {
    #$global:LINE = $global:LINE + 1

    Write-Host "$((get-date).ToString('HH:mm:ss')) " -n #-f Cyan
    #Write-Host ' {' -n -f Yellow
    Write-Host (Shorten-Path (pwd).Path) -n #-f Cyan
    #Write-Host '}' -n -f Yellow
    #Write-Host " $('[' + $($global:LINE) + ']')" -n -f Yellow
    return $(if ($nestedpromptlevel -ge 1) { '>>' }) + '>'
}

$p = {
    function prompt {
        "$((get-date).ToString('HH:mm:ss')) $(Shorten-Path (pwd).Path)" + $(if ($nestedpromptlevel -ge 1) { '>>' }) + '>'
    }
}

#function prompt {
#    "$((get-date).ToString('HH:mm:ss')) $(Shorten-Path (pwd).Path)" + $(if ($nestedpromptlevel -ge 1) { '>>' }) + '>'
#}
#>

function lunch {
    sleep 3000
    write-host •
    messagebox clock in
}

function wimi {
    (iwr http://www.realip.info/api/p/realip.php).RawContent.split("`n")[-1] -replace '[^0-9.]'
}

function java {
    param(
        [switch]$download
    )
    if ($download) {
        $page = iwr http://java.com/en/download/windows_offline.jsp
        $version = $page.RawContent -split "`n" | ? {$_ -match 'recommend'} | select -f 1 | % {$_ -replace '^[^v]+| \(.*$'}
        $link = $page.links.href | ? {$_ -match '^http.*download'} | select -f 1
        iwr $link -outfile "c:\temp\Java $version.exe"
    } else {
        $(iwr http://java.com/en/download).Content.Split("`n") | ? {$_ -match 'version'} | select -f 1
    }
}

#function Format-List {$input | Tee-Object -Variable global:lastformat | Microsoft.PowerShell.Utility\Format-List}
#function Format-Table {$input | Tee-Object -Variable global:lastformat | Microsoft.PowerShell.Utility\Format-Table}
#if ($LastFormat) {$global:lastobject=$LastFormat; $LastFormat=$Null}

<#
# sal stop stop-process
sal ss select-string
sal wh write-host
sal no New-Object
sal add Add-Member
#>
