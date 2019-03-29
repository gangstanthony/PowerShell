# https://www.reddit.com/r/PowerShell/comments/b6xnwa/cant_get_enough_powershell_have_all_the_latest/?

# get last powershell questions

$file = "c:\temp\redditposh.csv"
$errorlog = "c:\temp\redditposherrors.txt"

if (!(Test-Path $file)) {
    'title,link,time' | Set-Content $file
}
$last = ipcsv $file

$to = # send email as sms to your cell # https://20somethingfinance.com/how-to-send-text-messages-sms-via-email-for-free/
$From = 'address@gmail.com'
$SMTPServer = 'smtp.gmail.com'
$SMTPPort = '587'
$pw = 'password' | ConvertTo-SecureString -AsPlainText -Force
$cred = New-Object pscredential $from, $pw

function sendcheck ($info) {
    if ($info.link -and @($last | ? link -eq $info.Link).Count -eq 0) {
        $info | epcsv $file -NoTypeInformation -Append

        $body = $info.title, $info.link -join "`n"

        $site = $info.link -replace 'https?://(?:www.)?([^/]+).*', '$1'
        Send-MailMessage -To $to -From $from -Subject $site -Body $body -SmtpServer $smtpserver -Port $SMTPPort -Credential $cred -usessl

        if ([bool]$error[0] -and $error[0].exception -notmatch 'module') {
            Get-Date | Add-Content $errorlog
            $error[0] | Add-Content $errorlog 
        }
    }
}

# REDDIT.COM
sendcheck (([xml](iwr reddit.com/r/powershell/new/.rss).content).feed.entry[0] | % {
    [pscustomobject]@{
        Title = $_.title
        Link = $_.link.href
        Time = Get-Date -f s
    }
})

#<# STACKOVERFLOW.COM
sendcheck (([xml](iwr 'https://stackoverflow.com/feeds/tag?tagnames=powershell&sort=newest')).feed.entry[0] | % {
    [pscustomobject]@{
        Title = $_.title.'#text'
        Link = $_.link.href
        Time = Get-Date -f s
    }
})
#>

#<# SPICEWORKS.COM
sendcheck ((iwr 'https://community.spiceworks.com/programming/powershell?filter=recent').Links.href | ? {$_ -match '\/topic\/.*\?from_forum=356'} | select -f 1 | % {
    [pscustomobject]@{
        Title = (Get-Culture).TextInfo.ToTitleCase((Split-Path $_ -Leaf).Replace('-', ' ') -replace '^\d+ |\?.*')
        Link = 'https://community.spiceworks.com' + $_
        Time = Get-Date -f s
    }
})
#>

#<# POWERSHELL.ORG
sendcheck ((iwr 'http://powershell.org/wp/forums/forum/windows-powershell-qa/').ParsedHtml.childNodes | % {$_.innerhtml.split("`n")} | ? {$_ -match 'bbp-topic-permalink.*forums/topic'} | select -f 1 -Skip 1 | % {
    [pscustomobject]@{
        Title = $_ -replace '.*">([^<]+).*', '$1'
        Link = $_ -replace '.*href="([^"]+).*', '$1'
        Time = Get-Date -f s
    }
})
#>

#<# POWERSHELL.COM
@(
    'active_directory__powershell_remoting-9'
    'learn_powershell_from_don_jones-24'
    'learn_powershell-12'
    'powershell_and_wmi-24'
    'powershell_for_exchange-24'
    'powershell_for_microsoft_lync_server-24'
    'powershell_for_sharepoint-12'
    'powershell_for_windows-12'
    'powershell_remoting-24'
    'sql_server__sharepoint-9'
) | % {
    sendcheck ((iwr "https://community.idera.com/database-tools/powershell/ask_the_experts/f/$_").links | ? {$_.href -match 'http.*/\d{5}/'} | select href, outertext -f 1 | % {
        [pscustomobject]@{
            Title = (Get-Culture).TextInfo.ToTitleCase($_.outertext)
            Link = $_.href
            Time = Get-Date -f s
        }
    })
}
#>

#<# TECHNET.MICROSOFT.COM
sendcheck ((iwr https://social.technet.microsoft.com/forums/windowsserver/en-us/home?forum=winserverpowershell).Links | ? {$_.href -match 'https.*server/en-US/[a-z0-9]{8}-' -and $_.href -notmatch '#' -and $_.outertext -notmatch '\d votes'} | select href, outertext -f 1 | % {
    [pscustomobject]@{
        Title = $_.outertext
        Link = $_.href
        Time = Get-Date -f s
    }
})
#>
