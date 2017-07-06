# http://www.online-tech-tips.com/computer-tips/hide-file-in-picture/
# recommend using png instead of jpg

function CopyTo-Image {
    param (
        [string]$file,
        [string]$image
    )

    $date = date -f yyyyMMddHHmmss

    $fileext = $file.split('.')[-1]

    if ($fileext -eq 'zip') {
        $zip = $file
    } else {
        $zip = "c:\temp\$date.zip"
        Compress-Archive $file $zip
    }

    $path = Split-Path $image
    $imageext = $image.split('.')[-1]
    $newname = (Split-Path $file -Leaf).Split('.')[0] + '.' + $imageext
    $newpath = Join-Path $path $newname

    cmd "/c copy /b $image + $zip `"$newpath`""

    if ($fileext -ne 'zip') {
        del "c:\temp\$date.zip"
    }
}
