# https://knowledge.zomers.eu/PowerShell/Pages/How-to-control-UserAccountControl-Active-Directory-flags-with-PowerShell.aspx

function Check-Flags ($sam = $env:USERNAME) {
    $uac = [int](([adsisearcher]"samaccountname=$sam").FindOne().Properties.useraccountcontrol | Out-String).Trim()

    if ($uac -eq 0) {
        throw 'UAC is 0'
    }

    $flags = @{
        SCRIPT = 1
        ACCOUNTDISABLE = 2
        HOMEDIR_REQUIRED = 8
        LOCKOUT = 16
        PASSWD_NOTREQD = 32
        # Note You cannot assign this permission by directly modifying the UserAccountControl attribute. For information about how to set the permission programmatically, see the "Property flag descriptions" section. 
        PASSWD_CANT_CHANGE = 64
        ENCRYPTED_TEXT_PWD_ALLOWED = 128
        TEMP_DUPLICATE_ACCOUNT = 256
        NORMAL_ACCOUNT = 512
        INTERDOMAIN_TRUST_ACCOUNT = 2048
        WORKSTATION_TRUST_ACCOUNT = 4096
        SERVER_TRUST_ACCOUNT = 8192
        DONT_EXPIRE_PASSWORD = 65536
        MNS_LOGON_ACCOUNT = 131072
        SMARTCARD_REQUIRED = 262144
        TRUSTED_FOR_DELEGATION = 524288
        NOT_DELEGATED = 1048576
        USE_DES_KEY_ONLY = 2097152
        DONT_REQ_PREAUTH = 4194304
        PASSWORD_EXPIRED = 8388608
        TRUSTED_TO_AUTH_FOR_DELEGATION = 16777216
        PARTIAL_SECRETS_ACCOUNT = 67108864
    }

    $hash = New-Object System.Collections.Specialized.OrderedDictionary
    $hash.Add('SAM', $sam)
    $hash.Add('UAC', $uac)

    foreach ($key in $flags.Keys) {
        if (($uac -band $flags[$key]) -ne 0) {
            $hash.Add($key, $true)
        } else {
            $hash.Add($key, $false)
        }
    }

    New-Object psobject -Property $hash
}
