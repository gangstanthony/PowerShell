Function Get-FailingDrive {
<#
.SYNOPSIS
    Checks for any potentially failing drives and reports back drive information.
    
.DESCRIPTION
    Checks for any potentially failing drives and reports back drive information. This only works
    against local hard drives using SMART technology. Reason values and their meanings can be found
    here: http://en.wikipedia.org/wiki/S.M.A.R.T#Known_ATA_S.M.A.R.T._attributes
    
.PARAMETER Computer
    Remote or local computer to check for possible failed hard drive.
    
.PARAMETER Credential
    Provide alternate credential to perform query.

.NOTES
    Author: Boe Prox
    Version: 1.0

http://learn-powershell.net

.EXAMPLE
    Get-FailingDrive
    
    WARNING: ST9320320AS ATA Device may fail!


    MediaType       : Fixed hard disk media
    InterFace       : IDE
    DriveName       : ST9320320AS ATA Device
    Reason          : 1
    SerialNumber    : 202020202020202020202020533531584e5a4d50
    FailureImminent : True
    
    Description
    -----------
    Command ran against the local computer to check for potential failed hard drive.
#>
    [cmdletbinding()]
    Param (
        [parameter(ValueFromPipeline=$True,ValueFromPipelineByPropertyName=$True)]
        [string[]]$Computername,
        [parameter()]
        [System.Management.Automation.PSCredential]$Credential
    )
    Begin {
        $queryhash = @{}
        $BadDriveHash = @{}
    }
    Process {
        ForEach ($Computer in $Computername) {
            If ($PSBoundParameters['Computer']) {
                $queryhash['Computername'] = $Computer
                $BadDriveHash['Computername'] = $Computer
            } Else {
                $queryhash['Computername'] = $Env:Computername
                $BadDriveHash['Computername'] = $Env:Computername            
            }
            If ($PSBoundParameters['Credential']) {
                $queryhash['Credential'] = $Credential
                $BadDriveHash['Credential'] = $Credential
            }            
            Write-Verbose "Creating SplatTable"
            $queryhash['NameSpace'] = 'root\wmi'
            $queryhash['Class'] = 'MSStorageDriver_FailurePredictStatus'
            $queryhash['Filter'] = "PredictFailure='False'"
            $queryhash['ErrorAction'] = 'Stop'
            $BadDriveHash['Class'] = 'win32_diskdrive'
            $BadDriveHash['ErrorAction'] = 'Stop'
            [regex]$regex = "(?<DriveName>\w+\\[A-Za-z0-9_]*)\w+"
            Try {
                Write-Verbose "Checking for failed drives"
                Get-WmiObject @queryhash | ForEach {
                    $drive = $regex.Matches($_.InstanceName) | ForEach {$_.Groups['DriveName'].value}
                    Write-Verbose "Gathering more information about failing drive"
                    $BadDrive = gwmi @BadDriveHash | Where {$_.PNPDeviceID -like "$drive*"}
                    If ($BadDrive) {
                        Write-Warning "$($BadDriveHash['Computername']): $($BadDrive.Model) may fail!"
                        New-Object PSObject -Property @{
                            DriveName = $BadDrive.Model
                            FailureImminent  = $_.PredictFailure
                            Reason = $_.Reason
                            MediaType = $BadDrive.MediaType
                            SerialNumber = $BadDrive.SerialNumber
                            InterFace = $BadDrive.InterfaceType
                            Partitions = $BadDrive.Partitions
                            Size = $BadDrive.Size
                            Computer = $BadDriveHash['Computername']
                        }
                    }
                }
            } Catch {
                Write-Warning "$($Error[0])"
            }
        }
    }
}