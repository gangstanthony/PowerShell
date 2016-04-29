filter Get-ShortPath {
    param (
        [Parameter(ValueFromPipeline=$true)]
        [string]$obj
    )

    begin {
        $fso = New-Object -ComObject Scripting.FileSystemObject
        function Release-Ref ($ref) {
            ([System.Runtime.InteropServices.Marshal]::ReleaseComObject([System.__ComObject]$ref) -gt 0)
            [System.GC]::Collect()
            [System.GC]::WaitForPendingFinalizers()
        }
    }

    process {
        if (!$obj) {$obj = $pwd}

        $file = gi $obj
        if ($file.psiscontainer) {
            $fso.getfolder($file.fullname).ShortPath
        } else {
            $fso.getfile($file.fullname).ShortPath
        }
    }

    end {
        $null = Release-Ref $fso
    }
}
