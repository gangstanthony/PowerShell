## Variables
$Dest = "C:\Support\SQLBac\";    # Backup path on server (optional).
$Daysback = "0";                 # Days to keep.

$CurrentDate = Get-Date
$DatetoDelete = $CurrentDate.AddDays($Daysback)
Get-ChildItem $Dest | Where-Object { $_.LastWriteTime -lt $DatetoDelete } | Remove-Item