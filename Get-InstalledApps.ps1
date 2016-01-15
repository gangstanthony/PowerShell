function Get-InstalledApps {
	param (
        [Parameter(ValueFromPipeline=$true)]
		[string[]]$comps = $env:COMPUTERNAME
	)
    
    foreach ($comp in $comps) {
        $keys = '','\Wow6432Node'
        foreach ($key in $keys) {
            $apps = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$comp).OpenSubKey("SOFTWARE$key\Microsoft\Windows\CurrentVersion\Uninstall").GetSubKeyNames()
            foreach ($app in $apps) {
                $name = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$comp).OpenSubKey("SOFTWARE$key\Microsoft\Windows\CurrentVersion\Uninstall\$app").GetValue('DisplayName')
                if ($name) {
                    New-Object PSObject -Property @{
                        'DisplayName'     = $name
                        'DisplayVersion'  = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$comp).OpenSubKey("SOFTWARE$key\Microsoft\Windows\CurrentVersion\Uninstall\$app").GetValue('DisplayVersion')
                        'Publisher'       = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$comp).OpenSubKey("SOFTWARE$key\Microsoft\Windows\CurrentVersion\Uninstall\$app").GetValue('Publisher')
                        'InstallDate'     = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$comp).OpenSubKey("SOFTWARE$key\Microsoft\Windows\CurrentVersion\Uninstall\$app").GetValue('InstallDate')
                        'UninstallString' = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey('LocalMachine',$comp).OpenSubKey("SOFTWARE$key\Microsoft\Windows\CurrentVersion\Uninstall\$app").GetValue('UninstallString')
                    }
                }
            }
        }
    }
}
