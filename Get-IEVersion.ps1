# http://powershell.org/wp/forums/topic/creating-a-array-of-info-for-remote-computers/#post-37990

function Get-IEVersion ($computer = $env:COMPUTERNAME) {
    $version = 0
    
    $keyname = 'SOFTWARE\Microsoft\Internet Explorer'
     
    $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $computer)
    $key = $reg.OpenSubkey($keyname)
    
    try {
        $version = $key.GetValue('Version')
        $svcUpdateVersion = $key.GetValue('svcUpdateVersion')
        #$svcKBNumber = $key.Getvalue('svcKBNumber')
    } catch {}

    if ($svcUpdateVersion) {
        $svcUpdateVersion
    } else {
        $version
    }

    #[pscustomobject]@{
    #    ComputerName = $computer
    #    IEVersion = $version
    #    SvcUpdateVersion = $svcUpdateVersion
    #    KB_Number = $svcKBNumber
    #}
}
