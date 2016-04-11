# must be administrator

function Setup-Network {
    param (
        [switch]$dhcp,
        $ip,
        $mask,
        $gateway,
        $dns1,
        $dns2
    )
    
    # check admin rights
    $admin = reg query "HKU\S-1-5-19\Environment" 2>&1
    if ($admin -match 'denied') { Throw 'You are not admin' }

    if (!$dhcp -and !$ip) { Throw 'Must specify IP or DHCP.' }
    if ($ip) {
        if ($ip -notmatch '(\d{1,3}\.){3}\d{1,3}') { Throw 'Check IP address format.' }
        if (!$mask) { $mask = '255.255.255.0' } elseif ($mask -notmatch '(\d{1,3}\.){3}\d{1,3}') { Throw 'Check Mask format.' }
        if (!$gateway) { Write-Warning 'No Gateway specified.' } elseif ($gateway -notmatch '(\d{1,3}\.){3}\d{1,3}') { Throw 'Check Gateway format.' }
        if (!$dns1) { Write-Warning 'No primary DNS specified.' } elseif ($dns1 -notmatch '(\d{1,3}\.){3}\d{1,3}') { Throw 'Check primary DNS format.' }
        if (!$dns2) { Write-Warning 'No secondary DNS specified.' } elseif ($dns2 -notmatch '(\d{1,3}\.){3}\d{1,3}') { Throw 'Check secondary DNS format.' }
    }

    $all = gwmi win32_networkadapter
    if ($all | ? {$_.servicename -match '^e1(?:.*)express$'}) {
        [array]$ethernet = gwmi win32_networkadapterconfiguration | ? {$_.servicename -match '^e1(?:.*)express$'}
        [array]$NetConnectionID = $all | ? {$_.servicename -match '^e1(?:.*)express$'} | % {$_.NetConnectionID}
        [array]$InterfaceName = $all | ? {$_.servicename -match '^e1(?:.*)express$'} | % {$_.Name}
    } else {
        # OR MAYBE: | ? {$_.physicaladapter -and ($_.name -match 'ethernet' -or $_.description -match 'ethernet' -or $_.netconnectionid -match 'ethernet')}
        [array]$ethernet = gwmi win32_networkadapterconfiguration | ? {$_.description -notmatch 'wan miniport|microsoft isatap adapter|bluetooth|juniper|ras async adapter|wireless|virtual|apple|miniport|tunnel|debug|advanced-n|wireless-n|ndis'}
        [array]$NetConnectionID = $all | ? {$_.description -notmatch 'wan miniport|microsoft isatap adapter|bluetooth|juniper|ras async adapter|wireless|virtual|apple|miniport|tunnel|debug|advanced-n|wireless-n'} | % {$_.NetConnectionID}
        [array]$InterfaceName = $all | ? {$_.description -notmatch 'wan miniport|microsoft isatap adapter|bluetooth|juniper|ras async adapter|wireless|virtual|apple|miniport|tunnel|debug|advanced-n|wireless-n'} | % {$_.Name}
    }

    if (!$dhcp) {
        $static = $ethernet | % {
            $_.EnableStatic($ip, $mask)
            $_.SetGateways($gateway)
        }
        $NetConnectionID | % {
            $null = netsh interface ipv4 set dns name=$_ source=static address=$dns1 primary validate=no
            $null = netsh interface ipv4 add dnsserver name=$_ address=$dns2 index=2 validate=no
        }
    } elseif ($dhcp) {
        $NetConnectionID | % {
            netsh interface ip set address $_ dhcp
            $null = netsh interface ip set dns $_ dhcp
        }
    }

    if ($static) {
        $ReturnValue = @()
        $ReturnValue += $static | % {
            Switch ($_.ReturnValue) {
                0   { 'Successful completion' }
                1   { 'no reboot required' }
                64  { 'Successful completion' }
                65  { 'reboot required' }
                66  { 'Method not supported on this platform' }
                67  { 'Unknown failure' }
                68  { 'Invalid subnet mask' }
                69  { 'An error occurred while processing an Instance that was returned' }
                70  { 'Invalid input parameter' }
                71  { 'More than 5 gateways specified' }
                72  { 'Invalid IP  address' }
                73  { 'Invalid gateway IP address' }
                74  { 'An error occurred while accessing the Registry for the requested information' }
                75  { 'Invalid domain name' }
                76  { 'Invalid host name' }
                77  { 'No primary/secondary WINS server defined' }
                78  { 'Invalid file' }
                79  { 'Invalid system path' }
                80  { 'File copy failed' }
                81  { 'Invalid security parameter' }
                82  { 'Unable to configure TCP/IP service' }
                83  { 'Unable to configure DHCP service' }
                84  { 'Unable to renew DHCP lease' }
                85  { 'Unable to release DHCP lease' }
                86  { 'IP not enabled on adapter' }
                87  { 'IPX not enabled on adapter' }
                88  { 'Frame/network number bounds error' }
                89  { 'Invalid frame type' }
                90  { 'Invalid network number' }
                91  { 'Duplicate network number' }
                92  { 'Parameter out of bounds' }
                93  { 'Access denied' }
                94  { 'Out of memory' }
                95  { 'Already exists' }
                96  { 'Path' }
                97  { 'file or object not found' }
                98  { 'Unable to notify service' }
                100 { 'Unable to notify DNS service' }
                default { 'Interface not configurable' }
            }
        }

        $ReturnValue
        Write-Host ''
    }

    foreach ($name in $InterfaceName) {
        [string]$dnstype = gwmi win32_networkadapter | ? {$_.description -eq $name} | % {netsh interface ipv4 show dns $_.netconnectionid}
        if ($dnstype -match 'static') {
            $dns = [Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | ? {$_.description -eq $name} | % {$_.GetIPProperties()} | % {$_.dnsaddresses} | % {[string]$_}
        } else {
            $dns = ''
        }
        Write-Host "Name:    $name"
        Write-Host "IP:      $([Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | ? {$_.description -eq $name} | % {$_.GetIPProperties()} | % {$_.unicastaddresses} | ? {$_.PrefixOrigin -eq 'Manual' } | % {[string]$_.address})"
        Write-Host "Gateway: $([Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | ? {$_.description -eq $name} | % {$_.GetIPProperties()} | % {$_.gatewayaddresses} | % {[string]$_.address})"
        Write-Host "DHCP:    $([Net.NetworkInformation.NetworkInterface]::GetAllNetworkInterfaces() | ? {$_.description -eq $name} | % {$_.GetIPProperties()} | % {$_.dhcpserveraddresses} | % {[string]$_})"
        Write-Host "DNS:     $dns"
        Write-Host ''
    }
}
