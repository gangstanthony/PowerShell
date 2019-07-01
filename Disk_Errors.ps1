if ((get-host).Version.Major -ge 4){
$XmlQuery = [xml]@'
<QueryList>
  <Query Id="0" Path="System">
    <Select Path="System">*[System[Provider[@Name='disk'] and TimeCreated[timediff(@SystemTime) &lt;= 86400000]]]</Select>
  </Query>
</QueryList>
'@
$LogOutput = Get-WinEvent -FilterXml $XmlQuery -ErrorAction SilentlyContinue
}
  else{
    $LogOutput = Get-EventLog -LogName system -Source disk -After (get-date).AddDays(-1) -ErrorAction SilentlyContinue
    }

if ($LogOutput){
Write-Host "---ERROR---"
Write-Host "Disk messages in system log found"
$LogOutput | fl TimeGenerated, Message
exit 1010
}

else{
Write-Host "---OK---"
Write-Host "No disk messages in system log found"
exit 0
}