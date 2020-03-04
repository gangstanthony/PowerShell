function get-parameteraliases ($command) {
    (Get-Command $command).parameters.values | select name, @{n='aliases';e={$_.aliases}}
}
