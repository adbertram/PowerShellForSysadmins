param
(
	[Parameter()]
	[ValidateNotNullOrEmpty()]
	[switch]$AddToDomain
)

## Build the VM
$vmparams = @{ 
	Type     = 'SQL' 
	PassThru = $true
}
$vm = New-PowerLabVm @vmParams
"$PSScriptRoot\Install-SqlServer.ps1" -ComputerName $vm.Name

if ($AddToDomain.IsPresent) {
	$credConfig = $script:LabConfiguration.DefaultOperatingSystemConfiguration.Users.where({ $_.Name -ne 'Administrator' })
	$domainUserName = '{0}\{1}' -f $script:LabConfiguration.ActiveDirectoryConfiguration.DomainName, $credConfig.name
	$domainCred = New-PSCredential -UserName $domainUserName -Password $credConfig.Password
	$addParams = @{
		ComputerName = $vm.Name
		DomainName   = $script:LabConfiguration.ActiveDirectoryConfiguration.DomainName
		Credential   = $domainCred
		Restart      = $true
		Force        = $true
	}
	Add-Computer @addParams
}