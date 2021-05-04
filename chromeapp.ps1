# create shortcut uses create-shortcut function and expects c:\temp to exist

function chromeapp ($url, [switch]$createshortcut) {
    if (!$url) {
        $url = Get-Clipboard
    }

    if (!$url.startswith('http')) {
        $url = "http://$url"
    }

    Write-Output "chrome --app=$url"

    if ($createshortcut) {
        $s = 'C:\Program Files (x86)\Google\Chrome\Application\chrome.exe'
        $a = "--profile-directory=Default --app=$url"
        
        $n = $url.split('/', 3)[-1].Replace('.com', '').Replace('/', ' ')
        $d = "c:\temp\$n.lnk"

        Create-Shortcut -Source $s -DestinationLnk $d -Arguments $a
    }

    start chrome --app=$url
}
