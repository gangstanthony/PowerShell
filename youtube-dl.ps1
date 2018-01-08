# requires youtube-dl.exe, ffprobe.exe, and ffmpeg.exe to be in the c:\temp folder

function ydl {
    param (
        [string]$url = (Get-Clipboard),
        [ValidateSet('audio', 'video')]
        [string]$type = 'audio',
        [switch]$u,
        [string]$ydlpath = "$env:userprofile\Dropbox\Documents\PSScripts\youtube\youtube-dl.exe",
        [ValidateSet('auto', 'best', 'worst')]
        [string]$quality = 'auto'
    )
    
    if ($u) {
        start $ydlpath -ArgumentList '--update'
        return
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

    $quality = switch ($quality) {
        'auto' {
            if ($type -eq 'video') {
                'best'
            } else {
                'best' # 'worst'
            }
        }

        'best' {'best'}
        
        'worst' {'worst'}
    }

    if ($url -match 'playlist') {
        switch ($type) {
            'video' { . $ydlpath --merge-output-format mp4 -wic -o '%(autonumber)s %(title)s.%(ext)s' -f $quality $url }
            'audio' { . $ydlpath --extract-audio --audio-format mp3 -wic -o '%(autonumber)s %(title)s.%(ext)s' -f $quality $url }
        }
    } elseif ($url -match 'youtube') {
        switch ($type) {
            'video' { . $ydlpath --merge-output-format mp4 -wic -o '%(title)s.%(ext)s' -f $quality $url }
            'audio' { . $ydlpath --extract-audio --audio-format mp3 -wic -o '%(title)s.%(ext)s' -f $quality $url }
        }
    } elseif ($url -match 'soundcloud') {
        . $ydlpath -wic -o '%(title)s.%(ext)s' $url
    } else {
        switch ($type) {
            'video' { . $ydlpath --merge-output-format mp4 -wic -o '%(title)s.%(ext)s' $url }
            'audio' { . $ydlpath --extract-audio --audio-format mp3 -wic -o '%(title)s.%(ext)s' $url }
        }
    }
    
    if (Test-Path 'c:\temp\ffprobe.exe') {
        del 'c:\temp\ffprobe.exe'
    }

    if (Test-Path 'c:\temp\ffmpeg.exe') {
        del 'c:\temp\ffmpeg.exe'
    }
}
