function New-LabVm {
	[OutputType([void])]
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[ValidateSet('SQL', 'Web', 'Domain Controller')]
		[string]$Type,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[switch]$PassThru
	)

	$ErrorActionPreference = 'Stop'

	$name = GetNextLabVmName -Type $Type

	## Create the VM
	$scriptBlock = {
		$vmParams = @{
			Name               = $args[0]
			Path               = $args[1]
			MemoryStartupBytes = $args[2]
			Switch             = $args[3]
			Generation         = $args[4]
		}
		New-VM @vmParams
	}
	$argList = @(
		$name
		$script:LabConfiguration.DefaultVirtualMachineConfiguration.VMConfig.Path
		(Invoke-Expression -Command $script:LabConfiguration.DefaultVirtualMachineConfiguration.VMConfig.StartupMemory)
		(GetLabSwitch).Name
		$script:LabConfiguration.DefaultVirtualMachineConfiguration.VmConfig.Generation
	)
	$vm = InvokeHyperVCommand -Scriptblock $scriptBlock -ArgumentList $argList

	## Create the VHD and install Windows on the VM
	$os = @($script:LabConfiguration.VirtualMachines).where({$_.Type -eq $Type}).OS
	$addparams = @{
		Vm              = $vm
		OperatingSystem = $os
		VmType          = $Type
	}
	AddOperatingSystem @addparams

	InvokeHyperVCommand -Scriptblock { Start-Vm -Name $args[0] } -ArgumentList $name

	Add-TrustedHostComputer -ComputerName $name

	WaitWinRM -ComputerName $vm.Name

	## Enabling CredSSP support
	## Not using InvokeVMCommand here because we have to enable CredSSP first before it'll work
	$credConfig = $script:LabConfiguration.DefaultOperatingSystemConfiguration.Users.where({ $_.Name -ne 'Administrator' })
	$localCred = New-PSCredential -UserName $credConfig.name -Password $credConfig.Password
	Invoke-Command -ComputerName $name -ScriptBlock { $null = Enable-WSManCredSSP -Role Server -Force } -Credential $localCred
	
	if ($PassThru.IsPresent) {
		$vm
	}
	
}