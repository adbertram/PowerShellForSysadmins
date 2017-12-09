function NewLabSwitch {
	[CmdletBinding()]
	param
	(
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$Name = $script:LabConfiguration.DefaultVirtualMachineConfiguration.VirtualSwitch.Name,
	
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[ValidateSet('Internal', 'External')]
		[string]$Type = $script:LabConfiguration.DefaultVirtualMachineConfiguration.VirtualSwitch.Type
		
	)
	begin {
		$ErrorActionPreference = 'Stop'
	}
	process {
		try {
			$scriptBlock = {
				if ($args[1] -eq 'External') {
					if ($externalSwitch = Get-VmSwitch -SwitchType 'External') {
						$switchName = $externalSwitch.Name
					} else {
						$switchName = $args[0]
						$netAdapterName = (Get-NetAdapter -Physical| where { $_.Status -eq 'Up' }).Name
						$null = New-VMSwitch -Name $args[0] -NetAdapterName $netAdapterName
					}
				} else {
					$switchName = $args[0]
					if (-not (Get-VmSwitch -Name $args[0] -ErrorAction Ignore)) {
						$null = New-VMSwitch -Name $args[0] -SwitchType $args[1]
					}
				}
			}
			InvokeHyperVCommand -Scriptblock $scriptBlock -ArgumentList $Name, $Type
		} catch {
			Write-Error $_.Exception.Message
		}
	}
}