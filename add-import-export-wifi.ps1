
# backup already known wifi to config files
function export-wifi {
    param (
        $path = 'c:\temp'
    )

    $path = Join-Path $path export-wifi

    if (!(Test-Path $path -ea SilentlyContinue)) {
        md $path | Out-Null
    }

    $networks = netsh wlan show profiles | ? {$_ -match ' : '} | % {$_.split(':')[1].trim()} | % {$n = $_; netsh wlan show profile name="$_" key=clear} | ? {$_ -match 'key content'} | select @{n='Network';e={$n}}, @{n='Key';e={$_.split(':')[1].trim()}}
    $networks.network | % {netsh wlan export profile $_ key=clear folder=$path}
}


# load wifi from config files
function import-wifi {
    param (
        $path = 'c:\temp\export-wifi'
    )

    dir $path *.xml | % {netsh wlan add profile filename="$($_.FullName)" user=all}
}


# load wifi by ssid and pw
function add-wifi {
    param (
        $ssid = (Read-Host 'ssid'),
        $pass = (Read-Host 'pass')
    )

    Write-Warning 'SSID is case sensitive'

    do {
        $result = netsh wlan delete profile $ssid
        write-host $result
    } while ($result -match 'no wireless interface')

    $xml = @"
<?xml version="1.0"?>
<WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
	<name>$ssid</name>
	<SSIDConfig>
		<SSID>
			<name>$ssid</name>
		</SSID>
	</SSIDConfig>
	<connectionType>ESS</connectionType>
	<connectionMode>auto</connectionMode>
	<MSM>
		<security>
			<authEncryption>
				<authentication>WPA2PSK</authentication>
				<encryption>AES</encryption>
				<useOneX>false</useOneX>
			</authEncryption>
			<sharedKey>
				<keyType>passPhrase</keyType>
				<protected>false</protected>
				<keyMaterial>$pass</keyMaterial>
			</sharedKey>
		</security>
	</MSM>
	<MacRandomization xmlns="http://www.microsoft.com/networking/WLAN/profile/v3">
		<enableRandomization>false</enableRandomization>
	</MacRandomization>
</WLANProfile>
"@

    $xml | Set-Content "$env:TMP\$ssid.xml"

	netsh wlan add profile filename="$env:TMP\$ssid.xml" user=all

    del "$env:TMP\$ssid.xml"
}

