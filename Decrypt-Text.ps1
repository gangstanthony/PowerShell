function Decrypt-Text {
    param (
        [string]$text,
        [validateset('SecureString', 'Base64', 'ASCII')]
        [string]$method = 'Base64'
    )

    if ($method -eq 'SecureString') {
        (New-Object pscredential -ArgumentList ' ', ($text | ConvertTo-SecureString -Key (1..16))).GetNetworkCredential().Password
    } elseif ($method -eq 'Base64') {
        [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($text))
    } elseif ($method -eq 'ASCII') {
        $pwlength = $text.Length / 3 - 1
        -join(0..$pwlength | % {[char](32 + $text.Substring(($_*3), 3))})
    }
}
