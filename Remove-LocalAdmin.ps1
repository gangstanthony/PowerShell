function Remove-LocalAdmin {
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

    ([adsi]"WinNT://$comp/Administrators").remove("WinNT://$domain/$sam")
}
