function Logoff-User ($Name, $Server) {
    if (!(gcm quser -ea 0)) {
        throw 'could not find quser.exe'
    }

    $users = quser /server:$Server | select -Skip 1
    
    if ($Name) {
        $user = $users | ? {$_ -match $Name}
    } else {
        $user = $users | Out-Menu
    }

    $id = ($user.split() | ? {$_})[2]

    if ($id -match 'disc') {
        $id = ($user.split() | ? {$_})[1]
    }

    logoff $id /server:$Server
}
