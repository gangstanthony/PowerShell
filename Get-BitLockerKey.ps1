function Get-BitLockerKey {
    param (
        [string]$comp = $env:COMPUTERNAME
        #[string]$pwidmatch
    )

    if (!$comp.endswith('$')) {
        $comp += '$'
    }

    $compsearcher = [adsisearcher]"samaccountname=$comp"
    $compsearcher.PageSize = 200
    $compsearcher.PropertiesToLoad.Add('name') | Out-Null
    $compobj = $compsearcher.FindOne().Properties

    if (!$compobj) {
        throw "$comp not found"
    }

    $keysearcher = [adsisearcher]'objectclass=msFVE-RecoveryInformation'
    $keysearcher.SearchRoot = [string]$compobj.adspath.trim()
    $keysearcher.PageSize = 200
    $keysearcher.PropertiesToLoad.AddRange(('name', 'msFVE-RecoveryPassword'))

    $keys = $keysearcher.FindOne().Properties
    if ($keys) {
            $keys | % {
            try{ rv matches -ea stop }catch{}
            ('' + $_.name) -match '^([^\{]+)\{([^\}]+)' | Out-Null
        
            $date = $Matches[1]
            $pwid = $Matches[2]
        
            New-Object psobject -Property @{
                Name = [string]$compobj.name
                Date = $date
                PasswordID = $pwid
                BitLockerKey = [string]$_.'msfve-recoverypassword'
            } | select name, date, passwordid, bitlockerkey
        }
    } else {
        New-Object psobject -Property @{
            Name = [string]$compobj.name
            Date = ''
            PasswordID = ''
            BitLockerKey = ''
        } | select name, date, passwordid, bitlockerkey
    }
}
