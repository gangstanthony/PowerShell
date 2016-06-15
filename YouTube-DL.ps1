function ydl {
    param (
        [string]$song = $(get-clipboard),
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

    if ($song -match 'playlist') {
        if ($type -eq 'video') {
            . $ydlpath -wick -o '%(autonumber)s %(title)s.%(ext)s' $song
        } elseif ($type -eq 'audio') {
            . $ydlpath --extract-audio --audio-format mp3 -wico '%(title)s.%(ext)s' -f 17 $song
        }
    } elseif ($song -match 'youtube') {
        if ($type -eq 'video') {
            . $ydlpath -wick '%(title)s.%(ext)s' $song
        } elseif ($type -eq 'audio') {
            . $ydlpath --extract-audio --audio-format mp3 -wico '%(title)s.%(ext)s' -f 17 $song
        }
    } elseif ($song -match 'soundcloud') {
        . $ydlpath $song -wico '%(title)s.%(ext)s'
    }
}
