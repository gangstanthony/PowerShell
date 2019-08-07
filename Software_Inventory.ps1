<#
==============================================================================
 SOFTWARE INVENTORY - ALT CREDENTIALS
==============================================================================
 Created: [07/24/2014]
 Author: Ethan Bell
 Arguments:
==============================================================================
 Modified: 
 Modifications:
==============================================================================
 Purpose: To retrieve a list of installed applications on a remote computer
 Options: 
==============================================================================
Notes:
    Based on the original work by Aman Dhally, posted at  
    http://powershell.com/cs/media/p/18510.aspx  
    V3 - 7/24/2014 - Added prompt for remote computer name and credentials
    V2 - 7/17/2013 - Eliminated redundant calls and cleaned up HTML, Bob McCoy    
    V1 - 8/21/2012 - Aman Dhally  
==============================================================================
#>

#variables  
$DebugPreference = "SilentlyContinue"  
$UserName = (Get-Item Env:\USERNAME).Value
$origComputerName = (Get-Item Env:\COMPUTERNAME).Value
$ComputerName = Read-Host 'What is the computer name?'
$FileName = (Join-Path -Path ((Get-ChildItem Env:\USERPROFILE).value) -ChildPath $ComputerName) + ".html"  
  
# HTML Style  
$style = @"  
<style>  
BODY{background-color:Lavender}  
TABLE{border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse}  
TH{border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color:thistle}  
TD{border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color:PaleGoldenrod}  
</style>  
"@  
  
# Remove old report if it exists  
if (Test-Path -Path $FileName)   
{  
    Remove-Item $FileName  
    Write-Debug "$FileName removed"  
}  

# recommend not using win32_product. check comments here: https://github.com/gangstanthony/PowerShell/blob/master/Get-InstalledApps.ps1
# Run command   
Get-WmiObject win32_Product -ComputerName $ComputerName |   
    Select Name,Version,PackageName,Installdate,Vendor |   
    Sort Installdate -Descending |   
        ConvertTo-Html -Head $style -PostContent "Report generated on $(get-date) by $UserName on computer $origComputerName" -PreContent "<h1>Computer Name: $ComputerName<h1><h2>Software Installed</h2>" -Title "Software Information for $ComputerName" |
        Out-File -FilePath $FileName  
                                   
# View the file   
    Write-Debug "File saved $FileName"
    Invoke-Item -Path $FileName
  
# Finish
