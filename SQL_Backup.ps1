<#
==============================================================================
 SQL Database Backup Script
==============================================================================
 Created: [05/21/2015]
 Author: Ethan Bell
 Company: Allied Virtual Office Assistants
 Arguments: N/A
==============================================================================
 Source: Original script downloaded from Microsoft TechNet 
==============================================================================
 Purpose: Create a backup of all SQL Databases on the local machine/server
==============================================================================
#>

## Full + Log Backup of MS SQL Server databases/span>            
## with SMO.            
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.ConnectionInfo');            
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.Management.Sdk.Sfc');            
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMO');            
# Required for SQL Server 2008 (SMO 10.0).            
[void][System.Reflection.Assembly]::LoadWithPartialName('Microsoft.SqlServer.SMOExtended');            
$Server = "(local)";     # SQL Server Instance.            
$Dest = "C:\Support\SQLBac\";    # Backup path on server (optional).            
$srv = New-Object Microsoft.SqlServer.Management.Smo.Server $Server;            
# If missing set default backup directory.            
If ($Dest -eq "")            
{ $Dest = $server.Settings.BackupDirectory + "\" };            
Write-Output ("Started at: " + (Get-Date -format yyyy-MM-dd-HH:mm:ss));            
# Full-backup for every database            
foreach ($db in $srv.Databases)            
{            
    If($db.Name -ne "tempdb")  # Non need to backup TempDB       
    {            
        $timestamp = Get-Date -format yyyy-MM-dd-HH-mm-ss;            
        $backup = New-Object ("Microsoft.SqlServer.Management.Smo.Backup");            
        $backup.Action = "Database";            
        $backup.Database = $db.Name;            
        $backup.Devices.AddDevice($Dest + $db.Name + "_full_" + $timestamp + ".bak", "File");            
        $backup.BackupSetDescription = "Full backup of " + $db.Name + " " + $timestamp;            
        $backup.Incremental = 0;            
        # Starting full backup process.            
        $backup.SqlBackup($srv);     
        # For db with recovery mode <> simple: Log backup.            
        If ($db.RecoveryModel -ne 3)            
        {            
            $timestamp = Get-Date -format yyyy-MM-dd-HH-mm-ss;            
            $backup = New-Object ("Microsoft.SqlServer.Management.Smo.Backup");            
            $backup.Action = "Log";            
            $backup.Database = $db.Name;            
            $backup.Devices.AddDevice($Dest + $db.Name + "_log_" + $timestamp + ".trn", "File");            
            $backup.BackupSetDescription = "Log backup of " + $db.Name + " " + $timestamp;            
            #Specify that the log must be truncated after the backup is complete.            
            $backup.LogTruncation = "Truncate";
            # Starting log backup process            
            $backup.SqlBackup($srv);            
        };            
    };            
};            
Write-Output ("Finished at: " + (Get-Date -format  yyyy-MM-dd-HH:mm:ss));