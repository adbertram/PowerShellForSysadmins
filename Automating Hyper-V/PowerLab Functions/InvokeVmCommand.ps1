function InvokeVmCommand {
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$ComputerName,

		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[scriptblock]$ScriptBlock,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[object[]]$ArgumentList
	)

	$ErrorActionPreference = 'Stop'

	$credConfig = $script:LabConfiguration.DefaultOperatingSystemConfiguration.Users.where({ $_.Name -ne 'Administrator' })
	$cred = New-PSCredential -UserName $credConfig.name -Password $credConfig.Password
	$icmParams = @{
		ComputerName   = $ComputerName 
		ScriptBlock    = $ScriptBlock
		Credential     = $cred
		Authentication = 'CredSSP'
	}
	if ($PSBoundParameters.ContainsKey('ArgumentList')) {
		$icmParams.ArgumentList = $ArgumentList
	}
	Invoke-Command @icmParams

	
}