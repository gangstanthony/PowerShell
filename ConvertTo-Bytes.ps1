function ConvertTo-Bytes {
    param (
        [string]$file
    )

    if (!$file -or !(Test-Path $file)) {
        throw "file not found: '$file'"
    }

    [convert]::ToBase64String((Get-Content $file -Encoding Byte))
}
