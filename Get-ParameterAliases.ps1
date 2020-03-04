function Get-ParameterAliases ($command) {
    $params = (get-command $command).Parameters
    foreach ($key in $params.Keys) {
        $params[$key] | select name, @{n='aliases';e={$_.aliases}}
    }
}
