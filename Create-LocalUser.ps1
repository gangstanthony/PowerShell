
# http://www.selfadsi.org/ads-attributes/user-userAccountControl.htm

function Create-LocalUser {
    param (
        [string]$computer = $env:computername,
        [string]$fullName,
        [Parameter(mandatory = $true)][string]$username,
        [Parameter(mandatory = $true)][string]$password,
        [switch]$passworDdoesNotExpire,
        [string]$addToGroup = 'Administrators',
        [switch]$CheckFirst = $true
    )

    if ($checkfirst -and ([ADSI]"WinNT://$computer/$username").Name) {
        Write-Warning "$username already exists on $computer"
        return
    }

    $objOU = [ADSI]"WinNT://$computer"
    $objUser = $objOU.Create('user', $username)
    $objUser.SetPassword($password)
    $objUser.SetInfo()
    $objUser.FullName = $fullname
    $objUser.SetInfo()

    if ($passworddoesnotexpire) {
        $objUser.UserFlags = 65536 # password does not expire
        $objUser.SetInfo()
    }

    if ($addtogroup) {
        ([ADSI]"WinNT://$computer/$addtogroup").Add("WinNT://$computer/$username")
    }
}

# Create-LocalUser -computer $env:COMPUTERNAME -fullname 'Test' -username 'test' -password 'Password1' -passworddoesnotexpire -addtogroup 'Administrators'
