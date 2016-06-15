# requires youtube-dl.exe, ffprobe.exe, and ffmpeg.exe to be in the c:\temp folder

function ydl {
    param (
        [string]$url = (Get-Clipboard),
        [switch]$u,
        [string]$ydlpath = 'C:\temp\youtube-dl.exe',
        [ValidateSet('audio', 'video')]
        [string]$type = 'audio'
    )
    
    if ($u) {
        start $ydlpath -ArgumentList '--update'
    }
    
    if (!(Test-Path c:\temp)) {
        md c:\temp | Out-Null
    }

    cd c:\temp

    # video quality is auto
    # audio only is always downloaded at lowest quality (-f 17)
    if ($url -match 'playlist') {
        if ($type -eq 'video') {
            . $ydlpath -wic -o '%(autonumber)s %(title)s.%(ext)s' $url
        } elseif ($type -eq 'audio') {
            . $ydlpath --extract-audio --audio-format mp3 -wic -o '%(autonumber)s %(title)s.%(ext)s' -f 17 $url
        }
    } elseif ($url -match 'youtube') {
        if ($type -eq 'video') {
            . $ydlpath -wic -o '%(title)s.%(ext)s' $url
        } elseif ($type -eq 'audio') {
            . $ydlpath --extract-audio --audio-format mp3 -wic -o '%(title)s.%(ext)s' -f 17 $url
        }
    } elseif ($url -match 'soundcloud') {
        . $ydlpath -wic -o '%(title)s.%(ext)s' $url
    }
}
