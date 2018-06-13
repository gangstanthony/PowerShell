# http://www.culham.net/powershell/changing-desktop-wallpaper-using-windows-powershell/

# makes use of Resolve-FullPath by Aaron Jensen
# https://www.powershellgallery.com/packages/Carbon/1.9.0/Content/Path%5CResolve-FullPath.ps1

# "sometimes" working alt
# https://www.reddit.com/r/PowerShell/comments/5ske2m/setwallpaper/

# Script to change the desktop wallpaper depending on the resolution of the monitor.
# Change the resolution at the bottom of this script to your first resolution and provide the wallpaper name
# If the script detects a different resolution, it will load and display the second wallpaper.
# 0: Tile 1: Center 2: Stretch 3: Fill 4: Fit 5: Span 6: No Change

function Set-Wallpaper {
    param (
        [string]$Path,
        [ValidateSet('Tile', 'Center', 'Stretch', 'Fill', 'Fit', 'Span')]
        [string]$Style = 'Fill'
    )

    begin {
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
        public class Setter {
        public const int SetDesktopWallpaper = 20;
        public const int UpdateIniFile = 0x01;
        public const int SendWinIniChange = 0x02;
        [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
        private static extern int SystemParametersInfo (int uAction, int uParam, string lpvParam, int fuWinIni);
        public static void SetWallpaper ( string path, Wallpaper.Style style ) {
        SystemParametersInfo( SetDesktopWallpaper, 0, path, UpdateIniFile | SendWinIniChange );
        RegistryKey key = Registry.CurrentUser.OpenSubKey("Control Panel\\Desktop", true);
        switch( style )
        {
        case Style.Tile :
        key.SetValue(@"WallpaperStyle", "0") ;
        key.SetValue(@"TileWallpaper", "1") ;
        break;
        case Style.Center :
        key.SetValue(@"WallpaperStyle", "0") ;
        key.SetValue(@"TileWallpaper", "0") ;
        break;
        case Style.Stretch :
        key.SetValue(@"WallpaperStyle", "2") ;
        key.SetValue(@"TileWallpaper", "0") ;
        break;
        case Style.Fill :
        key.SetValue(@"WallpaperStyle", "10") ;
        key.SetValue(@"TileWallpaper", "0") ;
        break;
        case Style.Fit :
        key.SetValue(@"WallpaperStyle", "6") ;
        key.SetValue(@"TileWallpaper", "0") ;
        break;
        case Style.Span :
        key.SetValue(@"WallpaperStyle", "22") ;
        key.SetValue(@"TileWallpaper", "0") ;
        break;
        case Style.NoChange :
        break;
        }
        key.Close();
        }
        }
        }
"@

        $StyleNum = @{
            Tile = 0
            Center = 1
            Stretch = 2
            Fill = 3
            Fit = 4
            Span = 5
        }

        function Resolve-FullPath {
            [CmdletBinding()]
            param (
                [Parameter(Mandatory=$true)]
                [string]
                # The path to resolve. Must be rooted, i.e. have a drive at the beginning.
                $Path = $(Throw 'No path provided.')
            )
    
            if ( -not ([IO.Path]::IsPathRooted($Path)) ) {
                # $Path = "$PWD\$Path"
                $Path = Join-Path (Get-Location) $Path
            }
            [IO.Path]::GetFullPath($Path)
        }
    }

    process {
        [Wallpaper.Setter]::SetWallpaper($Path, $StyleNum[$Style])
        [Wallpaper.Setter]::SetWallpaper($Path, $StyleNum[$Style])
    }
}
