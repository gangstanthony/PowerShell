# https://serverfault.com/questions/429240/how-do-you-manage-network-locations-through-domain-group-policies

function Remove-NetworkShortcut {
    param (
        [string]$Name,
        [string]$ComputerName = $env:COMPUTERNAME,
        [string]$SAM = $env:USERNAME
    )
    $networkshortcuts_path = "\\$ComputerName\c$\users\$SAM\AppData\Roaming\Microsoft\Windows\Network Shortcuts"
    $path = join-path $networkshortcuts_path $name
    if (Test-Path $path) {
        del $path -Recurse -Force
    }
}
