# create shortcut uses create-shortcut function and expects c:\temp to exist

<# convert shortcut to bat file - synology does not sync shortcuts
    $s = dir C:\temp\Shortcuts -re | ? extension -match 'lnk' | % fullname | % {Get-Shortcut $_}
    $s | % {'"' + $_.targetpath.replace(' (x86)','') + '" '+ $_.arguments.replace('%','%%') | set-content "c:\temp\test\$(split-path $_.fullname -leaf).bat"}
#>

function chromeapp ($url, [switch]$createshortcut, [switch]$createbat) {
    if (!$url) {
        $url = Get-Clipboard
    }

    if (!$url.startswith('http')) {
        $url = "http://$url"
    }

    if (Test-Path 'C:\Program Files (x86)\Google\Chrome') {
        $chrome = 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe'
    } elseif (Test-Path 'C:\Program Files\Google\Chrome') {
        $chrome = 'C:\Program Files\Google\Chrome\Application\chrome.exe'
    } else {
        throw 'chrome not found'
    }

    Write-Output "$chrome --app=$url"

    if ($createshortcut) {
        $s = $chrome
        $a = "--profile-directory=Default --app=$url"
        
        $n = $url.split('/', 3)[-1].Replace('.com', '').Replace('/', ' ')
        $d = "c:\temp\$n.lnk"

        Create-Shortcut -Source $s -DestinationLnk $d -Arguments $a
    }

    if ($createbat) {
        $n = $url.split('/', 3)[-1].Replace('.com', '').Replace('/', ' ')
        '"' + $chrome + '" ' + "--profile-directory=Default --app=$($url.Replace('%','%%'))" | Set-Content "c:\temp\$n.bat"
    }

    start chrome --app=$url
}
