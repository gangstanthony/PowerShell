# http://www.powershelladmin.com/wiki/Powershell_prompt_for_password_convert_securestring_to_plain_text

function Encode-Text {
    param (
        [string]$Text,
        [validateset('SecureString', 'SecureStringWithKey', 'Base64', 'ASCII')]
        [string]$Method = 'Base64'
    )
    
    switch ($method) {
        'SecureString' {
            Write-Warning "This can only be recovered by '$env:USERNAME' on computer '$env:COMPUTERNAME'"
            ConvertTo-SecureString $text -AsPlainText -Force | ConvertFrom-SecureString
        }

        'SecureStringWithKey' {
            ConvertTo-SecureString $text -AsPlainText -Force | ConvertFrom-SecureString -Key (1..16)
        }

        'Base64' {
            [Convert]::ToBase64String([System.Text.Encoding]::Unicode.GetBytes($Text))
        }

        'ASCII' {
            -join([char[]]$text | % {
                '{0:D3}' -f ([int]$_ - 32)
            })
        }
    }
}
