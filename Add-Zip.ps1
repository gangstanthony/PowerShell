# http://stackoverflow.com/questions/11021879/creating-a-zipped-compressed-folder-in-windows-using-powershell-or-the-command-l

# when using in foreach, must sleep -m 500 after every file

# on conflict, popup will ask to copy and replace

function Add-Zip {
    param (
        [string]$sourceFile,
        [string]$zipFile
    )

    begin {
        function Resolve-FullPath ([string]$Path) {    
            if ( -not ([System.IO.Path]::IsPathRooted($Path)) ) {
                # $Path = Join-Path (Get-Location) $Path
                $Path = "$PWD\$Path"
            }
            [IO.Path]::GetFullPath($Path)
        }
    }

    process {
        $sourceFile = Resolve-FullPath $sourceFile
        $zipFile = Resolve-FullPath $zipFile

        if (-not (Test-Path $zipFile)) {
            Set-Content $zipFile ('PK' + [char]5 + [char]6 + ([string][char]0 * 18))
            (Get-Item $zipFile).IsReadOnly = $false  
        }

        $shell = New-Object -ComObject shell.application
        $zipPackage = $shell.NameSpace($zipFile)

        $zipPackage.CopyHere($sourceFile)
    }
}
