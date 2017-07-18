function Add-LocalAdmin {
    param (
        [string]$comp,
        [string]$sam,
        [string]$domain = $env:USERDOMAIN
    )

    if ($comp -match '^\s*$') {
        throw "Comp not found '$comp'"
    }

    if ($sam -match '^\s*$') {
        throw "Sam not acceptable '$sam'"
    }

    ([adsi]"WinNT://$comp/Administrators").add("WinNT://$domain/$sam")
}
