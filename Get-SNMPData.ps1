
# get snmp description and name

function Get-SNMPData {
    param (
        [string]$ip
    )

    begin {
        $ping = New-Object System.Net.NetworkInformation.Ping
        $snmp = New-Object -ComObject olePrn.OleSNMP
    }

    process {
        $info = [pscustomobject]@{
            IP = $ip
            Name = ''
            Description = ''
            Addresses = ''
            Online = $false
        }

        if ($ping.Send($ip).Status -eq 'Success') {
            $info.Online = $true

            $snmp.Open($ip, 'public', 2, 3000)

            try {
                $info.Name = $snmp.Get('.1.3.6.1.2.1.1.5.0')
                $info.Description = $snmp.Get('.1.3.6.1.2.1.1.1.0')
                $info.Addresses = ($snmp.Gettree('.1.3.6.1.2.1.4.20.1.1') | ? {$_ -match '(?:[^\.]{1,3}\.){3}[^\.]{1,3}$' -and $_ -notmatch '127\.0\.0\.1'} | % {$i = $_.split('.'); "$($i[-4]).$($i[-3]).$($i[-2]).$($i[-1])"}) -join ';'
            } catch {}
        }

        Write-Output $info
    }
}
