function GetLabSwitch {
	[OutputType('Microsoft.HyperV.PowerShell.VMSwitch')]
	[CmdletBinding()]
	param
	()

	$ErrorActionPreference = 'Stop'

	$switchConfig = $script:LabConfiguration.DefaultVirtualMachineConfiguration.VirtualSwitch

	$scriptBlock = {
		if ($args[1] -eq 'External') {
			Get-VmSwitch -SwitchType 'External'
		} else {
			Get-VmSwitch -Name $args[0] -SwitchType $args[1]
		}
	}
	InvokeHyperVCommand -Scriptblock $scriptBlock -ArgumentList $switchConfig.Name, $switchConfig.Type
}