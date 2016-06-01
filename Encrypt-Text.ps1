# http://www.powershelladmin.com/wiki/Powershell_prompt_for_password_convert_securestring_to_plain_text

function Encrypt-Text {
    param (
        [string]$text,
        [validateset('SecureString', 'Base64', 'ASCII')]
        [string]$method = 'Base64'
    )
    
    if ($method -eq 'SecureString') {
        ConvertTo-SecureString $text -AsPlainText -Force | ConvertFrom-SecureString
    } elseif ($method -eq 'Base64') {
        [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($Text))
    } elseif ($method -eq 'ASCII') {
        -join([char[]]$text | % {
            '{0:D3}' -f ([int]$_ - 32)
        })
    }
}
