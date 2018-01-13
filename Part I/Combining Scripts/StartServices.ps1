Import-Csv -Path 'C:\Servers.txt' | Get-Service -Name wuauserv | ForEach-Object {
	$_ | Start-Service
}