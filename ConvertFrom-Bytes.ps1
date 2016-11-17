function ConvertFrom-Bytes {
    param (
        [string]$bytes,
        [string]$savepath
    )

    $dir = Split-Path $savepath
    if (!(Test-Path $dir)) {
        md $dir | Out-Null
    }

    [convert]::FromBase64String($bytes) | Set-Content $savepath -Encoding Byte
}
