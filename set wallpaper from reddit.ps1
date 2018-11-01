# http://www.culham.net/powershell/changing-desktop-wallpaper-using-windows-powershell/

# https://www.reddit.com/r/PowerShell/comments/8l9fgf/changing_wallpaper_with_powershell/

# "sometimes" working alt
# https://www.reddit.com/r/PowerShell/comments/5ske2m/setwallpaper/

# in order of top-week results returned as of now.
# trying to keep these SFW, but reddit is like a box of chocolates.
$subReddit = @(
    # prefer
    'EarthPorn'     # 25

    # testing
    #'spaceporn'     # 25
    'SkyPorn'       # 25
    'BotanicalPorn' # 20
    'waterporn'     # 19
    'VillagePorn'   # 16
    'Beachporn'     # 9
    'lakeporn'      # 1

    # not prefer
    #'CityPorn'      # 25
    #'wallpaper'     # 25
    #'wallpapers'    # 25
    #'WeatherPorn'   # 9
    #'multiwall'     # 9
)

$dstfile = "c:\reddit\wpp_$(date -f yyyyMMdd-HHmmss).jpg"

if (!(Test-Path $(Split-Path $dstfile))) {
    md $(Split-Path $dstfile) | Out-Null
}

# grabs top 25 images of the week from each sub, then picks one at random
##### * WARNING * this really doesn't work for some subs (villageporn), and i have no idea why #####
$images = foreach ($sub in $subReddit) {
    $links = Invoke-RestMethod https://www.reddit.com/r/$sub/top/.json -Method Get -Body @{limit='25'} | % {$_.data.children.data.url} | ? {$_ -match '\.jpe?g$'}
    $links
    Write-Host "$sub = $(@($links).count)"
}

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
        sleep -ms 200
        [Wallpaper.Setter]::SetWallpaper($Path, $StyleNum[$Style])
    }
}

Set-WallPaper -Path $dstfile -Style Fill

#####
# set lock screen (requires admin)
# https://www.reddit.com/r/PowerShell/comments/5fglby/powershell_to_set_windows_10_lockscreen/daoepvj/
#####

if (!(New-Object Security.Principal.WindowsPrincipal ([Security.Principal.WindowsIdentity]::GetCurrent())).IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)) {
    Write-Host 'you are not admin' -ForegroundColor Red
    return
}

# take ownership
& $env:systemRoot\system32\takeown.exe /F $env:programData\Microsoft\Windows\SystemData /R /A /D Y
& $env:systemRoot\system32\icacls.exe $env:programData\Microsoft\Windows\SystemData /grant Administrators:`(OI`)`(CI`)F /T
& $env:systemRoot\system32\icacls.exe $env:programData\Microsoft\Windows\SystemData\S-1-5-18\ReadOnly /reset /T

# delete files
del $env:programData\Microsoft\Windows\SystemData\S-1-5-18\ReadOnly\LockScreen_Z\* -Force

# take ownership
& $env:systemRoot\system32\takeown.exe /F $env:systemRoot\Web\Screen /R /A /D Y
& $env:systemRoot\system32\icacls.exe $env:systemRoot\Web\Screen /grant Administrators:`(OI`)`(CI`)F /T
& $env:systemRoot\system32\icacls.exe $env:systemRoot\Web\Screen /reset /T

# replace files
copy $env:systemRoot\Web\Screen\img100.jpg $env:systemRoot\Web\Screen\img200.jpg -Force
copy $dstfile $env:systemRoot\Web\Screen\img100.jpg -Force

#del $dstfile

