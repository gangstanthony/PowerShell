# http://www.reddit.com/r/PowerShell/comments/4hq96s/adding_members_to_combobox_-_remove_display_in_powershell_screen/d2v351y?context=3

$a1 = New-Object System.Collections.ArrayList
$a2 = New-Object System.Collections.ArrayList
$a3 = New-Object System.Collections.ArrayList
$a4 = New-Object System.Collections.ArrayList

1..100 | % {
    $null = $a1.Add(
        (Measure-Command {
            $null = $(1..100)
        }).Ticks
    )
    $null = $a2.Add(
        (Measure-Command {
            $(1..100) > $null
        }).Ticks
    )
    $null = $a3.Add(
        (Measure-Command {
            [void]$(1..100)
        }).Ticks
    )
    $null = $a4.Add(
        (Measure-Command {
            $(1..100) | Out-Null
        }).Ticks
    )
}

($a1 | measure -Sum).sum
($a2 | measure -Sum).sum
($a3 | measure -Sum).sum
($a4 | measure -Sum).sum
