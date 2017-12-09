function Get-LabVhd {
	[CmdletBinding()]
	param
	(
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$Name
	
	)
	try {
		$defaultVhdPath = $script:LabConfiguration.DefaultVirtualMachineConfiguration.VHDConfig.Path

		$icmParams = @{
			ScriptBlock  = { Get-ChildItem -Path $args[0] -File | foreach { Get-VHD -Path $_.FullName } }
			ArgumentList = $defaultVhdPath
		}
		InvokeHyperVCommand @icmParams
	} catch {
		$PSCmdlet.ThrowTerminatingError($_)
	}
}