# requires c:\pstools\psexec.exe

function Get-BitLockerInfo {
    param (
        $ComputerName = $env:COMPUTERNAME
    )
    
    $comp = [pscustomobject]@{
        Name = $ComputerName
        OS = Get-Os $ComputerName
    }

    $comp = $comp | select *,
        @{n='User';e={''}},
        @{n='BitLocker Drive Encryption';e={''}},
        @{n='BitLocker Version';e={''}},
        @{n='Conversion Status';e={''}},
        @{n='Encryption Method';e={''}},
        @{n='Identification Field';e={''}},
        @{n='Key Protectors';e={''}},
        @{n='Lock Status';e={''}},
        @{n='Percentage Encrypted';e={''}},
        @{n='Protection Status';e={''}},
        @{n='Size';e={''}},
        @{n='Volume C';e={''}}

    # manage-bde -status c: -computername $comp.name # can't use because of the context it says manage-bde not found
    $bitlockerinfo = (c:\pstools\PsExec.exe \\$($comp.name) manage-bde -status c:).Split("`n").trim() | ? {$_ -and $_ -notmatch '^(\s+)?$'}
    $hash = @{}
    $bitlockerinfo | ? {$_ -match '[a-z]:\s'} | % {
        $split = $_.split(':').trim()
        if ($split[0] -match '^volume') {
            $split[1] = $bitlockerinfo[$bitlockerinfo.indexof($_) + 1]
        }
        $hash.add($split[0], $split[1])
    }
    $bitlockerinfo = [pscustomobject]$hash

    $comp.User = Get-User $comp.name
    $comp.'BitLocker Drive Encryption' = $bitlockerinfo.'BitLocker Drive Encryption'
    $comp.'BitLocker Version' = $bitlockerinfo.'BitLocker Version'
    $comp.'Conversion Status' = $bitlockerinfo.'Conversion Status'
    $comp.'Encryption Method' = $bitlockerinfo.'Encryption Method'
    $comp.'Identification Field' = $bitlockerinfo.'Identification Field'
    $comp.'Key Protectors' = $bitlockerinfo.'Key Protectors'
    $comp.'Lock Status' = $bitlockerinfo.'Lock Status'
    $comp.'Percentage Encrypted' = $bitlockerinfo.'Percentage Encrypted'
    $comp.'Protection Status' = $bitlockerinfo.'Protection Status'
    $comp.Size = $bitlockerinfo.Size
    $comp.'Volume C' = $bitlockerinfo.'Volume C'

    $comp
}
