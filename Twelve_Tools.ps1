<#
	.SYNOPSIS
		This is a simple Powershell script to provide a set of 12 tools to make our life easy.

	.DESCRIPTION
		You can use the below key words to get the corresponding tools
		 R - To restart any remote server
		 I - To do IISRESET on a remote web server
		 W - To do WLBS query on any web servers for Windows Load Balancing status
		 J - To get the status of SQL Job starting with some string we prefer (You will be prompted to give Server name and Job name string)
		 V - To start a specific service on a remote machine (Make sure to provide the 'Service Name'properly- as shown in the properties page of the services)
		 C - To stop a specific service on a remote machine (Make sure to provide the 'Service Name'properly- as shown in the properties page of the services)
		 T - To get the status of scheduled tasks running on a remote machine (You will be prompted for Server Name)
		 L - To log off a specific Terminal Service session to a remote machine (You will be prompted for Server Name)
		 S - To get the Serial Number of a remote machine (You will be prompted for Server Name)
		 E - To Exit

	.NOTES
		You need an administrative account with domain privileges and SQL access to use this tool.
		Make sure to exit this application / Lock your computer, when you are about to leave for the day- to avoid any possible security problems.
		Much coding is not done to handle all the errors and exceptions, so you might receive errors in non standard scenarios.
		This program uses tools like rcmd.exe, terminal service powershell modules which need to be installed separately on clients and local machines accordingly.

	.LINK
		http://technet.microsoft.com/hi-in/scriptcenter/powershell(en-us).aspx
		http://www.powershellcommunity.org/
		http://en.wikipedia.org/wiki/Windows_PowerShell
#>


######################################## DISCLAIMER ###################################
# The free software programs provided by Shaiju J.S may be freely distributed,     #### 
# provided that no charge above the cost of distribution is levied, and that the ######
# disclaimer below is always attached to it.                                     ######
# The programs are provided as is without any guarantees or warranty.            ###### 
# Although the author has attempted to find and correct any bugs in the free software #
# programs, the author is not responsible for any damage or losses of any kind caused #
# by the use or misuse of the programs. The author is under no obligation to provide ##
# support, service, corrections, or upgrades to the free software programs. ########### 
#######################################################################################


write-host "###########################################################################" -ForegroundColor DarkCyan
write-host "###################### TOOL KIT USING POWERSHELL ##########################" -ForegroundColor Yellow
write-host "################### 12 TOOLS TO AVOID RDP SESSIONS ########################" -ForegroundColor Green
write-host "####################### USE ADMIN ACCOUNT TO START ########################" -ForegroundColor Yellow
write-host "## RM Tool Version 2.0.0 #### By Shaiju J.S ########## 02 Jan 2012 ########" -ForegroundColor Green
write-host "###########################################################################" -ForegroundColor DarkCyan

#######################################################################################
$a = (Get-Host).PrivateData
$a.WarningBackgroundColor = "red"
$a.WarningForegroundColor = "white"
#To change your screen or background color set the following:
#$Host.Ui.RawUi.BackGroundColor = "Blue"
# To change your test or foreground color set the following:
#$Host.Ui.RawUi.ForeGroundColor = "Yellow"

gc env:computername 
Get-Date 

function Read-Choice {
	PARAM([string]$message, [string[]]$choices, [int]$defaultChoice=12, [string]$Title=$null )
  	$Host.UI.PromptForChoice( $caption, $message, [Management.Automation.Host.ChoiceDescription[]]$choices, $defaultChoice )
}

switch(Read-Choice "Use Shortcut Keys:[]" "&Restart","&IISRESET","&WLBS Status","&Job- SQL","&V-Start Service","&C-Stop Service","&Task- Scheduled","&Log-off TS","&Basic Computer Inventory","&Application List","&Process- Remote","&Event- Logs","&Quit"){
	0 { 
		Write-Host "You have selected the option to restart a server" -ForegroundColor Yellow
		$ServerName = Read-Host "Enter the name of the server to be restarted"
		if (Test-connection $ServerName) {
			Get-Date
			write-host “$ServerName is reachable”
			Write-Host "$ServerName is getting restarted"
			Get-Date 
			restart-computer -computername $ServerName -Force 
			Write-Host "Starting continuous ping to test the status"  
			Test-Connection -ComputerName $ServerName -Count 100 | select StatusCode 		
			Start-Sleep -s 300
			Write-Host "Here is the last reboot time: " 
			$wmi=Get-WmiObject -class Win32_OperatingSystem -computer $ServerName 
			$LBTime=$wmi.ConvertToDateTime($wmi.Lastbootuptime)
			$LBTime
			
		}
		else {
				Get-Date
				write-host “$ServerName is not reachable, please check this manually”
				exit
		}

	} 
	1 { 
		Write-Host "You have selected the option to do IISRESET" -ForegroundColor Yellow
		$Server1 = Read-Host "Enter the server name on which iis need to be reset"
		rcmd \\$Server1 iisreset
	} 
	2 {
		Write-Host "You have selected the option to check WLBS status" -ForegroundColor Yellow
		$Server2 = Read-host "Enter the remote computer name" 
		rcmd \\$Server2 wlbs query
		$opt = Read-Host "Do you want to stop/start wlbs on $Server2 (Y/N)"
		if ($opt -eq 'Y') {
			$opt0 = Read-Host "S- To start X- To stop)"
			if ($opt0 -eq 'S') {
				rcmd \\$Server2 wlbs resume
				rcmd \\$Server2 wlbs start
			}
			else {
				if ($opt0 -eq 'X') {
					rcmd \\$Server2 wlbs stop
					rcmd \\$Server2 wlbs suspend
				}
				else {
					exit
				}
				exit
			}
		}
		else {
			exit
		}
	} 
	3 { 
		Write-Host "You have selected the option to get the status of SQL job" -ForegroundColor Yellow
		write-host "Hope you are logged in with an account having SQL access privilege"
		[System.Reflection.Assembly]::LoadWithPartialName(‘Microsoft.SqlServer.SMO’) | out-null
		$instance = Read-Host "Enter the server name"
		$j = Read-Host "Job names starting with....."							
		$s = New-Object (‘Microsoft.SqlServer.Management.Smo.Server’) $instance
		$s.JobServer.Jobs |Where-Object {$_.Name -ilike "$j*"}| SELECT NAME, LASTRUNOUTCOME, LASTRUNDATE 
	} 
	4 {
		Write-Host "You have selected the option to start a service" -ForegroundColor Yellow
		$Server6 = Read-host "Enter the remote computer name"
		Get-Service * -computername $Server6 | where {$_.Status -eq "Stopped"} | Out-GridView 
		$svc6 = Read-host "Enter the name of the service to be started"
		(Get-WmiObject -computer $Server6 Win32_Service -Filter "Name='$svc6'").InvokeMethod("StartService",$null)
	}
	5 {
		Write-Host "You have selected the option to stop a service" -ForegroundColor Yellow
		$Server7 = Read-host "Enter the remote computer name"
		Get-Service * -computername $Server7 | where {$_.Status -eq "Running"} | Out-GridView 
		$svc7 = Read-host "Enter the name of the service to be stopped"
		(Get-WmiObject -computer $Server7 Win32_Service -Filter "Name='$svc7'").InvokeMethod("StopService",$null)
	}
	6 {
		Write-Host "You have selected the option to get the scheduled task status list" -ForegroundColor Yellow
		$Server8 = Read-host "Enter the remote computer name"
		schtasks /query /S $Server8 /FO TABLE /V | Out-GridView 	
	}
	7 {
		Write-Host "You have selected the option to list and log off terminal service sessions" -ForegroundColor Yellow
		Import-Module PSTerminalServices
		$server9 = Read-Host "Enter Remote Server Name"
		$session = Get-TSSession -ComputerName $server9 | SELECT "SessionID","State","IPAddress","ClientName","WindowStationName","UserName"  
		$session
		$s = Read-Host "Enter Session ID, if you want to log off any session"
		Get-TSSession -ComputerName $server9 -filter {$_.SessionID -eq $s} | Stop-TSSession –Force
	}
	8 {
		Write-Host "You have selected the option to get basic computer inventory" -ForegroundColor Yellow
		$server8 = Read-Host "Enter Remote Server Name"
		Get-WMIObject -Class "Win32_BIOS" -Computer $server8 | select SerialNumber
		get-wmiobject -computername  $server8 win32_computersystem
		Get-WmiObject win32_logicaldisk -ComputerName $server8 | select DeviceID, size, FreeSpace
	}
	9 {
		Write-Host "The option to List the Applications installed on a remote machine" -ForegroundColor Yellow
		# This script will Query the Uninstall Key on a computer specified in $computername and list the applications installed there 
		# $Branch contains the branch of the registry being accessed 
		$computername= Read-Host "Enter the computer name"
		# Branch of the Registry 
		$Branch='LocalMachine' 
		# Main Sub Branch you need to open 
		$SubBranch="SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall" 
		$registry=[microsoft.win32.registrykey]::OpenRemoteBaseKey('Localmachine',$computername) 
		$registrykey=$registry.OpenSubKey($Subbranch) 
		$SubKeys=$registrykey.GetSubKeyNames() 
		# Drill through each key from the list and pull out the value of 
		# “DisplayName” – Write to the Host console the name of the computer 
		# with the application beside it
		Foreach ($key in $subkeys) { 
		    $exactkey=$key 
		    $NewSubKey=$SubBranch+"\\"+$exactkey 
		    $ReadUninstall=$registry.OpenSubKey($NewSubKey) 
		    $Value=$ReadUninstall.GetValue("DisplayName") 
		    WRITE-HOST $Value
		} 
	}
	10 {
	Write-Host "You have selected the option to get process details of a remote server" -ForegroundColor Yellow
	$server12 = Read-Host "Enter the remote machine name"
	Get-Process -ComputerName $server12 | Out-GridView 
	}
	11 {
	Write-Host "You have selected the option to get the event log details of a server" -ForegroundColor Yellow
	$server14 = Read-Host "Enter server name"
	[int]$n = Read-Host "Last how many Days?"
	$start1 = (Get-Date).addDays(-[int]$n)   
	$start2 = (Get-Date)
	$opt3 = Read-Host "Do you want to save it to a notepad (Y/N)?" 
		if ($opt3 -eq 'Y') {
		get-eventlog -logname System -EntryType Error -after $start1 -before $start2 -ComputerName $server14 > C:\Scripts\event.txt
		Invoke-Item C:\Scripts\event.txt 
		}
		else {
		get-eventlog -logname System -EntryType Error -after $start1 -before $start2 -ComputerName $server14 | Out-GridView
		}
	}
	12 {
		Write-Host "You have selected the option to exit the tool, Thank you for using this !!!" -ForegroundColor Yellow	
		exit
	}
} 