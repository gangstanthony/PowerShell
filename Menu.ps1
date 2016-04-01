# https://www.reddit.com/r/PowerShell/comments/4ad8or/create_user_menus_from_objectsarrays/
# https://www.reddit.com/r/PowerShell/comments/49tqgx/need_some_help_with_an_automation_script_im/

function Menu {
    param (
        [object[]]$Object,
        $Prompt
    )

    if (!$object) { Throw 'Must provide an object.' }
    $ok = $false
    Write-Host ''

    do {
        if ($prompt) { Write-Host $prompt }

        for ($i = 0; $i -lt $object.count; $i++) {
            Write-Host $i`. $object[$i]
        }

        Write-Host ''

        $answer = Read-Host

        if ($answer -in 0..($object.count-1)) {
            $object[$answer]
            $ok = $true
        } else {
            Write-Host 'Not an option!' -ForegroundColor Red
            Write-Host ''
        }
    } while (!$ok)
}
