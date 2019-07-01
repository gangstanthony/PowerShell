$dnsservers = "192.168.1.100","192.168.1.1"
$computers = Get-Content ComputerList.txt
foreach ($comp in $computers)
{

	$adapters = gwmi -q "select * from win32_networkadapterconfiguration where ipenabled='true'" -ComputerName $comp
	foreach ($adapter in $adapters)
	{
		$adapter.setDNSServerSearchOrder($dnsservers)
	}
	
}