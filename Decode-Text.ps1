# http://www.powershelladmin.com/wiki/Powershell_prompt_for_password_convert_securestring_to_plain_text

function Decode-Text {
    param (
        [string]$Text,
        [validateset('SecureString', 'SecureStringWithKey', 'Base64', 'ASCII')]
        [string]$Method = 'Base64'
    )

    if ($method -eq 'SecureString') {
        (New-Object pscredential ' ', (ConvertTo-SecureString $text)).GetNetworkCredential().Password
    } elseif ($method -eq 'SecureStringWithKey') {
        (New-Object pscredential ' ', (ConvertTo-SecureString $text -Key (1..16))).GetNetworkCredential().Password
    } elseif ($method -eq 'Base64') {
        [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($text))
    } elseif ($method -eq 'ASCII') {
        $pwlength = $text.Length / 3 - 1
        -join(0..$pwlength | % {[char](32 + $text.Substring(($_*3), 3))})
    }
}
