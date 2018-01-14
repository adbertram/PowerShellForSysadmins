function PrepareUnattendXmlFile {
	[OutputType('System.IO.FileInfo')]
	[CmdletBinding(SupportsShouldProcess)]
	param
	(
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$Path,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$VMName,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$IpAddress,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$DnsServer,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$DomainName,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$ProductKey,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$UserName,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$UserPassword,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$VmType
	)

	$ErrorActionPreference = 'Stop'

	## Make a copy of the unattend XML
	$tempUnattend = Copy-Item -Path $Path -Destination $env:TEMP -PassThru -Force

	## Prep the XML object
	$unattendText = Get-Content -Path $tempUnattend.FullName -Raw
	$xUnattend = ([xml]$unattendText)
	$ns = New-Object System.Xml.XmlNamespaceManager($xunattend.NameTable)
	$ns.AddNamespace('ns', $xUnattend.DocumentElement.NamespaceURI)

	if ($VmType -eq 'Domain Controller') {
		$dnsIp = $script:LabConfiguration.DefaultOperatingSystemConfiguration.Network.DnsServer
		$xUnattend.SelectSingleNode('//ns:Interface/ns:UnicastIpAddresses/ns:IpAddress', $ns).InnerText = "$dnsIp/24"
		$xUnattend.SelectSingleNode('//ns:DNSServerSearchOrder/ns:IpAddress', $ns).InnerText = $dnsIp
	} else {
		# Insert the NIC configuration
		$xUnattend.SelectSingleNode('//ns:Interface/ns:UnicastIpAddresses/ns:IpAddress', $ns).InnerText = "$IpAddress/24"
		$xUnattend.SelectSingleNode('//ns:DNSServerSearchOrder/ns:IpAddress', $ns).InnerText = $DnsServer
	}

	## Insert the correct product key
	$xUnattend.SelectSingleNode('//ns:ProductKey', $ns).InnerText = $ProductKey
	
	# ## Insert the user names and password
	$localuser = $script:LabConfiguration.DefaultOperatingSystemConfiguration.Users.where({ $_.Name -ne 'Administrator' })
	$xUnattend.SelectSingleNode('//ns:LocalAccounts/ns:LocalAccount/ns:Password/ns:Value[text()="XXXX"]', $ns).InnerXml  = $localuser.Password
	$xUnattend.SelectSingleNode('//ns:LocalAccounts/ns:LocalAccount/ns:Name[text()="XXXX"]', $ns).InnerXml  = $localuser.Name

	$userxPaths = '//ns:FullName', '//ns:Username'
	$userxPaths | foreach {
		$xUnattend.SelectSingleNode($_, $ns).InnerXml = $UserName
	}

	## Change the local admin password
	$localadmin = $script:LabConfiguration.DefaultOperatingSystemConfiguration.Users.where({ $_.Name -eq 'Administrator' })
	$xUnattend.SelectSingleNode('//ns:LocalAccounts/ns:LocalAccount/ns:Name[text()="Administrator"]', $ns).InnerText = $localadmin.Password
	
	$netUserCmd = $xUnattend.SelectSingleNode('//ns:FirstLogonCommands/ns:SynchronousCommand/ns:CommandLine[text()="net user administrator XXXX"]', $ns)
	$netUserCmd.InnerText = $netUserCmd.InnerText.Replace('XXXX', $localadmin.Password)

	## Set the lab user autologon
	$xUnattend.SelectSingleNode('//ns:AutoLogon/ns:Password/ns:Value', $ns).InnerText = $UserPassword

	## Insert the host name
	$xUnattend.SelectSingleNode('//ns:ComputerName', $ns).InnerText = $VMName

	## Set the domain names
	$xUnattend.SelectSingleNode('//ns:DNSDomain', $ns) | foreach { $_.InnerText = $DomainName }

	## Save the config back to the XML file
	$xUnattend.Save($tempUnattend.FullName)

	$tempUnattend
}