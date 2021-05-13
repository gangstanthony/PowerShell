# https://github.com/RamblingCookieMonster/PowerShell/blob/master/Get-ADSIObject.ps1
# http://www.ldapexplorer.com/en/manual/109010000-ldap-filter-syntax.htm

# alternate credentials
# https://www.reddit.com/r/PowerShell/comments/40zmmf/converting_a_vb_script_to_powershellabsolutely/

function Get-MADObject {
    param (
        [string]$name,
        [string]$description,
        [string]$searchroot,
        [ValidateSet($null,'user','group','computer')]
        $type
    )
    
    if (!$name -and !$description -and !$searchroot -and !$type) {
        Throw 'Please provide a type, search term, or root.'
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
        $filter += "(|(samaccountname=$name)(name=$name)(sn=$name)(givenname=$name)(mail=$name@randgroup.com))"
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
    $searcher.PageSize = 200
    if ($searchroot) { # this part allows you to enter like 'domain.com/someou/anotherou', but it does not account for containers
        $searchrootarray = $searchroot.split('/') | ? {$_}
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
    $searcher.PropertiesToLoad.AddRange(('name', 'displayname', 'sn', 'givenname', 'objectcategory', 'grouptype', 'whencreated', 'whenchanged', 'pwdlastset', 'lastlogon', 'distinguishedname', 'samaccountname', 'userprincipalname', 'mail', 'proxyaddresses', 'msexchhomeservername', 'homemdb', 'operatingsystem', 'description', 'title', 'department', 'manager', 'telephonenumber', 'mobile', 'scriptpath', 'homedirectory', 'homedrive', 'c', 'co', 'st', 'l', 'streetaddress', 'postalcode', 'company', 'useraccountcontrol', 'member', 'memberof'))
    
    $maxpwdage = ([adsi]"WinNT://$env:userdomain").maxpasswordage.value / 86400
    $(foreach ($object in $searcher.FindAll()) {
        New-Object -TypeName PSObject -Property @{
            Name              = [string]$object.properties.name
            DisplayName       = [string]$object.properties.displayname
            LastName          = [string]$object.properties.sn
            FirstName         = [string]$object.properties.givenname
            ObjectCategory    = [string]$object.properties.objectcategory -replace '^cn=|,.*'
            GroupType         = $(switch ([string]$object.properties.grouptype) {2 {'Global distribution group'};4 {'Domain local distribution group'};8 {'Universal distribution group'};'-2147483646' {'Global security group'};'-2147483644' {'Domain local security group'};'-2147483640' {'Universal security group'}})
            WhenCreated       = $(try{ Get-Date ([string]$object.Properties.whencreated) -f 'yyyy/MM/dd HH:mm:ss' } catch {''})
            WhenChanged       = $(try{ Get-Date ([string]$object.Properties.whenchanged) -f 'yyyy/MM/dd HH:mm:ss' } catch {''})
            PwdLastSet        = $(try{ Get-Date ([datetime]::fromfiletime($object.properties.pwdlastset[0])) -f 'yyyy/MM/dd HH:mm:ss' } catch {''})
            PwdDoesNotExpire  = if (([string]$object.properties.useraccountcontrol -band 65536) -eq 0) {$false} else {$true}
            PwdIsExpired      = $(try{ if (($(Get-Date) - $(Get-Date ([datetime]::fromfiletime($object.properties.pwdlastset[0]))) | select -ExpandProperty days) -gt $maxpwdage) {$true} else {$false} }catch{''})
            LastLogon         = $(try{ Get-Date ([datetime]::fromfiletime($object.properties.lastlogon[0])) -f 'yyyy/MM/dd HH:mm:ss' } catch {''})
            DistinguishedName = [string]$object.properties.distinguishedname
            SamAccountName    = [string]$object.properties.samaccountname
            UserPrincipalName = [string]$object.properties.userprincipalname
            Mail              = [string]$object.properties.mail
            ProxyAddresses    = [string[]]$object.properties.proxyaddresses
            EmailServer       = $(try{ [string]$object.properties.msexchhomeservername.split('=')[-1] } catch {''})
            EmailDB           = $(try{ [string]$object.properties.homemdb.split(',')[0] -replace 'cn=' } catch {''})
            OperatingSystem   = [string]$object.properties.operatingsystem
            Description       = [string]$object.properties.description
            Title             = [string]$object.properties.title
            Department        = [string]$object.properties.department
            Manager           = [string]$object.properties.manager
            TelephoneNumber   = [string]$object.properties.telephonenumber
            Mobile            = [string]$object.properties.mobile
            ScriptPath        = [string]$object.properties.scriptpath
            HomeDirectory     = [string]$object.properties.homedirectory
            HomeDrive         = [string]$object.properties.homedrive
            Country1          = [string]$object.properties.c
            Country2          = [string]$object.properties.co
            State             = [string]$object.properties.st
            City              = [string]$object.properties.l
            StreetAddress     = [string]$object.properties.streetaddress
            PostalCode        = [string]$object.properties.postalcode
            Company           = [string]$object.properties.company
            AccountIsLocked   = $(try{ if ((([adsi]$object.path).psbase.InvokeGet('IsAccountLocked')) -eq $true) {$true} else {$false} }catch{''})
            AccountIsDisabled = if (([string]$object.Properties.useraccountcontrol -band 2) -eq 0) {$false} else {$true}
            member            = $object.properties.member | sort
            memberof          = $object.properties.memberof | sort
        }
    }) | select name, displayname, lastname, firstname, objectcategory, grouptype, whencreated, whenchanged, pwdlastset, PwdIsExpired, PwdDoesNotExpire, lastlogon, distinguishedname, samaccountname, userprincipalname, mail, proxyaddresses, emailserver, emaildb, operatingsystem, description, title, department, manager, telephonenumber, mobile, scriptpath, homedirectory, homedrive, country1, country2, state, city, streetaddress, postalcode, company, accountislocked, accountisdisabled, member, memberof
}

<#
$pwdset = get-date '2015/11/16 07:38:01'

$pwdage = (get-date) - $pwdset | select -exp days
$maxage = ([adsi]"WinNT://$env:userdomain").maxpasswordage.value / 86400

'Expired:'
if ($pwdage -gt $maxage) {
    'yes'
} else {
    'no'
}
#>
