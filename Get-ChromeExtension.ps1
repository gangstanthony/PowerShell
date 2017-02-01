# https://www.reddit.com/r/PowerShell/comments/5px71w/getting_chrome_extensions/

function Get-ChromeExtension {
    param (
        [string]$ComputerName = $env:COMPUTERNAME
    )

    Get-ChildItem "\\$ComputerName\c$\users\*\appdata\local\Google\Chrome\User Data\Default\Extensions\*\*\manifest.json" -ErrorAction SilentlyContinue | % {
        $_.FullName -match 'users\\(.*?)\\appdata' | Out-Null
        Get-Content $_.FullName -Raw | ConvertFrom-Json | select @{n='ComputerName';e={$ComputerName}}, @{n='User';e={$Matches[1]}}, name, version
    }
}
