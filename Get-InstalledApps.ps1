# a more complete script can be found here:
# https://gist.github.com/indented-automation/32efb05a5fb67ef9eed02bbb8fe90691
# https://community.spiceworks.com/scripts/show_download/2170-get-a-list-of-installed-software-from-a-remote-computer-fast-as-lightning

# note: might have to use enable-psremoting first if no results are returned

<#
friends don't let friends use win32_product to query for installed programs
https://sdmsoftware.com/group-policy-blog/wmi/why-win32_product-is-bad-news/
https://blogs.technet.microsoft.com/heyscriptingguy/2011/12/14/use-powershell-to-find-and-uninstall-software/
https://blogs.technet.microsoft.com/heyscriptingguy/2011/11/13/use-powershell-to-quickly-find-installed-software/
http://powershell.org/wp/forums/topic/alternatives-to-win32_product/
this is what i use to get installed programs
https://github.com/gangstanthony/PowerShell/blob/master/Get-InstalledApps.ps1
example usage
    Get-InstalledApps -ComputerName $env:COMPUTERNAME -NameRegex '^java'
you will get an uninstallstring returned from that as well. you can use one of the methods below to run the uninstaller on the remote computer
https://www.reddit.com/r/PowerShell/comments/4l5kkm/what_are_all_or_at_least_the_most_common_ways_to/
#>

function Get-InstalledApps {
    param (
        [Parameter(ValueFromPipeline=$true)]
        [string[]]$ComputerName = $env:COMPUTERNAME,
        [string]$NameRegex = ''
    )
    
    foreach ($comp in $ComputerName) {
        $keys = '','\Wow6432Node'
        foreach ($key in $keys) {
            try {
                $reg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine', $comp)
                $apps = $reg.OpenSubKey("SOFTWARE$key\Microsoft\Windows\CurrentVersion\Uninstall").GetSubKeyNames()
            } catch {
                continue
            }

            foreach ($app in $apps) {
                $program = $reg.OpenSubKey("SOFTWARE$key\Microsoft\Windows\CurrentVersion\Uninstall\$app")
                $name = $program.GetValue('DisplayName')
                if ($name -and $name -match $NameRegex) {
                    [pscustomobject]@{
                        ComputerName = $comp
                        DisplayName = $name
                        DisplayVersion = $program.GetValue('DisplayVersion')
                        Publisher = $program.GetValue('Publisher')
                        InstallDate = $program.GetValue('InstallDate')
                        UninstallString = $program.GetValue('UninstallString')
                        Bits = $(if ($key -eq '\Wow6432Node') {'64'} else {'32'})
                        Path = $program.name
                    }
                }
            }
        }
    }
}
