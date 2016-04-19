# gwmi win32_volume is faster than win32_logicaldisk

# https://4sysops.com/archives/query-free-disk-space-details-of-remote-computers-using-powershell/

function diskfree {
    Param (
        [parameter(ValueFromPipeline=$true,ValueFromPipelineByPropertyName=$true)]
        [string[]]$ComputerName = $env:computername
    )

    foreach ($Computer in $ComputerName) {
        Write-Host "Working on $Computer"
        if (Test-Connection -ComputerName $Computer -Count 1 -ea 0) {
            $VolumesInfo = Get-WmiObject Win32_Volume -ComputerName $Computer -Filter "drivetype = '2' OR drivetype = '3'"
            foreach ($Volume in $VolumesInfo) {
                $Capacity = [System.Math]::Round(($Volume.Capacity/1GB),2)
                $FreeSpace = [System.Math]::Round(($Volume.FreeSpace/1GB),2)
                $UsedSpace = [System.Math]::Round(($Capacity - $FreeSpace),2)
                $PctFreeSpace = [System.Math]::Round(($Volume.FreeSpace/$Volume.Capacity)*100,2)
                [pscustomobject]@{
                    ComputerName = $computer
                    DriveName = $Volume.Caption
                    DriveType = $Volume.DriveType
                    CapacityGB = $Capacity
                    FreeSpaceGB = $FreeSpace
                    UsedSpaceGB = $UsedSpace
                    PercentFreeGB = $PctFreeSpace
                }
            }
        } else {
            Write-Host "$Computer is not reachable"
            [pscustomobject]@{
                ComputerName = $computer
                DriveName = '-'
                DriveType = '-'
                CapacityGB = '-'
                FreeSpaceGB = '-'
                UsedSpaceGB = '-'
                PercentFreeGB = '-'
            }
        }
    }
}
