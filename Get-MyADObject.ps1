function Get-MyADObject {
    param (
        [string]$name,
        [string]$description,
        [string]$searchroot,
        [ValidateSet($null,'user','group','computer')]
        $type
    )
    
    if (!$name -and !$description -and !$searchroot) {
        Throw 'Please provide a search term or root.'
    } elseif (!$name -and !$description) {
        $name = '*'
    }
    
    # ASTERISK MAKES IT SLOW
    if ($type) {
        $filter = "(&(objectcategory=$type)"
    } else {
        $filter = '(&(|(objectcategory=user)(objectcategory=group)(objectcategory=computer))'
    }

    if ($name) {
        #$filter += "(|(samaccountname=*$name*)(name=*$name*)(displayname=*$name*)(userprincipalname=*$name*))"
        $filter += "(|(samaccountname=$name)(name=$name)(sn=$name)(givenname=$name)(mail=$name@mammoet.com))"
    }
    if ($description) {
        if ($description -match '|') {
            $descstring = @('(|')
            $descstring += $description.Split('|') | % {
                '(description=' + $_ + ')'
            }
            $descstring += @(')')
            $descstring = -join $descstring
            $filter += $descstring
        } else {
            $filter += "(description=$description)"
        }
    }
    $filter += ')'
    
    $searcher = [adsisearcher]$filter
    if ($searchroot) {
        if ($searchroot.EndsWith('/')) { $searchroot = $searchroot.Substring(0, $searchroot.Length - 1) }
        $searchrootarray = $searchroot.split('/')
        $newsearchroot = @('LDAP://')
        $newsearchroot += for ($i = $searchrootarray.Length - 1; $i -ge 0; $i--) {
            if ($i -ne 0) {
                'OU=' + $searchrootarray[$i] + ','
            } else {
                'DC=' + $searchrootarray[$i].Split('.')[0] + ',DC=' + $searchrootarray[$i].Split('.')[1]
            }
        }
        $newsearchroot = -join $newsearchroot
        $searcher.SearchRoot = [adsi]$newsearchroot
    }
    $searcher.PropertiesToLoad.AddRange(('name', 'displayname', 'sn', 'givenname', 'objectcategory', 'whencreated', 'whenchanged', 'pwdlastset', 'lastlogon', 'distinguishedname', 'samaccountname', 'userprincipalname', 'mail', 'operatingsystem', 'description', 'title', 'department', 'telephonenumber', 'mobile', 'homedirectory', 'homedrive', 'c', 'co', 'st', 'l', 'streetaddress', 'postalcode', 'company', 'useraccountcontrol', 'member', 'memberof'))
    
    $maxpwdage = ([adsi]"WinNT://$env:userdomain").maxpasswordage.value/86400
    $result = foreach ($object in $searcher.FindAll()){
        New-Object -TypeName PSObject -Property @{
            Name              = [string]$object.properties.name
            DisplayName       = [string]$object.properties.displayname
            LastName          = [string]$object.properties.sn
            FirstName         = [string]$object.properties.givenname
            ObjectCategory    = [string]$object.properties.objectcategory -replace '^cn=|,.*'
            WhenCreated       = Get-Date ([string]$object.Properties.whencreated) -f 'yyyy/MM/dd HH:mm:ss'
            WhenChanged       = Get-Date ([string]$object.Properties.whenchanged) -f 'yyyy/MM/dd HH:mm:ss'
            PwdLastSet        = $(try{ Get-Date ([datetime]::fromfiletime($object.properties.pwdlastset[0])) -f 'yyyy/MM/dd HH:mm:ss' } catch {})
            PwdDoesNotExpire  = if (([string]$object.properties.useraccountcontrol -band 65536) -eq 0) {$false} else {$true}
            PwdIsExpired      = $(try{ if (($(Get-Date) - $(Get-Date ([datetime]::fromfiletime($object.properties.pwdlastset[0]))) | select -ExpandProperty days) -gt $maxpwdage) {$true} else {$false} }catch{})
            LastLogon         = $(try{ Get-Date ([datetime]::fromfiletime($object.properties.lastlogon[0])) -f 'yyyy/MM/dd HH:mm:ss' } catch {})
            DistinguishedName = [string]$object.properties.distinguishedname
            SamAccountName    = [string]$object.properties.samaccountname
            UserPrincipalName = [string]$object.properties.userprincipalname
            Mail              = [string]$object.properties.mail
            OperatingSystem   = [string]$object.properties.operatingsystem
            Description       = [string]$object.properties.description
            Title             = [string]$object.properties.title
            Department        = [string]$object.properties.department
            TelephoneNumber   = [string]$object.properties.telephonenumber
            Mobile            = [string]$object.properties.mobile
            HomeDirectory     = [string]$object.properties.homedirectory
            HomeDrive         = [string]$object.properties.homedrive
            Country1          = [string]$object.properties.c
            Country2          = [string]$object.properties.co
            State             = [string]$object.properties.st
            City              = [string]$object.properties.l
            StreetAddress     = [string]$object.properties.streetaddress
            PostalCode        = [string]$object.properties.postalcode
            Company           = [string]$object.properties.company
            AccountIsLocked   = $(try{ if ((([adsi]$object.path).psbase.InvokeGet('IsAccountLocked')) -eq $true) {$true} else {$false} }catch{ $null })
            AccountIsDisabled = [bool]($object.Properties.useraccountcontrol -band 2)
            member            = $object.properties.member
            memberof          = $object.properties.memberof
        }
    }
    $result = $result | select name, displayname, lastname, firstname, objectcategory, whencreated, whenchanged, pwdlastset, PwdIsExpired, PwdDoesNotExpire, lastlogon, distinguishedname, samaccountname, userprincipalname, mail, operatingsystem, description, title, department, telephonenumber, mobile, homedirectory, homedrive, country1, country2, state, city, streetaddress, postalcode, company, accountislocked, accountisdisabled, member, memberof
    $result
}
