
# get snmp description and name

function Get-SNMPData ($device) {

    begin {
        $snmp = New-Object -ComObject olePrn.OleSNMP
        $ping = New-Object System.Net.NetworkInformation.Ping
    }

    process {
        $name = $desc = $addr = $ip = '-'

        try {
            $result = $ping.Send($device)
        } catch {
            $result = $null
        }

    
        if ($result.Status -eq 'Success') {
            $ip = $result.Address.ToString()

            $snmp.open($ip, 'public', 2, 3000)

            try {
                $name = $snmp.Get('.1.3.6.1.2.1.1.5.0')
                $desc = $snmp.Get('.1.3.6.1.2.1.1.1.0')
                $addr = ($snmp.Gettree('.1.3.6.1.2.1.4.20.1.1') | ? {$_ -match '(?:[^\.]{1,3}\.){3}[^\.]{1,3}$' -and $_ -notmatch '127\.0\.0\.1'} | % {$i = $_.split('.'); "$($i[-4]).$($i[-3]).$($i[-2]).$($i[-1])"}) -join ';'
            } catch {}
        }

        [pscustomobject]@{
            Device = $device
            IP = $ip
            SNMPName = $name
            SNMPDescription = $desc
            SNMPAddresses = $addr
        }
    }
}
