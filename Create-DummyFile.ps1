# https://www.tutorialspoint.com/how-to-create-a-dummy-file-of-any-size-with-powershell

function Create-DummyFile {
    param (
        $path = 'c:\temp',
        $size = 15mb
    )

    $f = new-object System.IO.FileStream $path, Create, ReadWrite
    $f.SetLength($size)
    $f.Close()
}
