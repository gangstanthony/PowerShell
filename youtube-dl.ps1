# requires youtube-dl.exe, ffprobe.exe, and ffmpeg.exe to be in the c:\temp folder

function ydl {
    param (
        [string]$url = (Get-Clipboard),
        [ValidateSet('audio', 'video')]
        [string]$type = 'audio',
        [switch]$u,
        [string]$ydlpath = "$env:userprofile\Dropbox\Documents\PSScripts\youtube\youtube-dl.exe"
    )
    
    if ($u) {
        start $ydlpath -ArgumentList '--update'
    }
    
    if (!(Test-Path c:\temp)) {
        $null = md c:\temp
    }
    
    if (!(Test-Path 'c:\temp\ffprobe.exe')) {
        cp "$env:userprofile\Dropbox\Documents\PSScripts\youtube\ffprobe.exe" c:\temp
    }

    if (!(Test-Path 'c:\temp\ffmpeg.exe')) {
        cp "$env:userprofile\Dropbox\Documents\PSScripts\youtube\ffmpeg.exe" c:\temp
    }

    cd c:\temp

    # i like to save space so:
    # video quality is 360p or best if that is not an option
    # audio only is lowest quality (-f 17)
    if ($url -match 'playlist') {
        switch ($type) {
            'video' { . $ydlpath --merge-output-format mp4 -wic -o '%(autonumber)s %(title)s.%(ext)s' -f '18/best' $url }
            'audio' { . $ydlpath --extract-audio --audio-format mp3 -wic -o '%(autonumber)s %(title)s.%(ext)s' -f '17/worst' $url }
        }
    } elseif ($url -match 'youtube') {
        switch ($type) {
            'video' { . $ydlpath --merge-output-format mp4 -wic -o '%(title)s.%(ext)s' -f '18/best' $url }
            'audio' { . $ydlpath --extract-audio --audio-format mp3 -wic -o '%(title)s.%(ext)s' -f '17/worst' $url }
        }
    } elseif ($url -match 'soundcloud') {
        . $ydlpath -wic -o '%(title)s.%(ext)s' $url
    } else {
        switch ($type) {
            'video' { . $ydlpath --merge-output-format mp4 -wic -o '%(title)s.%(ext)s' $url }
            'audio' { . $ydlpath --extract-audio --audio-format mp3 -wic -o '%(title)s.%(ext)s' $url }
        }
    }
}
