function ydl {
    param (
        [string]$song = $(get-clipboard),
        [switch]$u,
        [string]$ydlpath = 'C:\Users\admin\Dropbox\Documents\PSScripts\youtube\youtube-dl.exe'
    )
    
    if ($u) {
        start $ydlpath -ArgumentList '--update'
    }
    
    if (!(Test-Path c:\temp)) {md c:\temp | Out-Null}
    cd c:\temp

    if ($song -match 'playlist') {
        . $ydlpath -wick -o '%(autonumber)s %(title)s.%(ext)s' $song
    } elseif ($song -match 'youtube') {
        . $ydlpath --extract-audio --audio-format mp3 -o '%(title)s.%(ext)s' -f 17 $song
    } elseif ($song -match 'soundcloud') {
        . $ydlpath $song -o '%(title)s.%(ext)s'
    }
}
