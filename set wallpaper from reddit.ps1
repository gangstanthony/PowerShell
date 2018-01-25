# http://www.culham.net/powershell/changing-desktop-wallpaper-using-windows-powershell/

# "sometimes" working alt
# https://www.reddit.com/r/PowerShell/comments/5ske2m/setwallpaper/

$subReddit = 'earthporn'
$dstfile = "c:\temp\wpp $(date -f yyyyMMdd-HHmmss).jpg"

if (!(Test-Path $(Split-Path $dstfile))) {
    md $(Split-Path $dstfile) | Out-Null
}

$images = Invoke-RestMethod https://www.reddit.com/r/$subReddit/.json -Method Get -Body @{limit='100'} | % {$_.data.children.data.url} | ? {$_ -match '\.jpg$'}
$image = $images | random

Invoke-WebRequest $image -OutFile $dstfile


function Set-Wallpaper {
    param (
        [string]$Path,
        [ValidateSet('Tile', 'Center', 'Stretch', 'Fill', 'Fit', 'Span')]
        [string]$Style = 'Fill'
    )

    begin {
        try {
            Add-Type @"
            using System;
            using System.Runtime.InteropServices;
            using Microsoft.Win32;
            namespace Wallpaper
            {
	            public enum Style : int
	            {
		            Tile, Center, Stretch, Fill, Fit, Span, NoChange
	            }
	
	            public class Setter
                {
		            public const int SetDesktopWallpaper = 20;
		            public const int UpdateIniFile = 0x01;
		            public const int SendWinIniChange = 0x02;
		            [DllImport( "user32.dll", SetLastError = true, CharSet = CharSet.Auto )]
		            private static extern int SystemParametersInfo ( int uAction, int uParam, string lpvParam, int fuWinIni );
		            public static void SetWallpaper ( string path, Wallpaper.Style style )
                    {
			            SystemParametersInfo( SetDesktopWallpaper, 0, path, UpdateIniFile | SendWinIniChange );
			            RegistryKey key = Registry.CurrentUser.OpenSubKey( "Control Panel\\Desktop", true );
			            switch( style )
			            {
				            case Style.Tile :
				            key.SetValue( @"WallpaperStyle", "0" ) ;
				            key.SetValue( @"TileWallpaper", "1" ) ;
				            break;
				            case Style.Center :
				            key.SetValue( @"WallpaperStyle", "0" ) ;
				            key.SetValue( @"TileWallpaper", "0" ) ;
				            break;
				            case Style.Stretch :
				            key.SetValue( @"WallpaperStyle", "2" ) ;
				            key.SetValue( @"TileWallpaper", "0" ) ;
				            break;
				            case Style.Fill :
				            key.SetValue( @"WallpaperStyle", "10" ) ;
				            key.SetValue( @"TileWallpaper", "0" ) ;
				            break;
				            case Style.Fit :
				            key.SetValue( @"WallpaperStyle", "6" ) ;
				            key.SetValue( @"TileWallpaper", "0" ) ;
				            break;
				            case Style.Span :
				            key.SetValue( @"WallpaperStyle", "22" ) ;
				            key.SetValue( @"TileWallpaper", "0" ) ;
				            break;
				            case Style.NoChange :
				            break;
			            }
			            key.Close();
		            }
	            }
            }
"@
        } catch {}
    
        $StyleNum = @{
            Tile = 0
            Center = 1
            Stretch = 2
            Fill = 3
            Fit = 4
            Span = 5
        }
    }

    process {
        [Wallpaper.Setter]::SetWallpaper($Path, $StyleNum[$Style])

        # sometimes the wallpaper only changes after the second run, so I'll run it twice!
        [Wallpaper.Setter]::SetWallpaper($Path, $StyleNum[$Style])
    }
}

Set-WallPaper -Path $dstfile -Style Fill

#####
# set lock screen (requires admin)
# https://www.reddit.com/r/PowerShell/comments/5fglby/powershell_to_set_windows_10_lockscreen/daoepvj/
#####

if ((New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    <#
    Start-Process -filePath "$env:systemRoot\system32\takeown.exe" -ArgumentList "/F `"$env:programData\Microsoft\Windows\SystemData`" /R /A /D Y" -NoNewWindow -Wait
    Start-Process -filePath "$env:systemRoot\system32\icacls.exe" -ArgumentList "`"$env:programData\Microsoft\Windows\SystemData`" /grant Administrators:(OI)(CI)F /T" -NoNewWindow -Wait
    Start-Process -filePath "$env:systemRoot\system32\icacls.exe" -ArgumentList "`"$env:programData\Microsoft\Windows\SystemData\S-1-5-18\ReadOnly`" /reset /T" -NoNewWindow -Wait
    Remove-Item -Path "$env:programData\Microsoft\Windows\SystemData\S-1-5-18\ReadOnly\LockScreen_Z\*" -Force
    Start-Process -filePath "$env:systemRoot\system32\takeown.exe" -ArgumentList "/F `"$env:systemRoot\Web\Screen`" /R /A /D Y" -NoNewWindow -Wait
    Start-Process -filePath "$env:systemRoot\system32\icacls.exe" -ArgumentList "`"$env:systemRoot\Web\Screen`" /grant Administrators:(OI)(CI)F /T" -NoNewWindow -Wait
    Start-Process -filePath "$env:systemRoot\system32\icacls.exe" -ArgumentList "`"$env:systemRoot\Web\Screen`" /reset /T" -NoNewWindow -Wait
    Copy-Item -Path "$env:systemRoot\Web\Screen\img100.jpg" -Destination "$env:systemRoot\Web\Screen\img200.jpg" -Force
    Copy-Item -Path $dstfile -Destination "$env:systemRoot\Web\Screen\img100.jpg" -Force
    #>

    . $env:systemRoot\system32\takeown.exe /F $env:programData\Microsoft\Windows\SystemData /R /A /D Y
    . $env:systemRoot\system32\icacls.exe $env:programData\Microsoft\Windows\SystemData /grant Administrators:`(OI`)`(CI`)F /T
    . $env:systemRoot\system32\icacls.exe $env:programData\Microsoft\Windows\SystemData\S-1-5-18\ReadOnly /reset /T
    del $env:programData\Microsoft\Windows\SystemData\S-1-5-18\ReadOnly\LockScreen_Z\* -Force
    . $env:systemRoot\system32\takeown.exe /F $env:systemRoot\Web\Screen /R /A /D Y
    . $env:systemRoot\system32\icacls.exe $env:systemRoot\Web\Screen /grant Administrators:`(OI`)`(CI`)F /T
    . $env:systemRoot\system32\icacls.exe $env:systemRoot\Web\Screen /reset /T
    copy $env:systemRoot\Web\Screen\img100.jpg $env:systemRoot\Web\Screen\img200.jpg -Force
    copy $dstfile $env:systemRoot\Web\Screen\img100.jpg -Force
} else {
    Write-Host 'you are not admin' -ForegroundColor Red
}

#del $dstfile
