# http://www.powershelladmin.com/wiki/Powershell_prompt_for_password_convert_securestring_to_plain_text
# http://poshcode.org/116

# also see
# https://www.reddit.com/r/PowerShell/comments/5zio13/looking_for_a_method_of_encrypting_a_command_not/deyempf/

function Encode-Text {
    param (
        [string]$Text,
        [validateset('SecureString', 'SecureStringWithKey', 'Base64', 'ASCII')]
        [string]$Method = 'Base64'
    )

    process {
        if (!$Text) {
            $Text = $input
        }
    }
    
    end{
        switch ($method) {
            # only recoverable by same user on same computer
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

            # only works with letters
            'ASCII' {
                -join([char[]]$text | % {
                    '{0:D3}' -f ([int]$_ - 32)
                })
            }
        }
    }
}
