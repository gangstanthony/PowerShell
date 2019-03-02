# https://www.reddit.com/r/PowerShell/comments/5hgr1g/help_getwinevent_filterxml_i_dont_get_it/

# get info (total count) for each log
# https://www.reddit.com/r/PowerShell/comments/5m8zxq/pssession_showing_different_information/dc1teyt/

$a1 = New-Object System.Collections.ArrayList
$a2 = New-Object System.Collections.ArrayList
$a3 = New-Object System.Collections.ArrayList
$a4 = New-Object System.Collections.ArrayList
$a5 = New-Object System.Collections.ArrayList
$a6 = New-Object System.Collections.ArrayList
$a7 = New-Object System.Collections.ArrayList

1..5 | % {
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
        $events = wevtutil qe system "/q:*[System[Provider[@Name='Microsoft-Windows-Winlogon'] and TimeCreated[@SystemTime > '$(date (date).AddDays(-11) -UFormat '%Y-%m-%dT%H:%M:%S.000Z')']]]" /rd:true /f:text
    }).TotalSeconds)

    $null = $a7.Add($(Measure-Command {
        $ElevenDaysAgo = [Management.ManagementDateTimeConverter]::ToDmtfDateTime((date).AddDays(-11))
        $events = wmic ntevent where "logfile = 'System' and sourcename = 'Microsoft-Windows-Winlogon' and timewritten > '$ElevenDaysAgo'"
    }).TotalSeconds)
}

"Method, Time
filterhashtable,       $($a1 | measure -Average | % {$_.average.tostring('000.000')})
filterxpath,           $($a2 | measure -Average | % {$_.average.tostring('000.000')})
filterxml,             $($a3 | measure -Average | % {$_.average.tostring('000.000')})
get-eventlog,          $($a4 | measure -Average | % {$_.average.tostring('000.000')})
gwmi win32_ntlogevent, $($a5 | measure -Average | % {$_.average.tostring('000.000')})
wevtutil,              $($a6 | measure -Average | % {$_.average.tostring('000.000')})
wmic,                  $($a7 | measure -Average | % {$_.average.tostring('000.000')})
" | ConvertFrom-Csv | sort time | ft -AutoSize

# Method                Time
# ------                ----
# filterxml             000.096
# filterxpath           000.112
# wevtutil              000.118
# filterhashtable       000.133
# gwmi win32_ntlogevent 000.998
# wmic                  001.071
# get-eventlog          002.171
