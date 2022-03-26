# check here for how to delete profiles
# http://www.thewindowsclub.com/delete-wifi-network-profile-windows
# netsh wlan delete profile name="MyWifiNetwork"

# one-liner
# netsh wlan show profiles | ? {$_ -match ' : '} | % {$_.split(':')[1].trim()} | % {$n = $_; netsh wlan show profile name="$_" key=clear} | ? {$_ -match 'key content'} | select @{n='Network';e={$n}}, @{n='Key';e={$_.split(':')[1].trim()}}

# https://www.reddit.com/r/PowerShell/comments/tnzyxw/showwifipasswords/
# optimized code credit to /u/Thotaz and /u/nascentt
function Show-WifiPasswords {
    netsh.exe wlan show profiles | Select-String -Pattern "(?<=^.+: ).+$" | ForEach-Object -Process {
        $NetworkName = $_.Matches[0].Value
        $KeyMatches = netsh.exe wlan show profile name="$NetworkName" key=clear | Select-String -Pattern "(?<=^\s+Key Content\s+: ).+$"
        [pscustomobject]@{
            NetworkName = $NetworkName
            SecurityKey = $( if ($KeyMatches) {$KeyMatches.Matches[0].Value} )
        }
    }
}

<# sample output
Network                         Key                    
-------                         ---                    
MyLuggage                       12345
NotYourWifi                     Topsecret#$%         
BearHouse                       P@ssw0rd
#>
