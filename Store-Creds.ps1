# http://bsonposh.com/archives/338

function Store-Creds ($pwfile = "c:\temp\$env:USERNAME.txt") {
    $Credential = Get-Credential -Credential $env:USERNAME
    $Credential.Password | ConvertFrom-SecureString | Set-Content $pwfile
}

function Get-Creds ($User = $env:USERNAME, $pwfile = "c:\temp\$env:USERNAME.txt") {
    if (Test-Path $pwfile) {
        $Password = Get-Content $pwfile | ConvertTo-SecureString
        $Credential = New-Object System.Management.Automation.PsCredential -ArgumentList $User, $Password
        $Credential
    }
}
