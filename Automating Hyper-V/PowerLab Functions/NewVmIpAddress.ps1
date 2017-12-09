function NewVmIpAddress {
	[OutputType('string')]
	[CmdletBinding()]
	param
	()

	$ipNet = $script:LabConfiguration.DefaultOperatingSystemConfiguration.Network.IpNetwork
	$ipBase = $ipNet -replace ".$($ipNet.Split('.')[-1])$"
	$randomLastOctet = Get-Random -Minimum 10 -Maximum 254
	$ipBase, $randomLastOctet -join '.'
	
}