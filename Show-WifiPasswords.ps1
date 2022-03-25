# check here for how to delete profiles
# http://www.thewindowsclub.com/delete-wifi-network-profile-windows
# netsh wlan delete profile name="MyWifiNetwork"

function Show-WifiPasswords {
    netsh wlan show profiles | ? {$_ -match ' : '} | % {$_.split(':')[1].trim()} | % {$n = $_; netsh wlan show profile name="$_" key=clear} | ? {$_ -match 'key content'} | select @{n='Network';e={$n}}, @{n='Key';e={$_.split(':')[1].trim()}}
}

<# sample output
Network                         Key                    
-------                         ---                    
MyLuggage                       12345
NotYourWifi                     Topsecret#$%         
BearHouse                       P@ssw0rd
#>
