# requires psexec

function Get-BitLockerInfo {
    param (
        [string]$ComputerName = $env:COMPUTERNAME,
        [string]$PsExecPath = 'C:\pstools\psexec.exe'
    )

    # Test connectivity before attempting to connect
    if (Test-Connection -ComputerName $ComputerName -Quiet -Count 2) {
        try{
            $user = (Get-WmiObject -Class Win32_ComputerSystem -ComputerName $ComputerName ).UserName
        }
        catch {
            $user = 'UNKNOWN'
        }

        $hash = [ordered]@{
            'ComputerName' = $ComputerName
            'User'         = $user
        }

        # manage-bde -status c: -computername $comp.name # can't use because of the context it says manage-bde not found
        # With this parsing of the output of 'manage-bde' we ensure it works on systems using languages other than English, and it's more robust and efficient in general
        $bitlockerinfo = (& $PsExecPath \\$ComputerName manage-bde -status c:) -replace ':','=' | Where-Object { $_ -match "^(\s{4})" } | ConvertFrom-StringData
        
        foreach ($key in $bitlockerinfo.Keys) {
            $hash.Add("$key", $bitlockerinfo."$key")
        }

        # return the created object
        [PSCustomObject]$hash

    } else {
        Write-Error "Could not reach target computer: '$ComputerName'."
    }
}
