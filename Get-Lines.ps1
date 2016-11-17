# https://www.reddit.com/r/PowerShell/comments/4payc9/confirm_file_length_and_format_before_loading/

# this should work, but why not use get-content?
# get-content -readlines 1000
# see 'streamwriter example...'

# !
# this
# $stream = New-Object System.IO.StreamReader -ArgumentList $file
# is the same type as this!
# $stream = [System.IO.File]::OpenText($file)

function Get-Lines ([string]$file) {
    begin {
        $file = (Resolve-Path $file).ToString()

        if (!(Test-Path $file)) {
            Throw "File not found: $file"
        }

        try {
            #$stream = New-Object System.IO.StreamReader $file
            $stream = [System.IO.File]::OpenText($file)
        } catch {
            Throw $_
        }
    }

    process {
        while (!$stream.EndOfStream) {
            $stream.ReadLine()
        }
        $stream.Close()
        rv stream
    }
}
