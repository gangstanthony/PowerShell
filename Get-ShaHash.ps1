function Get-ShaHash {
	param (
        [Parameter(ValueFromPipeline=$true)]
		[string]$file,
        [ValidateSet(1, 256, 384, 512)]
        [int]$bit = 512
	)

    begin {
        function Resolve-FullPath ([string]$Path) {    
            if ( -not ([IO.Path]::IsPathRooted($Path)) ) {
                $Path = Join-Path $PWD $Path
            }
            [IO.Path]::GetFullPath($Path)
        }
    }

    process {
        $file = Resolve-FullPath $file
        
        $sha = New-Object System.Security.Cryptography.SHA$bit`CryptoServiceProvider
        $hash = [BitConverter]::ToString($sha.ComputeHash([IO.File]::ReadAllBytes([IO.FileInfo]$file)))
        $hash
    }
}
