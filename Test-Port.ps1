# https://www.reddit.com/r/PowerShell/comments/47hvmx/how_to_tell_if_ip_address_is_a_printer/
# https://www.wikiwand.com/en/List_of_TCP_and_UDP_port_numbers
#  515 - printer # Line Printer Daemon (LPD), print service
#  135 - windows # Microsoft EPMAP (End Point Mapper), also known as DCE/RPC Locator service,[17] used to remotely manage services including DHCP server, DNS server and WINS. Also used by DCOM
#   21 - ftp
#   22 - ssh
#   23 - telnet
#   25 - smtp
#   53 - dns server?
#   80 - http
#   88 - kerberos auth server?
#  161 - snmp
#  162 - snmp trap
#  220 - imap
#  443 - https
#  445 - Microsoft-DS Active Directory, Windows SMB file sharing
#  464 - Kerberos Change/Set password
#  636 - Lightweight Directory Access Protocol over TLS/SSL (LDAPS)
# 1433 - SQL server

# BETTER VERSION, but i couldn't get it to work properly
# https://jonlabelle.com/snippets/view/powershell/powershell-script-to-scan-open-ports

function Test-Port {
    param (
        $ip = '127.0.0.1',
        $port = '515'
    )

    begin {
        $tcp = New-Object Net.Sockets.TcpClient
    }
    
    process {
        try {
            $tcp.Connect($ip, $port)
        } catch {}

        if ($tcp.Connected) {
            $tcp.Close()
            $open = $true
        } else {
            $open = $false
        }

        [pscustomobject]@{
            IP = $ip
            Port = $port
            Open = $open
        }
    }
}
