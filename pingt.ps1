# pingt 8.8.8.8 -t

# ping forever and show the time of ping

function pingt {
    param(
        [Parameter(ValueFromPipeline=$true)]
        $comp = $env:COMPUTERNAME,
        $n = 4,
        [switch]$t
    )
    if (!$comp) {Throw 'No host provided'}

    function callping {
        sleep 1
        Write-Host $(Get-Date -f 'yyyy/MM/dd HH:mm:ss ') -NoNewline
        ping1 $comp -showhost | Microsoft.PowerShell.Core\Out-Default
    }

    if ($t) {
        while (1) {
            callping
        }
    } else {
        for ($i = 0; $i -lt $n; $i++) {
            callping
        }
    }
}
