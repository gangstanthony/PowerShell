# http://powershell.org/wp/2013/09/16/powershell-performance-the-operator-and-when-to-avoid-it/

<# http://powershell.org/wp/2013/10/21/why-get-content-aint-yer-friend/
# get the whole file (faster than below)
#[IO.File]::ReadAllText("c:\myfile.txt")

# read each line
$file = New-Object System.IO.StreamReader -Arg "test.txt"
while ($line = $file.ReadLine()) {
  # $line has your line
}
$file.close()
#>

$a1 = New-Object System.Collections.ArrayList
$a2 = New-Object System.Collections.ArrayList
$a3 = New-Object System.Collections.ArrayList

1..5 | % {
    $null = $a1.Add($(Measure-Command {
        $StringBuilder = New-Object System.Text.StringBuilder
        1..10000 | % {
            $null = $stringBuilder.Append($_)
        }
        $OutputString = $StringBuilder.ToString()
        rv StringBuilder
        rv OutputString
    }).TotalSeconds)

    $null = $a2.Add($(Measure-Command {
        $OutputString = ''
        1..10000 | % {
            $OutputString += $_
        }
        rv OutputString
    }).TotalSeconds)

    $null = $a3.Add($(Measure-Command {
        $OutputString = -join@(1..10000 | % {
            $_
        })
        rv OutputString
    }).TotalSeconds)
}

@"
Method,Time
StringBuilder,                $($a1 | measure -Sum | % {$_.sum.tostring('000.000')})
string +=,                    $($a2 | measure -Sum | % {$_.sum.tostring('000.000')})
string -join@(for(...){...}), $($a3 | measure -Sum | % {$_.sum.tostring('000.000')})
"@ | ConvertFrom-Csv | sort time | ft -AutoSize

<#
Method                       Time   
------                       ----   
StringBuilder                000.836
string -join@(for(...){...}) 000.912
string +=                    002.587
#>
