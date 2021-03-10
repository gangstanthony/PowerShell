# TODO
# test with SID accounts

# to figure out filesystemrights that only show as numbers
# https://social.technet.microsoft.com/Forums/windows/en-US/cb822c55-9f96-48e6-9c60-ca64ed13ef94/what-is-the-diference-between-acl-access-rule-quot268435456quot-and-quotfullcontrolquot?forum=winserverpowershell

function Get-FolderACL {
    param (
        [string]$Path,
        [switch]$ExpandGroups = $false,
        [string]$RightsRegex
    )
    
    begin {
        # digs through nested groups and returns all nested users.
        # does not return names of nested groups.
        # returns dn and objectcategory and enabled (not yet...)
        function Get-Member ([string]$GroupName) {
            if ($GroupName -match 'S-\d-\d-\d+') {
                $GroupName = $GroupName.Substring(3).Split(',', 2)[0]
                try {
                    $GroupName = ([System.Security.Principal.SecurityIdentifier]($GroupName)).Translate([System.Security.Principal.NTAccount]).Value
                    $GroupName = ([adsisearcher]"samaccountname=$GroupName").FindOne().Path.Substring(7)
                } catch {
                    Write-Warning "Could not translate $GroupName to name."
                }
            }

            $Grouppath = "LDAP://" + $GroupName
            $GroupObj = [adsi]$Grouppath

            $users = foreach ($member in $GroupObj.Member) {
                $UserPath = "LDAP://" + $member
                $UserObj = [adsi]$UserPath

                if (-not ($UserObj.groupType.Value -ne $null)) { # if this is NOT a group (it's a user) then...
                    $member
                } else { # this is a group. redo loop.
                    Get-Member -GroupName $member
                }
            }

            $users | select -Unique
        }
    }

    process {
        Write-Host "Running Get-FolderACL for $Path..."

        $arraylist = New-Object System.Collections.ArrayList

        # if you get access denied, skip the folder
        try {
            $CurrentACL = Get-Acl -Path $Path
        } catch {
            Write-Warning "Could not Get-Acl for $Path"
            continue
        }

        $owner = $CurrentACL.Owner

        $CurrentACL.Access | ForEach-Object {
        
            $FileSystemRights = $_.FileSystemRights.ToString()
            # skip if these are not the rights we are looking for
            if ($RightsRegex -and !($FileSystemRights -match $RightsRegex)) {
                return
            }

            $IdentityReference = ''
            $IdentityReference = $_.IdentityReference.ToString()
        
            $UserDomain = ''
            $UserAccount = ''
            if ($IdentityReference -match '\\') {
                $UserDomain = $IdentityReference.Substring(0, $IdentityReference.IndexOf('\'))
                $UserAccount = $IdentityReference.Substring($IdentityReference.IndexOf('\') + 1)
            }
        
            if ($UserAccount -match 'S-\d-\d-\d+') {
                try {
                    $UserAccount = ([System.Security.Principal.SecurityIdentifier]($UserAccount)).Translate([System.Security.Principal.NTAccount]).Value
                } catch {
                    Write-Warning "Could not translate $UserAccount to name."
                }
            }

            $ObjectCategory = ''
            $Enabled = ''

            $hash = New-Object System.Collections.Specialized.OrderedDictionary

            $hash.Add('Path', $Path)
            $hash.Add('Owner', $owner)
            $hash.Add('ObjectCategory', $ObjectCategory)
            $hash.Add('Enabled', $Enabled)
            #$hash.Add('UserDomain', $UserDomain)
            #$hash.Add('UserAccount', $UserAccount)
            $hash.Add('IdentityReference', $IdentityReference)
            $hash.Add('FileSystemRights', $FileSystemRights) # returns "Read, Write" may need to remove space
            $hash.Add('AsMemberOf', '')
            $hash.Add('IsInherited', $_.IsInherited.ToString()) # returns either true or false
            $hash.Add('InheritanceFlags', $_.InheritanceFlags.ToString()) # returns "ContainerInherit, ObjectInherit" may need to remove space
            $hash.Add('PropagationFlags', $_.PropagationFlags.ToString()) # mostly just 'none'
            $hash.Add('AccessControlType', $_.AccessControlType.ToString()) # either 'allow' or 'deny'

            $obj = New-Object psobject -Property $hash

            # if we're not interested in all the accounts, we may as well save time by not enumerating the admins groups for every single folder
            #if (!$ShowAllAccounts -and $UserAccount -match '(domain )?administrators') {
            # changed to this because: if the account is not a member of the domain, your results will vary depending on your local groups of your whatever computer you're running this on
        
            if ($UserDomain -eq $env:COMPUTERNAME -or $UserDomain -eq 'BUILTIN') {
                $winnt = [adsi]"WinNT://$env:COMPUTERNAME/$UserAccount"
            
                if (-not $winnt.groupType.Value.GetType().ToString().EndsWith('Int32')) {
                    $obj.ObjectCategory = 'User'
                
                    if (($winnt.userflags[0] -band 2) -ne 0) {
                        $obj.Enabled = $false
                    } else {
                        $obj.Enabled = $true
                    }
                } else {
                    $obj.ObjectCategory = 'Group'
                }
            } elseif ($UserDomain -eq 'NT AUTHORITY') {
                $obj.ObjectCategory = ''
                $obj.Enabled = ''
            } else {
                try {
                    $searcher = [adsisearcher]"samaccountname=$UserAccount"
                    $searcher.PropertiesToLoad.AddRange(('distinguishedname', 'objectcategory', 'useraccountcontrol'))
                    # CAUTION # we're assuming that there will only be one AD account with this samaccountname, so we're only using findone from the searcher
                    $result1 = New-Object psobject -Property $([hashtable]$searcher.FindOne().Properties)
                    $obj.ObjectCategory = [string]$result1.ObjectCategory -replace '^cn=|,.*'
                    $obj.Enabled = if (([string]$result1.UserAccountControl -band 2) -eq 0) {$true} else {$false}
                } catch {
                    $result1 = $null
                }
            }

            [void]$arraylist.Add($obj)

            # this is only to look into group members
            if ($ExpandGroups -and $obj.ObjectCategory -eq 'Group' -and -not ($UserDomain -eq 'NT AUTHORITY') -and -not ($UserAccount -match '(domain )?administrators')) {
                # results will all be users distinguishedname
                Get-Member $result1.distinguishedname | ForEach-Object {
                    # have to create a $newobj because modifying $obj after adding to $arraylist just overwrites the last entry
                    $newobj = $obj.PsObject.Copy()

                    $newobj.AsMemberOf = $IdentityReference

                    if ($_ -match 'S-\d-\d-\d+') {
                        $newobj.ObjectCategory = '' # if sid, we don't know if it's a person or not
                        $newobj.Enabled = ''
                        $UserAccount = $_.Substring(3).Split(',', 2)[0]
                        try {
                            $UserAccount = ([System.Security.Principal.SecurityIdentifier]($UserAccount)).Translate([System.Security.Principal.NTAccount]).Value
                        } catch {
                            Write-Warning "Could not translate $UserAccount to name."
                        }
                    } else {
                        $searcher = [adsisearcher]"distinguishedname=$_"
                        $searcher.PropertiesToLoad.AddRange(('userprincipalname', 'objectcategory', 'useraccountcontrol'))
                        $result2 = New-Object psobject -Property $([hashtable]$searcher.FindOne().Properties)
                        $newobj.ObjectCategory = [string]$result2.ObjectCategory -replace '^cn=|,.*'
                        $newobj.Enabled = if (([string]$result2.UserAccountControl -band 2) -eq 0) {$true} else {$false}
                        $UserAccount = $result2.UserPrincipalName.Split('@', 2)[0]
                    }

                    $UserDomain = ($_.Split(',') | ? {$_.StartsWith('DC=')})[0].Substring(3).ToUpper()
                    #$newobj.UserDomain = $UserDomain
                    #$newobj.UserAccount = $UserAccount
                    $newobj.IdentityReference = $UserDomain + '\' + $UserAccount

                    [void]$arraylist.Add($newobj)
                }
            }
        }
    
        Write-Output $arraylist | select * -Unique
    }
}
