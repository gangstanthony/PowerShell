

$a1 = New-Object System.Collections.ArrayList
$a2 = New-Object System.Collections.ArrayList
$a3 = New-Object System.Collections.ArrayList
$a4 = New-Object System.Collections.ArrayList
$a5 = New-Object System.Collections.ArrayList
$a6 = New-Object System.Collections.ArrayList

1..50 | % {
    $null = $a1.Add($(Measure-Command {
        # filterhashtable
        $filterhashtable = @{
	        LogName = 'system'
            providername = 'Microsoft-Windows-WinLogon'
	        StartTime = (date).AddDays(-11)
        }
        $events = Get-WinEvent -FilterHashTable $filterhashtable
    }).TotalSeconds)
    
    $null = $a2.Add($(Measure-Command {
        # filterxpath
        $filterxpath = "
            *[
                System/Provider[@Name='Microsoft-Windows-WinLogon']
                and
                System/TimeCreated[@SystemTime > '$(date (date).AddDays(-11) -UFormat "%Y-%m-%dT%H:%M:%S.000Z")']
            ]
        "
        $events = Get-WinEvent -LogName system -FilterXPath $filterxpath
    }).TotalSeconds)
    
    $null = $a3.Add($(Measure-Command {
        # filterxml
        $filterXml = "
            <QueryList>
                <Query Id='0' Path='System'>
                <Select Path='System'>
                    *[System[
			            Provider[@Name = 'Microsoft-Windows-Winlogon']
                        and
			            TimeCreated[@SystemTime >= '$(date (date).AddDays(-11) -UFormat '%Y-%m-%dT%H:%M:%S.000Z')']
                    ]]
                </Select>
                </Query>
            </QueryList>
        "
        $events = Get-WinEvent -FilterXml $filterXml
    }).TotalSeconds)

    $null = $a4.Add($(Measure-Command {
        $events = Get-EventLog -LogName System -Source Microsoft-Windows-WinLogon -After (Get-Date).AddDays(-11)
    }).TotalSeconds)
    
    $null = $a5.Add($(Measure-Command {
        $ElevenDaysAgo = [Management.ManagementDateTimeConverter]::ToDmtfDateTime((date).AddDays(-11))
        $events = gwmi win32_ntlogevent -Filter "logfile = 'System' and sourcename = 'Microsoft-Windows-Winlogon' and timewritten > '$ElevenDaysAgo'"
    }).TotalSeconds)

    $null = $a6.Add($(Measure-Command {
        $date = ((date) - (date).AddDays(-11)).totalmilliseconds
        $events = wevtutil qe system "/q:*[System[Provider[@Name='Microsoft-Windows-Winlogon'] and TimeCreated[timediff(@SystemTime) <= $date]]]" /rd:true /f:text
    }).TotalSeconds)
}

" Method, Time
filterhashtable, $($a1 | measure -Sum | % {$_.sum.tostring('000.000')})
filterxpath, $($a2 | measure -Sum | % {$_.sum.tostring('000.000')})
filterxml, $($a3 | measure -Sum | % {$_.sum.tostring('000.000')})
get-eventlog, $($a4 | measure -Sum | % {$_.sum.tostring('000.000')})
gwmi win32_ntlogevent, $($a5 | measure -Sum | % {$_.sum.tostring('000.000')})
wevtutil, $($a6 | measure -Sum | % {$_.sum.tostring('000.000')})
" | ConvertFrom-Csv | sort time | ft -AutoSize

# Method                Time   
# ------                ----   
# filterxml             000.996
# filterxpath           001.397
# wevtutil              002.097
# filterhashtable       002.703
# gwmi win32_ntlogevent 011.042
# get-eventlog          015.876
