# http://superuser.com/questions/502374/equivalent-of-linux-touch-to-create-an-empty-file-with-powershell

function touch ([string]$file) {
    if ($file -eq $null) {
        throw "No filename supplied"
    }

    $dir = Split-Path $file

    if (Test-Path $file) {
        (Get-ChildItem $file).LastWriteTime = Get-Date
    } elseif (Test-Path $dir) {
        $null = mkdir $dir -ErrorAction Continue
        echo $null > $file
    }
}
