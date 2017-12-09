function Get-LabVm {
	[CmdletBinding(DefaultParameterSetName = 'Name')]
	param
	(
		[Parameter(ParameterSetName = 'Name')]
		[ValidateNotNullOrEmpty()]
		[string]$Name,

		[Parameter(ParameterSetName = 'Type')]
		[ValidateNotNullOrEmpty()]
		[string]$Type
	
	)
	$ErrorActionPreference = 'Stop'

	$nameMatch = $script:LabConfiguration.VirtualMachines.BaseName -join '|'
	if ($PSBoundParameters.ContainsKey('Name')) {
		$nameMatch = $Name
	} elseif ($PSBoundParameters.ContainsKey('Type')) {
		$nameMatch = $Type
	}

	try {
		$icmParams = @{
			ScriptBlock  = { $name = $args[0]; @(Get-VM).where({ $_.Name -match $name }) }
			ArgumentList = $nameMatch
		}
		InvokeHyperVCommand @icmParams
	} catch {
		if ($_.Exception.Message -notmatch 'Hyper-V was unable to find a virtual machine with name') {
			$PSCmdlet.ThrowTerminatingError($_)
		}
	}
}