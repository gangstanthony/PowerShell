# http://superuser.com/questions/502374/equivalent-of-linux-touch-to-create-an-empty-file-with-powershell

function touch {
    param (
        [string]$file,
        $date = '' # 2015-01-01
    )

    if ($file -eq $null) {
        throw 'No filename supplied'
    }

    if (!$date) {
        $date = Get-Date
    } else {
        $date = Get-Date $date
    }

    $dir = Split-Path $file

    if (Test-Path $file) {
        (Get-Item $file).LastWriteTime = [datetime]$date
    } elseif ($dir -and !(Test-Path -LiteralPath $dir)) {
        $null = mkdir $dir
        $null = New-Item $file -ItemType File
    } else {
        $null = New-Item $file -ItemType File
    }
}
