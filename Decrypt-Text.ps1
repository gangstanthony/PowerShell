# http://www.powershelladmin.com/wiki/Powershell_prompt_for_password_convert_securestring_to_plain_text

function Decrypt-Text {
    param (
        [string]$text,
        [validateset('SecureString', 'Base64', 'ASCII')]
        [string]$method = 'Base64'
    )

    if ($method -eq 'SecureString') {
        (New-Object pscredential ' ', (ConvertTo-SecureString $text)).GetNetworkCredential().Password
    } elseif ($method -eq 'Base64') {
        [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($text))
    } elseif ($method -eq 'ASCII') {
        $pwlength = $text.Length / 3 - 1
        -join(0..$pwlength | % {[char](32 + $text.Substring(($_*3), 3))})
    }
}
