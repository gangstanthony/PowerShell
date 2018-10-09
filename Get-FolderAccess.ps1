# NOTE: working on v2, but this is kind of a mess, and you may be better off using NTFSSecurity module with acltohtml to build a report
# 
# https://github.com/raandree/NTFSSecurity
# 
# acltohtml source: https://fossil.include-once.org/poshcode/artifact/e58827e740ef882e
# 
# Best to run as admin account or you might get "Attempted to perform an unauthorized operation" on folders you can't access.
# Depth 0 = only specified folder. # This used to be set to folder and recurse all subs
# Depth 1-6 = works for folder and it's children
# Filters groups by regex on name, not by "if it found a group then exclude it"
# Does not tell you if the permission is inherited or explicit
# 
# -Path            = 'c:\temp' | 'r:\' | '\\server\share'
# -Depth           = folder recurse depth. max is 6
# -ExpandGroups    = get all nested members of AD groups. then does not show group names
# -ShowAllAccounts = include builtin accounts and AD groups. for use with ExpandGroups
# -ReportFormat    = creates report in HTML or EXCEL format
# -DontOpen        = does not open report file after creation
# -Rights          = allows regex filter on access rights (ex:'readonly') # Doesn't work for some reason?
# 
# EXAMPLES:
# Get-FolderAccess -Path 'c:\temp\scripts'
# Get-FolderAccess -Path 'c:\temp' -ExpandGroups -ShowAllAccounts -Depth 0 -ReportFormat HTML
# Get-FolderAccess -Path 'c:\temp' -Depth 0 -ReportFormat HTML
# 
# RETURNS
# if ReportFormat is Console (default) it outputs an object to the console window
# if ReportFormat is either HTML or Excel, it returns the path to the created report
# 
# TODO:
# include email (maybe...)
# include folder browser dialogue for chosing where to save the report (maybe...)

function Get-FolderAccess {
    [CmdletBinding()]
    param (
        [string]$Path = $PWD,
        [int]$Depth = 1,
        [switch]$ExpandGroups = $false,
        [switch]$ShowAllAccounts = $false,
        [switch]$DontOpen = $false,
        [ValidateSet('Console','HTML','Excel')]
        $ReportFormat = 'Console'
    )

function Get-FolderACL ([string]$Path, [string]$Domain) {
    
    # if you get access denied, skip the folder
    try {
        $CurrentACL = Get-Acl -Path $Path
    } catch {
        Write-Warning "Could not Get-Acl for $Path"
        continue
    }

    # can't use this because we need the owner?
    #$thisacl = Get-Acl -Path $Path
    #$CurrentACL = New-Object System.Security.AccessControl.DirectorySecurity
    #$CurrentACL.SetOwner([System.Security.Principal.NTAccount]$thisacl.Owner)

    # could make hashtable of all current identities and exclude those from the output
    # or just filter out what i don't want (builtin, nt authority, etc...)
    #$CurrentACL.Access | % {$CurrentACL.RemoveAccessRule($_) | Out-Null} # does absolutely nothing???

#!#
#$root = Split-Path $Path -Leaf
#Write-Host "Folder: $root"
#!#

    $CurrentACL.Access |
        Where-Object {
            # skip those whose rights are just a bunch of numbers because it won't let me add them to the FileSystemAccessrule
            $_.FileSystemRights.ToString() -notmatch '^-?\d{5}'
        } |
        ForEach-Object {
            # remove the domain\ in the name
            $UserAccount = $_.IdentityReference.ToString().Substring($_.IdentityReference.ToString().IndexOf('\') + 1)
            $IdentityReference = $_.IdentityReference.ToString()
            $FileSystemRights  = $_.FileSystemRights.ToString() # returns "Read, Write" may need to remove space
            $InheritanceFlags  = $_.InheritanceFlags.ToString() # returns "ContainerInherit, ObjectInherit" may need to remove space
            $PropagationFlags  = $_.PropagationFlags.ToString() # mostly just 'none'
            $AccessControlType = $_.AccessControlType.ToString() # either 'allow' or 'deny'
            
            # if ((([adsi]"LDAP://$_").userAccountControl[0] -band 2) -ne 0) {account is disabled}

            # if we're not interested in all the accounts, we may as well save time by not enumerating the admins groups for every single folder
            #if (!$ShowAllAccounts -and $UserAccount -match '(domain )?administrators') {
            # changed to this because: if the account is not a member of the domain, your results will vary depending on your local groups of your whatever computer you're running this on
            if ($UserAccount -match '(domain )?administrators') {
                $CurrentACL.AddAccessRule($_)
            } else {
                try {
                    $dn = ([adsisearcher]"samaccountname=$($UserAccount)").FindOne().Path.Substring(7)
                } catch {
                    $dn = $null
                }
                Get-Member $dn |
                    Where-Object { # filter out any ForeignSecurityPrincipals
                        $_ -notmatch 'S-\d-\d-\d{1,}'
                    } |
                    ForEach-Object {
                        $IdentityReference = ([adsi]"LDAP://$_").samaccountname.ToString()
                        $CurrentACLPermission = $IdentityReference, $FileSystemRights, $InheritanceFlags, $PropagationFlags, $AccessControlType
                        
                        try {
                            $CurrentAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $CurrentACLPermission
                            $CurrentACL.AddAccessRule($CurrentAccessRule)
                        } catch {
                            Write-Host "Error: `$CurrentAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $CurrentACLPermission" -ForegroundColor Red
                            "Error: `$CurrentAccessRule = New-Object System.Security.AccessControl.FileSystemAccessRule $CurrentACLPermission" >> $logFile
                        }
                    }
            }
        }
    Write-Output $CurrentACL | select * -Unique
}

function Get-Member ($GroupName) {
    $Grouppath = "LDAP://" + $GroupName
    $GroupObj = [ADSI]$Grouppath

#!#
#Write-Host "    Group:"$GroupObj.cn.ToString()
#!#

    $users = foreach ($member in $GroupObj.Member) {
        $UserPath = "LDAP://" + $member
        $UserObj = [ADSI]$UserPath

        if ($UserObj.groupType.Value -eq $null) { # if this is NOT a group (it's a user) then...

#!#
#Write-Host "        Member:"$UserObj.cn.ToString()
#!#

            $member
        } else { # this is a group. redo loop.
            Get-Member -GroupName $member
        }
    }
    $users | select -Unique
}

function acltohtml ($Path, $colACLs, $ShowAllAccounts, $Domain) {
$saveDir = "$env:TEMP\Network Access"
if (!(Test-Path $saveDir)) {
    $null = mkdir "$saveDir\Logs"
}
$time = Get-Date -Format 'yyyyMMddHHmmss'
$saveName = "Network Access $time"
$report = "$saveDir\$saveName.html"
'' > $report
$result = New-Object System.Text.StringBuilder

#region Function definitions
function drawDirectory ($directory, $Domain) {
    $dirHTML = New-Object System.Text.StringBuilder

    $null = $dirHTML.Append('
        <div class="')

    if ($directory.level -eq 0) {
        $null = $dirHTML.Append('he0_expanded')
    } else {
        $null = $dirHTML.Append('he' + $directory.level)
    }

    $null = $dirHTML.Append('"><span class="sectionTitle" tabindex="0">Folder ' + $directory.Folder + '</span></div>
        <div class="container">
        <div class="he4i">
        <div class="heACL">
        <table class="info3" cellpadding="0" cellspacing="0">
        <thead>
        <th scope="col"><b>Owner</b></th>
        </thead>
        <tbody>')

    $null = $dirHTML.Append('<tr><td>' + $itemACL.Owner + '</td></tr>
        <tr>
        <td>
        <table>
        <thead>
        <th>User</th>
        <th>Control</th>
        <th>Privilege</th>
        </thead>
        <tbody>')

    $itemACL = $directory.ACL
    if ($itemACL.AccessToString -ne $null) {
        # select -u because duplicates if inherited and not
        $acls = $itemACL.AccessToString.split("`n") | select -Unique | ? {$_ -notmatch '  -\d{9}$'} | sort
    }
    
    if (!$ShowAllAccounts) {
        $acls = $acls -match "^$domain\\" -notmatch '\\MAM-|\\\w{2}-\w{3}\d-\w{3}|\\a-|\\-svc-'
    }
    
    $index = 0
    $total = $acls.Count
    $starttime = $lasttime = Get-Date
    foreach ($acl in $acls) {
        #$temp = [regex]::split($acl, '(?<!(,|NT))\s+')
        $temp = [regex]::split($acl, '\s+(?=Allow|Deny)|(?<=Allow|Deny)\s+')  

        if ($debug) {
            Write-Host "ACL(" $temp.gettype().name ")[" $temp.length "]: " $temp
        }

        if ($temp.count -eq 1) {
            continue
        }

        $index++
        $currtime = (Get-Date) - $starttime
        $avg = $currtime.TotalSeconds / $index
        $last = ((Get-Date) - $lasttime).TotalSeconds
        $left = $total - $index
        $WrPrgParam = @{
            Activity = (
                "Check if account is disabled $(Get-Date -f s)",
                "Total: $($currtime -replace '\..*')",
                "Avg: $('{0:N2}' -f $avg)",
                "Last: $('{0:N2}' -f $last)",
                "ETA: $('{0:N2}' -f ($avg * $left / 60))",
                "min ($([string](Get-Date).AddSeconds($avg*$left) -replace '^.* '))"
            ) -join ' '
            Status = "$index of $total ($left left) [$('{0:N2}' -f ($index / $total * 100))%]"
            CurrentOperation = "USER: $($temp[0])"
            PercentComplete = $index / $total * 100
            id = 2
        }
        Write-Progress @WrPrgParam
        $lasttime = Get-Date

        if ($temp[0] -match "^$domain\\") {
            if ((([adsi]([adsisearcher]"samaccountname=$($temp[0] -replace "^$domain\\")").findone().path).useraccountcontrol[0] -band 2) -ne 0) {
                # account is disabled
                $temp[0] += ' - DISABLED'
            }
        }

        $null = $dirHTML.Append('<tr><td>' + $temp[0] + '</td><td>' + $temp[1] + '</td><td>' + $temp[2] + '</td></tr>')
    }

    $null = $dirHTML.Append('</tbody>
        </table>
        </td>
        </tr>
        </tbody>
        </table>
        </div>
        </div>
        <div class="filler"></div>
        </div>')

    return $dirHTML.ToString()
}
#endregion
#region Header, style and javascript functions needed by the html report
$null = $result.Append(@"
<html dir="ltr" xmlns:v="urn:schemas-microsoft-com:vml" gpmc_reportInitialized="false">
<head>
<meta http-equiv="Content-Type" content="text/html; charset=UTF-16" />
<title>Access Control List for $Path</title>
<!-- Styles -->
<style type="text/css">
    body    { background-color:#FFFFFF; border:1px solid #666666; color:#000000; font-size:68%; font-family:MS Shell Dlg; margin:0,0,10px,0; word-break:normal; word-wrap:break-word; }
    table   { font-size:100%; table-layout:fixed; width:100%; }
    td,th   { overflow:visible; text-align:left; vertical-align:top; white-space:normal; }
    .title  { background:#FFFFFF; border:none; color:#333333; display:block; height:24px; margin:0px,0px,-1px,0px; padding-top:4px; position:relative; table-layout:fixed; width:100%; z-index:5; }
    .he0_expanded    { background-color:#FEF7D6; border:1px solid #BBBBBB; color:#3333CC; cursor:hand; display:block; font-family:MS Shell Dlg; font-size:100%; font-weight:bold; height:2.25em; margin-bottom:-1px; margin-left:0px; margin-right:0px; padding-left:8px; padding-right:5em; padding-top:4px; position:relative; width:100%; }
    .he1_expanded    { background-color:#A0BACB; border:1px solid #BBBBBB; color:#000000; cursor:hand; display:block; font-family:MS Shell Dlg; font-size:100%; font-weight:bold; height:2.25em; margin-bottom:-1px; margin-left:20px; margin-right:0px; padding-left:8px; padding-right:5em; padding-top:4px; position:relative; width:100%; }
    .he1h_expanded   { background-color: #7197B3; border: 1px solid #BBBBBB; color: #000000; cursor: hand; display: block; font-family: MS Shell Dlg; font-size: 100%; font-weight: bold; height: 2.25em; margin-bottom: -1px; margin-left: 10px; margin-right: 0px; padding-left: 8px; padding-right: 5em; padding-top: 4px; position: relative; width: 100%; }
    .he1    { background-color:#A0BACB; border:1px solid #BBBBBB; color:#000000; cursor:hand; display:block; font-family:MS Shell Dlg; font-size:100%; font-weight:bold; height:2.25em; margin-bottom:-1px; margin-left:20px; margin-right:0px; padding-left:8px; padding-right:5em; padding-top:4px; position:relative; width:100%; }
    .he2    { background-color:#C0D2DE; border:1px solid #BBBBBB; color:#000000; cursor:hand; display:block; font-family:MS Shell Dlg; font-size:100%; font-weight:bold; height:2.25em; margin-bottom:-1px; margin-left:30px; margin-right:0px; padding-left:8px; padding-right:5em; padding-top:4px; position:relative; width:100%; }
    .he3    { background-color:#D9E3EA; border:1px solid #BBBBBB; color:#000000; cursor:hand; display:block; font-family:MS Shell Dlg; font-size:100%; font-weight:bold; height:2.25em; margin-bottom:-1px; margin-left:40px; margin-right:0px; padding-left:11px; padding-right:5em; padding-top:4px; position:relative; width:100%; }
    .he4    { background-color:#E8E8E8; border:1px solid #BBBBBB; color:#000000; cursor:hand; display:block; font-family:MS Shell Dlg; font-size:100%; font-weight:bold; height:2.25em; margin-bottom:-1px; margin-left:50px; margin-right:0px; padding-left:11px; padding-right:5em; padding-top:4px; position:relative; width:100%; }
    .he4h   { background-color:#E8E8E8; border:1px solid #BBBBBB; color:#000000; cursor:hand; display:block; font-family:MS Shell Dlg; font-size:100%; font-weight:bold; height:2.25em; margin-bottom:-1px; margin-left:55px; margin-right:0px; padding-left:11px; padding-right:5em; padding-top:4px; position:relative; width:100%; }
    .he4i   { background-color:#F9F9F9; border:1px solid #BBBBBB; color:#000000; display:block; font-family:MS Shell Dlg; font-size:100%; margin-bottom:-1px; margin-left:30px; margin-right:0px; padding-bottom:5px; padding-left:21px; padding-top:4px; position:relative; width:100%; }
    .he5    { background-color:#E8E8E8; border:1px solid #BBBBBB; color:#000000; cursor:hand; display:block; font-family:MS Shell Dlg; font-size:100%; font-weight:bold; height:2.25em; margin-bottom:-1px; margin-left:60px; margin-right:0px; padding-left:11px; padding-right:5em; padding-top:4px; position:relative; width:100%; }
    .he5h   { background-color:#E8E8E8; border:1px solid #BBBBBB; color:#000000; cursor:hand; display:block; font-family:MS Shell Dlg; font-size:100%; padding-left:11px; padding-right:5em; padding-top:4px; margin-bottom:-1px; margin-left:65px; margin-right:0px; position:relative; width:100%; }
    .he5i   { background-color:#F9F9F9; border:1px solid #BBBBBB; color:#000000; display:block; font-family:MS Shell Dlg; font-size:100%; margin-bottom:-1px; margin-left:65px; margin-right:0px; padding-left:21px; padding-bottom:5px; padding-top: 4px; position:relative; width:100%; }
    DIV .expando { color:#000000; text-decoration:none; display:block; font-family:MS Shell Dlg; font-size:100%; font-weight:normal; position:absolute; right:10px; text-decoration:underline; z-index: 0; }
    .he0 .expando { font-size:100%; }
    .info, .info3, .info4, .disalign  { line-height:1.6em; padding:0px,0px,0px,0px; margin:0px,0px,0px,0px; }
    .disalign TD                      { padding-bottom:5px; padding-right:10px; }
    .info TD                          { padding-right:10px; width:50%; }
    .info3 TD                         { padding-right:10px; width:33%; }
    .info4 TD, .info4 TH              { padding-right:10px; width:25%; }
    .info TH, .info3 TH, .info4 TH, .disalign TH { border-bottom:1px solid #CCCCCC; padding-right:10px; }
    .subtable, .subtable3             { border:1px solid #CCCCCC; margin-left:0px; background:#FFFFFF; margin-bottom:10px; }
    .subtable TD, .subtable3 TD       { padding-left:10px; padding-right:5px; padding-top:3px; padding-bottom:3px; line-height:1.1em; width:10%; }
    .subtable TH, .subtable3 TH       { border-bottom:1px solid #CCCCCC; font-weight:normal; padding-left:10px; line-height:1.6em;  }
    .subtable .footnote               { border-top:1px solid #CCCCCC; }
    .subtable3 .footnote, .subtable .footnote { border-top:1px solid #CCCCCC; }
    .subtable_frame     { background:#D9E3EA; border:1px solid #CCCCCC; margin-bottom:10px; margin-left:15px; }
    .subtable_frame TD  { line-height:1.1em; padding-bottom:3px; padding-left:10px; padding-right:15px; padding-top:3px; }
    .subtable_frame TH  { border-bottom:1px solid #CCCCCC; font-weight:normal; padding-left:10px; line-height:1.6em; }
    .subtableInnerHead { border-bottom:1px solid #CCCCCC; border-top:1px solid #CCCCCC; }
    .explainlink            { color:#000000; text-decoration:none; cursor:hand; }
    .explainlink:hover      { color:#0000FF; text-decoration:underline; }
    .spacer { background:transparent; border:1px solid #BBBBBB; color:#FFFFFF; display:block; font-family:MS Shell Dlg; font-size:100%; height:10px; margin-bottom:-1px; margin-left:43px; margin-right:0px; padding-top: 4px; position:relative; }
    .filler { background:transparent; border:none; color:#FFFFFF; display:block; font:100% MS Shell Dlg; line-height:8px; margin-bottom:-1px; margin-left:53px; margin-right:0px; padding-top:4px; position:relative; }
    .container { display:block; position:relative; }
    .rsopheader { background-color:#A0BACB; border-bottom:1px solid black; color:#333333; font-family:MS Shell Dlg; font-size:130%; font-weight:bold; padding-bottom:5px; text-align:center; }
    .rsopname { color:#333333; font-family:MS Shell Dlg; font-size:130%; font-weight:bold; padding-left:11px; }
    .gponame{ color:#333333; font-family:MS Shell Dlg; font-size:130%; font-weight:bold; padding-left:11px; }
    .gpotype{ color:#333333; font-family:MS Shell Dlg; font-size:100%; font-weight:bold; padding-left:11px; }
    #uri    { color:#333333; font-family:MS Shell Dlg; font-size:100%; padding-left:11px; }
    #dtstamp{ color:#333333; font-family:MS Shell Dlg; font-size:100%; padding-left:11px; text-align:left; width:30%; }
    #objshowhide { color:#000000; cursor:hand; font-family:MS Shell Dlg; font-size:100%; font-weight:bold; margin-right:0px; padding-right:10px; text-align:right; text-decoration:underline; z-index:2; word-wrap:normal; }
    #gposummary { display:block; }
    #gpoinformation { display:block; }
    @media print {
        #objshowhide{ display:none; }
        body    { color:#000000; border:1px solid #000000; }
        .title  { color:#000000; border:1px solid #000000; }
        .he0_expanded    { color:#000000; border:1px solid #000000; }
        .he1h_expanded   { color:#000000; border:1px solid #000000; }
        .he1_expanded    { color:#000000; border:1px solid #000000; }
        .he1    { color:#000000; border:1px solid #000000; }
        .he2    { color:#000000; background:#EEEEEE; border:1px solid #000000; }
        .he3    { color:#000000; border:1px solid #000000; }
        .he4    { color:#000000; border:1px solid #000000; }
        .he4h   { color:#000000; border:1px solid #000000; }
        .he4i   { color:#000000; border:1px solid #000000; }
        .he5    { color:#000000; border:1px solid #000000; }
        .he5h   { color:#000000; border:1px solid #000000; }
        .he5i   { color:#000000; border:1px solid #000000; }
        }
        v\:* {behavior:url(#default#VML);}
</style>
</head>
<body>
<table class="title" cellpadding="0" cellspacing="0">
<tr><td colspan="2" class="gponame">Access Control List for $Path</td></tr>
<tr>
<td id="dtstamp">Data obtained on: $(Get-Date)</td>
<td><div id="objshowhide" tabindex="0"></div></td>
</tr>
</table>
<div class="filler"></div>
'<div class="gposummary">'
"@)
#endregion
#region Setting up the report    
    $index = 0
    $total = $colACLs.Count
    $starttime = $lasttime = Get-Date
    foreach ($acl in $colACLs) {
        $index++
        $currtime = (Get-Date) - $starttime
        $avg = $currtime.TotalSeconds / $index
        $last = ((Get-Date) - $lasttime).TotalSeconds
        $left = $total - $index
        $WrPrgParam = @{
            Activity = (
                "acltohtml $(Get-Date -f s)",
                "Total: $($currtime -replace '\..*')",
                "Avg: $('{0:N2}' -f $avg)",
                "Last: $('{0:N2}' -f $last)",
                "ETA: $('{0:N2}' -f ($avg * $left / 60))",
                "min ($([string](Get-Date).AddSeconds($avg*$left) -replace '^.* '))"
            ) -join ' '
            Status = "$index of $total ($left left) [$('{0:N2}' -f ($index / $total * 100))%]"
            CurrentOperation = "FOLDER: $($acl.folder)"
            PercentComplete = $index / $total * 100
            id = 1
        }
        Write-Progress @WrPrgParam
        $lasttime = Get-Date

        $null = $result.Append((drawDirectory -directory $acl -domain $Domain))
    }

    $null = $result.Append('</div></body></html>')

    $result.ToString() > $report
#endregion
    if (!$DontOpen) {
        . $report
    }

    $report
}

function acltovariable ($colACLs, $ShowAllAccounts, [string]$Domain) {
    $index = 0
    $total = $colACLs.Count
    $starttime = $lasttime = Get-Date
    foreach ($directory in $colACLs) {
        $index++
        $currtime = (Get-Date) - $starttime
        $avg = $currtime.TotalSeconds / $index
        $last = ((Get-Date) - $lasttime).TotalSeconds
        $left = $total - $index
        $WrPrgParam = @{
            Activity = (
                "acltovariable $(Get-Date -f s)",
                "Total: $($currtime -replace '\..*')",
                "Avg: $('{0:N2}' -f $avg)",
                "Last: $('{0:N2}' -f $last)",
                "ETA: $('{0:N2}' -f ($avg * $left / 60))",
                "min ($([string](Get-Date).AddSeconds($avg*$left) -replace '^.* '))"
            ) -join ' '
            Status = "$index of $total ($left left) [$('{0:N2}' -f ($index / $total * 100))%]"
            CurrentOperation = "FOLDER: $($directory.folder)"
            PercentComplete = $index / $total * 100
            id = 1
        }
        Write-Progress @WrPrgParam
        $lasttime = Get-Date

        $itemACL = $directory.ACL
        $acls = $null

        if ($itemACL.AccessToString -ne $null) {
            # select -u because duplicates if inherited and not
            $acls = $itemACL.AccessToString.split("`n") | select -Unique | <#? {$_ -notmatch '  -\d{9}$'} |#> sort
        }
        
        if (!$ShowAllAccounts) {
            $acls = $acls -match "^$domain\\" -notmatch '\\MAM-|\\\w{2}-\w{3}\d-\w{3}|\\a-|\\-svc-'
        }

        $index2 = 0
        $total2 = $acls.Count
        $starttime2 = $lasttime2 = Get-Date
        foreach ($acl in $acls) {
            #$temp = [regex]::split($acl, '(?<!(,|NT))\s+')
            $temp = [regex]::split($acl, '\s+(?=Allow|Deny)|(?<=Allow|Deny)\s+')

            if ($temp.count -eq 1) {
                continue
            }

            $index2++
            $currtime2 = (Get-Date) - $starttime2
            $avg2 = $currtime2.TotalSeconds / $index2
            $last2 = ((Get-Date) - $lasttime2).TotalSeconds
            $left2 = $total2 - $index2
            $WrPrgParam2 = @{
                Activity = (
                    "Check if account is disabled $(Get-Date -f s)",
                    "Total: $($currtime2 -replace '\..*')",
                    "Avg: $('{0:N2}' -f $avg2)",
                    "Last: $('{0:N2}' -f $last2)",
                    "ETA: $('{0:N2}' -f ($avg2 * $left2 / 60))",
                    "min ($([string](Get-Date).AddSeconds($avg2*$left2) -replace '^.* '))"
                ) -join ' '
                Status = "$index2 of $total2 ($left2 left) [$('{0:N2}' -f ($index2 / $total2 * 100))%]"
                CurrentOperation = "USER: $($temp[0])"
                PercentComplete = $index2 / $total2 * 100
                id = 2
            }
            Write-Progress @WrPrgParam2
            $lasttime2 = Get-Date

            # if it is a domain account, see if it is disabled
            if ($temp[0] -match "^$domain\\") {
                if ((([adsi]([adsisearcher]"samaccountname=$($temp[0] -replace "^$domain\\")").findone().path).useraccountcontrol[0] -band 2) -ne 0) {
                    $temp[0] += ' - DISABLED'
                }
            }

            New-Object psobject -Property @{
                Folder = $directory.Folder
                Name   = $temp[0]
                Access = $temp[1]
                Rights = $temp[2]
            }
        }
    }
}

function acltoexcel ($colACLs, $ShowAllAccounts) {
    $saveDir = "$env:TEMP\Network Access"
    if (!(Test-Path $saveDir)) {$null = mkdir "$saveDir\Logs"}
    $time = Get-Date -Format 'yyyyMMddHHmmss'
    $saveName = "Network Access $time"
    $report = "$saveDir\$saveName.csv"
    '' > $report

    acltovariable $colACLs $ShowAllAccounts | epcsv $report -NoTypeInformation

    $xl = New-Object -ComObject 'Excel.Application'
    $wb = $xl.workbooks.open($report)
    $xlOut = $report.Replace('.csv', '')
    $ws = $wb.Worksheets.Item(1)
    $range = $ws.UsedRange 
    [void]$range.EntireColumn.Autofit()
    $wb.SaveAs($xlOut, 51)
    $xl.Quit()
    
    function Release-Ref ($ref) {
        ([System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.__ComObject]$ref) -gt 0)
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
    }
    
    $null = $ws, $wb, $xl | % {Release-Ref $_}

    del $report

    if (!$DontOpen) {
        . ($report -replace '\.csv$', '.xlsx')
    }

    $report -replace '\.csv$', '.xlsx'
}

function SIDtoName ([string]$SID) {
    ([System.Security.Principal.SecurityIdentifier]($SID)).Translate([System.Security.Principal.NTAccount]).Value
}

######### BEGIN DO STUFF ##########

    # set up defaults
    $domain = $env:USERDOMAIN

    if ($Path.EndsWith('\')) {
        $Path = $Path.TrimEnd('\')
    }

    $allowedLevels = 6

    if ($Depth -gt $allowedLevels -or $Depth -lt -1) {
        throw 'Level out of range.'
    }
    
    if (!$ExpandGroups) {
        $ShowAllAccounts = $true
    }

    $colFolders = New-Object System.Collections.ArrayList

    if ($Depth -eq 0) {
        # just continue
        #$colFiles = Get-ChildItem -path $Path -Filter *. -Recurse -Force | Sort-Object FullName
    } elseif ($Depth -ne -1) {
        1..$Depth | % {
            # psiscontainer to only get directories
            Get-ChildItem -Path ($Path + ('\*' * $_)) -ErrorVariable GciError -ErrorAction SilentlyContinue | ? {$_.psiscontainer} | sort FullName | % {
                $null = $colFolders.Add($_.FullName)
            }
        }
    }

    if ($GciError) {
        $GciError | % {Write-Warning $_.exception.message}
    }
    
    # begin get all acls
    $colACLs = New-Object System.Collections.ArrayList

    $myobj = New-Object psobject -Property @{
        Folder = $Path
        ACL = ''
        Level = 0
    }

    if (!$ExpandGroups) {
        $ShowAllAccounts = $true
        $myobj.ACL = Get-Acl -Path $Path
    } else {
        $myobj.ACL = Get-FolderACL -Path $Path -Domain $domain
    }

    $null = $colACLs.Add($myobj)

    $index = 0
    $total = $colFolders.Count
    $starttime = $lasttime = Get-Date
    #* $file = $colFiles[0]
    foreach ($folder in $colFolders) {
        $index++
        $currtime = (Get-Date) - $starttime
        $avg = $currtime.TotalSeconds / $index
        $last = ((Get-Date) - $lasttime).TotalSeconds
        $left = $total - $index
        $WrPrgParam = @{
            Activity = (
                "Get-FolderAccess $(Get-Date -f s)",
                "Total: $($currtime -replace '\..*')",
                "Avg: $('{0:N2}' -f $avg)",
                "Last: $('{0:N2}' -f $last)",
                "ETA: $('{0:N2}' -f ($avg * $left / 60))",
                "min ($([string](Get-Date).AddSeconds($avg*$left) -replace '^.* '))"
            ) -join ' '
            Status = "$index of $total ($left left) [$('{0:N2}' -f ($index / $total * 100))%]"
            CurrentOperation = "FOLDER: $folder"
            PercentComplete = $index / $total * 100
        }
        Write-Progress @WrPrgParam
        $lasttime = Get-Date

        # calculate current folder depth
        $matches = (([regex]'\\').matches($folder.substring($Path.length, $folder.length - $Path.length))).count

        $myobj = New-Object psobject -Property @{
            Folder = $folder
            ACL = ''
            Level = $matches - 1
        }
        
        if (!$ExpandGroups) {
            $myobj.ACL = Get-Acl -Path $folder
        } else {
            $myobj.ACL = Get-FolderAcl -Path $folder -Domain $domain #* $myobj.ACL = $CurrentACL
        }

        $null = $colACLs.Add($myobj)
    }

    # sort by folder then subs.
    # this is because the root was added before the loop (putting all level 0 folders at the top, then level 1s above 2s, etc.), but sorting by name organizes it.
    $colACLs = $colACLs | sort folder

    # begin do stuff with all those acls...
    switch ($ReportFormat) {
        'Console' {acltovariable -colACLs $colACLs -ShowAllAccounts $ShowAllAccounts -Domain $domain}
        'HTML'    {acltohtml -Path $Path -colACLs $colACLs -ShowAllAccounts $ShowAllAccounts -Domain $domain}
        'Excel'   {acltoexcel -colACLs $colACLs -ShowAllAccounts $ShowAllAccounts}
    }
}
