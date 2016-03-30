function Get-Lines ($file) {
    begin {
        if (![System.IO.File]::Exists($file)) {
            Throw "File not found: $file"
        }

        try {
            $stream = New-Object System.IO.StreamReader -ArgumentList $file
        } catch {
            Throw $_
        }
    }

    process {
        :loop while ($true) {
            $line = $stream.ReadLine()
            if ($line -eq $null) {
                $stream.close()
                break loop
            }
            $line
        }
    }
}
