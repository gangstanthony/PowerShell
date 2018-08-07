# https://stealthfield.wordpress.com/2015/08/21/powershell-array-vs-arraylist-performance/

$a1 = New-Object System.Collections.ArrayList
$a2 = New-Object System.Collections.ArrayList
$a3 = New-Object System.Collections.ArrayList
$a4 = New-Object System.Collections.ArrayList

1..100 | % {
    $null = $a1.Add($(Measure-Command {
        $ArrayList = New-Object System.Collections.ArrayList
        1..1000 | % {
            $null = $ArrayList.Add($_)
        }
        rv ArrayList
    }).TotalSeconds)

    $null = $a2.Add($(Measure-Command {
        $List = New-Object System.Collections.Generic.List[System.String]
        1..1000 | % {
            $List.Add($_)
        }
        $ListArray = $List.ToArray()
        rv List
        rv ListArray
    }).TotalSeconds)

    $null = $a3.Add($(Measure-Command {
        $Array1 = @()
        1..1000 | % {
            $Array += $_
        }
        rv Array1
    }).TotalSeconds)

    $null = $a4.Add($(Measure-Command {
        $Array2 = @(1..1000 | % {
            $_
        })
        rv Array2
    }).TotalSeconds)
}

@"
Method, Time
ArrayList,                  $($a1 | measure -Sum | % {$_.sum.tostring('000.000')})
List,                       $($a2 | measure -Sum | % {$_.sum.tostring('000.000')})
"array +=",                 $($a3 | measure -Sum | % {$_.sum.tostring('000.000')})
"array = @(for(...){...})", $($a4 | measure -Sum | % {$_.sum.tostring('000.000')})
"@ | ConvertFrom-Csv | sort time | ft -AutoSize

<#
Method                   Time   
------                   ----   
array = @(for(...){...}) 001.520
ArrayList                001.779
array +=                 001.798
List                     001.868
#>
