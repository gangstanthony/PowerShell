# https://www.reddit.com/r/PowerShell/comments/9vlrxo/requesting_help_to_optimize_this_getmailbox_based/

# took almost 7 seconds per mailbox (office 365)

Write-Host 'Gathering Stats, Please Wait..'

$Mailboxes = Get-Mailbox -ResultSize Unlimited | Select UserPrincipalName, Identity, ArchiveStatus

$index = 0
$total = @($Mailboxes).Count
$starttime = $lasttime = Get-Date
$MailboxSizes = foreach ($Mailbox in $Mailboxes)
{
    $index++
    $currtime = (Get-Date) - $starttime
    $avg = $currtime.TotalSeconds / $index
    $last = ((Get-Date) - $lasttime).TotalSeconds
    $left = $total - $index
    $WrPrgParam = @{
        Activity = (
            "Get-MailboxStats $(Get-Date -f s)",
            "Total: $($currtime -replace '\..*')",
            "Avg: $('{0:N2}' -f $avg)",
            "Last: $('{0:N2}' -f $last)",
            "ETA: $('{0:N2}' -f ($avg * $left / 60))",
            "min ($([string](Get-Date).AddSeconds($avg*$left) -replace '^.* '))"
        ) -join ' '
        Status = "$index of $total ($left left) [$('{0:N2}' -f ($index / $total * 100))%]"
        CurrentOperation = "$Mailbox"
        PercentComplete = $index / $total * 100
    }
    Write-Progress @WrPrgParam
    $lasttime = Get-Date

    $MailboxStats = Get-MailboxStatistics $Mailbox.UserPrincipalname | Select LastLogonTime, @{n='TotalItemSizeGB';e={[math]::Round( (($_.TotalItemSize.Value.ToString()).Split("(")[1].Split(' ')[0].Replace(',', '') / 1GB), 2 )}}, ItemCount
    $MailboxFolderStats = Get-MailboxFolderStatistics $Mailbox.UserPrincipalName | Where-Object {$_.name -like 'Purges' -or $_.name -like 'DiscoveryHolds'}
    $MailboxPurgeFolderStats = $MailboxFolderStats | Where-Object {$_.name -like 'Purges'} | Select Name, @{n='FolderSizeGB';e={[math]::Round( ([decimal](($_.FolderSize -replace '[0-9\.]+ [A-Z]* \(([0-9,]+) bytes\)', '$1').Replace(',', '')) / 1GB), 2 )}}, ItemsInFolder
    $MailboxDiscoveryHoldsFolderStats = $MailboxFolderStats | Where-Object {$_.name -like 'DiscoveryHolds'} | Select Name, @{n='FolderSizeGB';e={[math]::Round( ([decimal](($_.FolderSize -replace '[0-9\.]+ [A-Z]* \(([0-9,]+) bytes\)', '$1').Replace(',', '')) / 1GB), 2 )}}, ItemsInFolder

    if ($Mailbox.ArchiveStatus -eq 'Active')
    {
        $ArchiveStats = Get-MailboxStatistics $Mailbox.UserPrincipalname -Archive | Select @{n='TotalItemSizeGB';e={[math]::Round( (($_.TotalItemSize.Value.ToString()).Split('(')[1].Split(' ')[0].Replace(',', '') / 1GB), 2 )}}, ItemCount

        $ArchiveSize = $ArchiveStats.TotalItemSizeGB
        $ArchiveItemCount = $ArchiveStats.ItemCount
    }
    else
    {
        $ArchiveSize = 'No Archive'
        $ArchiveItemCount = 'No Archive'
    }

    [pscustomobject]@{
        UserPrincipalName = $Mailbox.UserPrincipalName
        LastLoggedIn = $MailboxStats.LastLogonTime
        MailboxSize = $MailboxStats.TotalItemSizeGB
        MailboxItemCount = $MailboxStats.ItemCount
        PurgesFolderSize = $MailboxPurgeFolderStats.FolderSizeGB
        PurgeItems = $MailboxPurgeFolderStats.ItemsInFolder
        DiscoveryHoldsFolderSize = $MailboxDiscoveryHoldsFolderStats.FolderSizeGB
        DiscoveryHoldItems = $MailboxDiscoveryHoldsFolderStats.ItemsInFolder
        ArchiveSize = $ArchiveSize
        ArchiveItemCount = $ArchiveItemCount
    }
}

$MailboxSizes | Out-GridView -Title 'Mailbox and Archive Sizes'
