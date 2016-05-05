# http://superuser.com/questions/502374/equivalent-of-linux-touch-to-create-an-empty-file-with-powershell

function touch {
    $file = $args[0]

    if ($file -eq $null) {
        throw "No filename supplied"
    }

    if (Test-Path $file) {
        (Get-ChildItem $file).LastWriteTime = Get-Date
    } else {
        echo $null > $file
    }
}
