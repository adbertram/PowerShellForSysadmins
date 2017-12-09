function InvokeHyperVCommand {
	[CmdletBinding(SupportsShouldProcess)]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[scriptblock]$Scriptblock,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[object[]]$ArgumentList
	)

	$ErrorActionPreference = 'Stop'

	$icmParams = @{
		ScriptBlock  = $Scriptblock
		ArgumentList = $ArgumentList
	}
	
	if (-not (Get-Variable 'hypervSession' -Scope Script -ErrorAction Ignore)) {
		$script:hypervSession = New-PSSession -ComputerName $script:LabConfiguration.HostServer.Name
	}
	$icmParams.Session = $script:hypervSession
	
	Invoke-Command @icmParams

}