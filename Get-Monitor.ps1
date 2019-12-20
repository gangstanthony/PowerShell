# https://www.reddit.com/r/PowerShell/comments/4qbvbp/get_serial_number_make_and_model_from_attached/

# alternative
# $Monitors = Get-WmiObject -Class Win32_PnPEntity | Where-Object Service -eq "Monitor"
# https://www.reddit.com/r/PowerShell/comments/6io2ws/check_how_many_monitors_are_connected/

function Get-Monitor {
    [CmdletBinding()]
    param (
        [Parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [String[]]$ComputerName = $env:ComputerName
    )
  
    # List of Manufacture Codes that could be pulled from WMI and their respective full names. Used for translating later down.
    $ManufacturerHash = @{
        AAC = 'AcerView'
        ACR = 'Acer'
        AOC = 'AOC'
        AIC = 'AG Neovo'
        APP = 'Apple Computer'
        AST = 'AST Research'
        AUO = 'Asus'
        BNQ = 'BenQ'
        CMO = 'Acer'
        CPL = 'Compal'
        CPQ = 'Compaq'
        CPT = 'Chunghwa Pciture Tubes, Ltd.'
        CTX = 'CTX'
        DEC = 'DEC'
        DEL = 'Dell'
        DPC = 'Delta'
        DWE = 'Daewoo'
        EIZ = 'EIZO'
        ELS = 'ELSA'
        ENC = 'EIZO'
        EPI = 'Envision'
        FCM = 'Funai'
        FUJ = 'Fujitsu'
        FUS = 'Fujitsu-Siemens'
        GSM = 'LG Electronics'
        GWY = 'Gateway 2000'
        HEI = 'Hyundai'
        HIT = 'Hyundai'
        HSL = 'Hansol'
        HTC = 'Hitachi/Nissei'
        HWP = 'HP'
        IBM = 'IBM'
        ICL = 'Fujitsu ICL'
        IVM = 'Iiyama'
        KDS = 'Korea Data Systems'
        LEN = 'Lenovo'
        LGD = 'Asus'
        LPL = 'Fujitsu'
        MAX = 'Belinea' 
        MEI = 'Panasonic'
        MEL = 'Mitsubishi Electronics'
        MS_ = 'Panasonic'
        NAN = 'Nanao'
        NEC = 'NEC'
        NOK = 'Nokia Data'
        NVD = 'Fujitsu'
        OPT = 'Optoma'
        PHL = 'Philips'
        REL = 'Relisys'
        SAN = 'Samsung'
        SAM = 'Samsung'
        SBI = 'Smarttech'
        SGI = 'SGI'
        SNY = 'Sony'
        SRC = 'Shamrock'
        SUN = 'Sun Microsystems'
        SEC = 'Hewlett-Packard'
        TAT = 'Tatung'
        TOS = 'Toshiba'
        TSB = 'Toshiba'
        VSC = 'ViewSonic'
        ZCM = 'Zenith'
        UNK = 'Unknown'
        _YV = 'Fujitsu'
    }

    # Takes each computer specified and runs the following code:
    foreach ($Computer in $ComputerName) {
        
        # Grabs the Monitor objects from WMI
        $Monitors = Get-WmiObject -Namespace root\WMI -Class WMIMonitorID -ComputerName $Computer -ErrorAction SilentlyContinue

        # Takes each monitor object found and runs the following code:
        foreach ($Monitor in $Monitors) {
            
            # Grabs respective data and converts it from ASCII encoding and removes any trailing ASCII null values
            $Mon_Model = try{ ([System.Text.Encoding]::ASCII.GetString($Monitor.UserFriendlyName)).Replace([string][char]0x0000, '') }catch{}
            $Mon_Serial_Number = ([System.Text.Encoding]::ASCII.GetString($Monitor.SerialNumberID)).Replace([string][char]0x0000, '')
            $Mon_Attached_Computer = ($Monitor.PSComputerName).Replace([string][char]0x0000, '')
            $Mon_Manufacturer = ([System.Text.Encoding]::ASCII.GetString($Monitor.ManufacturerName)).Replace([string][char]0x0000, '')

            <# Filters out "non monitors". Place any of your own filters here. These two are all-in-one computers with built in displays. I don't need the info from these.
            if ($Mon_Model -like '*800 AIO*' -or $Mon_Model -like '*8300 AiO*') {
                break
            }#>

            # Sets a friendly name based on the hash table above. If no entry found sets it to the original 3 character code
            $Mon_Manufacturer_Friendly = $ManufacturerHash.$Mon_Manufacturer
            if ($Mon_Manufacturer_Friendly -eq $null) {
                $Mon_Manufacturer_Friendly = $Mon_Manufacturer
            }

            # Creates a custom monitor object and fills it with 4 NoteProperty members and the respective data
            [pscustomobject]@{
                Computer = $Mon_Attached_Computer
                Manufacturer = $Mon_Manufacturer_Friendly
                Model = $Mon_Model
                SerialNumber = $Mon_Serial_Number
                YearOfManufacture = $Monitor.YearOfManufacture
                WeekOfManufacture = $Monitor.WeekOfManufacture
            }
        }
    }
}
