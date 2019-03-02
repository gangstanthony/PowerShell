# http://powershell.org/forums/topic/creating-a-array-of-info-for-remote-computers/#post-37990
# https://www.reddit.com/r/PowerShell/comments/4gvfdg/noob_tech_question_how_would_i_query_all_domain/

function Get-OfficeVersion ($computer = $env:COMPUTERNAME) {
    $version = 0
 
    $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $computer)

    try {
        $reg.OpenSubKey('SOFTWARE\Microsoft\Office').GetSubKeyNames() | % {
            if ($_ -match '(\d+)\.') {
                if ([int]$matches[1] -gt $version) {
                    $version = $matches[1]
                }
            }
        }
    } catch {}
 
    $version
}
