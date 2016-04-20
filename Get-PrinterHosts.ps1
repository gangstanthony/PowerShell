
# need admin rights
# if you include USB printers on workstations, it picks up peoples home usb printers as well...
# also including shared printers may include home printers

function Get-PrinterHosts {
    Param (
        [string]$comp = $env:COMPUTERNAME
    )
    
    if (!$comp) { throw 'No comps.' }
    
    $ping = New-Object System.Net.NetworkInformation.Ping
    try {
        $result = $ping.Send($comp)
    } catch {
        $result = $null
    }

    if ($result.Status -eq 'Success') {
        $printers = Get-WmiObject Win32_Printer -ComputerName $comp | select name, sharename, systemname, portname, shared, printerpapernames, capabilitydescriptions, location, comment, drivername
        
        # get the ip address
        $ip = $result.Address.ToString()

        foreach ($printer in $printers) {
            [pscustomobject]@{
                Computer               = $comp.ToUpper()
                ComputerIP             = $ip
                Printer                = $printer.Name.ToUpper()
                ShareName              = $(try { $printer.ShareName.ToUpper() } catch { $null })
                SystemName             = $(if ($printer.SystemName.StartsWith('\')) {$printer.SystemName.Substring(2).ToUpper()} else {$printer.SystemName.ToUpper()})
                Location               = $(try { $printer.Location } catch { $null })
                Comment                = $(try { $printer.Comment } catch { $null })
                DriverName             = $(try { $printer.DriverName } catch { $null })
                Port                   = $printer.PortName
                Shared                 = $printer.Shared
                PrinterPaperNames      = $printer.PrinterPaperNames
                CapabilityDescriptions = $printer.CapabilityDescriptions
            }
        }
    } else {
        [pscustomobject]@{
            Computer               = $comp.ToUpper()
            ComputerIP             = '-'
            Printer                = '-'
            ShareName              = '-'
            SystemName             = '-'
            Location               = '-'
            Comment                = '-'
            DriverName             = '-'
            Port                   = '-'
            Shared                 = '-'
            PrinterPaperNames      = '-'
            CapabilityDescriptions = '-'
        }
    }
}
