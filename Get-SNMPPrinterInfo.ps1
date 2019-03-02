# other powershell snmp information
# https://solvedbypowershell.blogspot.com/2014/12/powershell-using-snmp-for-html-network.html
# https://www.powershellgallery.com/packages/Proxx.SNMP/1.0.1.2/Content/Invoke-SnmpGet.ps1
# https://www.powershellgallery.com/packages/Proxx.SNMP/1.0.0.1/Content/Invoke-SnmpWalk.ps1
# https://exchange.nagios.org/directory/Plugins/Hardware/Printers/SNMP-Printer-Check/details
# https://www.powershellgallery.com/packages/Proxx.SNMP/1.1.1.4
# https://www.reddit.com/r/PowerShell/comments/77ls36/printer_page_counter_from_print_server/
# https://gallery.technet.microsoft.com/Get-PrintStatistics-a6bb8323
# https://gallery.technet.microsoft.com/scriptcenter/Script-to-generate-print-84bdcf69

function Get-SNMPPrinterInfo {
    param (
        [string[]]$printers
    )

    begin {
        $snmp = New-Object -ComObject olePrn.OleSNMP
        $ping = New-Object System.Net.NetworkInformation.Ping
    }

    process {
        foreach ($printer in $printers) {
            try {
                $result = $ping.Send($printer)
            } catch {
                $result = $null
            }

            if ($result.Status -eq 'Success') {
                # get the ip address
                $printerip = $result.Address.ToString()
            
                # OPEN SNMP CONNECTION TO PRINTER
                $snmp.open($printerip, 'public', 2, 3000)

                # MODEL
                try { $model = $snmp.Get('.1.3.6.1.2.1.25.3.2.1.3.1') } catch { $model = $null }

                # IF IT HAS A MODEL NAME...
                if ($model) {
                
                    # DESCRIPTION
                    try { $sysdescr0 = $snmp.Get('.1.3.6.1.2.1.1.1.0') } catch { $sysdescr0 = $null }

                    # COLOR
                    # might want to check on this one
                    try { if ($snmp.Get('.1.3.6.1.2.1.43.11.1.1.6.1.2') -match 'Toner|Cartridge') { $color = 'Yes' } else { $color = 'No' } } catch { $color = 'No' }

                    # TRAYS
                    try { $trays = $($snmp.GetTree('.1.3.6.1.2.1.43.8.2.1.13') | ? {$_ -notlike 'print*'}) -join ';' } catch { $trays = $null }

                    # COMMENT
                    try { $comment = $snmp.Get('.1.3.6.1.2.1.1.6.0') } catch { $comment = $null }

                    ##### FEATURES, NAME
                    $features = $null
                    $name = $null
                    switch -Regex ($model) {
                        '^sharp' {
                            try { $features = $($snmp.GetTree('.1.3.6.1.4.1.2385.1.1.3.2.1.3') | ? {$_ -notlike '.*'}) -join ';' } catch { $features = $null }
                            try { $name = $snmp.Get('.1.3.6.1.4.1.1536.1.3.5.4.2.0').toupper() } catch { $name = $null }
                        }
                        '^canon' {
                            try { $name = $snmp.Gettree('.1.3.6.1.4.1.1602.1.3.3.1.1.2.1.1.10.134') | ? {$_ -notlike '.*'} | select -f 1 | % {$_.toupper()} } catch { $name = $null }
                        }
                        '^zebra' {
                            try { $name = $snmp.Get('.1.3.6.1.4.1.10642.1.4.0').toupper() } catch { $name = $null }
                        }
                        '^lexmark' {
                            try { $name = $snmp.Get('.1.3.6.1.4.1.641.1.5.7.6.0').toupper() } catch { $name = $null }
                        }
                        '^ricoh' {
                            try { $name = $snmp.Get('.1.3.6.1.4.1.367.3.2.1.7.3.5.1.1.2.1.1').toupper() } catch { $name = $null }
                        }
                        '^hp' {
                            try { $name = $snmp.Get('.1.3.6.1.4.1.11.2.4.3.5.46.0').toupper() } catch { $name = $null }
                        }
                        default {
                            #'features', 'name' | % {Clear-Variable $_}
                            $features = $null
                            $name = $null
                        }
                    }
                    #if ($model -like 'SHARP*') {}
                
                    # ADDRESS
                    try { $addr = ($snmp.Gettree('.1.3.6.1.2.1.4.20.1.1') | ? {$_ -match '(?:[^\.]{1,3}\.){3}[^\.]{1,3}$' -and $_ -notmatch '127\.0\.0\.1'} | % {$ip = $_.split('.'); "$($ip[-4]).$($ip[-3]).$($ip[-2]).$($ip[-1])"}) -join ';' } catch { $addr = $null }

                    [pscustomobject]@{
                        Machine = $printer
                        IP = $printerip
                        Name = $name
                        Model = $model
                        Comment = $comment
                        Color = $color
                        Trays = $trays
                        Features = $features
                        SystemDescription = $sysdescr0
                        Addresses = $addr
                    }
                }
            } else {
                Write-Warning "Machine '$printer' may be offline."
            }
        }
    }
}
