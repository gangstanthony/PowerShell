function Encrypt-Text {
    param (
        [string]$text,
        [validateset('SecureString', 'Base64', 'ASCII')]
        [string]$method = 'Base64'
    )
    
    if ($method -eq 'SecureString') {
        $text | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString -Key (1..16)
    } elseif ($method -eq 'Base64') {
        [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($Text))
    } elseif ($method -eq 'ASCII') {
        -join([char[]]$text | % {
            '{0:D3}' -f ([int]$_ - 32)
        })
    }
}
