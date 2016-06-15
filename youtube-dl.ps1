function ydl {
    param (
        [string]$url = $(get-clipboard),
        [switch]$u,
        [string]$ydlpath = 'C:\Users\anthony.stringer\Dropbox\Documents\PSScripts\youtube\youtube-dl.exe',
        [validateset('audio', 'video')]
        [string]$type = 'audio'
    )
    
    if ($u) {
        start $ydlpath -ArgumentList '--update'
    }
    
    if (!(Test-Path c:\temp)) {md c:\temp | Out-Null}
    cd c:\temp

    if ($url -match 'playlist') {
        if ($type -eq 'video') {
            . $ydlpath -wick -o '%(autonumber)s %(title)s.%(ext)s' $url
        } elseif ($type -eq 'audio') {
            . $ydlpath --extract-audio --audio-format mp3 -wic -o '%(title)s.%(ext)s' -f 17 $url
        }
    } elseif ($url -match 'youtube') {
        if ($type -eq 'video') {
            . $ydlpath -wick -o '%(title)s.%(ext)s' $url
        } elseif ($type -eq 'audio') {
            . $ydlpath --extract-audio --audio-format mp3 -wic -o '%(title)s.%(ext)s' -f 17 $url
        }
    } elseif ($url -match 'soundcloud') {
        . $ydlpath -wic -o '%(title)s.%(ext)s' $url
    }
}
