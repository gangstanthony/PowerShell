# https://stackoverflow.com/a/4192419/4589490

$file = 'C:\temp\test\torestore.csv'

$reader = [System.IO.File]::OpenText($file)
$filename = Split-Path $file -Leaf
$outdir = Join-Path (Split-Path $file) 'split'
if (!(Test-Path $outdir)) {md $outdir}

$linecount = 1000
$count = 0
$filecount = 1

while ($null -ne ($line = $reader.ReadLine())) {
    if ($count -eq 0) {
        $header = $line
    }

    if ($count % $linecount -eq 0) {
        # start new file
        $output = Join-Path $outdir ($filename + '-' + $filecount + '.csv')
        $filecount++
        $header | Add-Content $output
    }

    $line | Add-Content $output

    $count++
}
