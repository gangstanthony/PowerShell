# http://www.howtogeek.com/tips/how-to-extract-zip-files-using-powershell/
# http://stackoverflow.com/questions/11021879/creating-a-zipped-compressed-folder-in-windows-using-powershell-or-the-command-l
# https://blogs.msdn.microsoft.com/daiken/2007/02/12/compress-files-with-windows-powershell-then-package-a-windows-vista-sidebar-gadget/

# destination dir must already exist

<# alternative1
[System.Reflection.Assembly]::Load('WindowsBase,Version=3.0.0.0, Culture=neutral, PublicKeyToken=31bf3856ad364e35')
$folder = 'c:\temp'
$zipArchive = Join-Path $folder 'zip.zip'
$ZipPackage = [System.IO.Packaging.ZipPackage]::Open($zipArchive, [System.IO.FileMode]::OpenOrCreate, [System.IO.FileAccess]::ReadWrite)
# ???
$ZipPackage.Close()
#>

<# alternative2
[Reflection.Assembly]::LoadWithPartialName('System.IO.Compression.FileSystem')
[System.IO.Compression.ZipFile]::CreateFromDirectory($src_folder, $destfile, $compressionLevel, $includebasedir)
#>

function Expand-ZIPFile {
    param (
        [string]$file,
        [string]$destination
    )

    if (!$destination) {
        $destination = [string](Resolve-Path $file)
        $destination = $destination.Substring(0, $destination.LastIndexOf('.'))
        mkdir $destination | Out-Null
    }
    $shell = New-Object -ComObject Shell.Application
    #$shell.NameSpace($destination).CopyHere($shell.NameSpace($file).Items(), 16);
    $zip = $shell.NameSpace($file)
    foreach ($item in $zip.items()) {
        $shell.Namespace($destination).CopyHere($item)
    }
}
