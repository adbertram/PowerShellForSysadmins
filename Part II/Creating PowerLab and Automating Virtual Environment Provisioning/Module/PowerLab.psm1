function New-PowerLabSwitch {
	param(
		[Parameter()]
		[string]$SwitchName = 'PowerLab',

		[Parameter()]
		[string]$SwitchType = 'External'
	)

	if (-not (Get-VmSwitch -Name $SwitchName -SwitchType $SwitchType -ErrorAction SilentlyContinue)) {
		$null = New-VMSwitch -Name $SwitchName -SwitchType $SwitchType
	} else {
		Write-Verbose -Message "The switch [$($SwitchName)] has already been created."
	}
}

function New-PowerLabVm {
	param(
		[Parameter(Mandatory)]
		[string]$Name,

		[Parameter()]
		[string]$Path = 'C:\PowerLab\VMs',

		[Parameter()]
		[string]$Memory = 4GB,

		[Parameter()]
		[string]$Switch = 'PowerLab',

		[Parameter()]
		[ValidateRange(1, 2)]
		[int]$Generation = 2,

		[Parameter()]
		[switch]$PassThru
	)

	if (-not (Get-Vm -Name $Name -ErrorAction SilentlyContinue)) {
		$null = New-VM -Name $Name -Path $Path -MemoryStartupBytes $Memory -Switch $Switch -Generation $Generation
	} else {
		Write-Verbose -Message "The VM [$($Name)] has already been created."
	}
	if ($PassThru.IsPresent) {
		Get-VM -Name $Name
	}
}

function New-PowerLabVhd {
	param
	(
		[Parameter(Mandatory)]
		[string]$Name,

		[Parameter()]
		[string]$AttachToVm,

		[Parameter()]
		[ValidateRange(512MB, 1TB)]
		[int64]$Size = 50GB,

		[Parameter()]
		[ValidateSet('Dynamic', 'Fixed')]
		[string]$Sizing = 'Dynamic',

		[Parameter()]
		[string]$Path = 'C:\PowerLab\VHDs'
	)

	$vhdxFileName = "$Name.vhdx"
	$vhdxFilePath = Join-Path -Path $Path -ChildPath "$Name.vhdx"

	### Ensure we don't try to create a VHD when there's already one there
	if (-not (Test-Path -Path $vhdxFilePath -PathType Leaf)) {
		$params = @{
			SizeBytes = $Size
			Path      = $vhdxFilePath
		}
		if ($Sizing -eq 'Dynamic') {
			$params.Dynamic = $true
		} elseif ($Sizing -eq 'Fixed') {
			$params.Fixed = $true
		}

		New-VHD @params
		Write-Verbose -Message "Created new VHD at path [$($vhdxFilePath)]"
	}

	### Attach either the newly created VHD or the one that was already there to the VM.
	if ($PSBoundParameters.ContainsKey('AttachToVm')) {
		if (-not ($vm = Get-VM -Name $AttachToVm -ErrorAction SilentlyContinue)) {
			Write-Warning -Message "The VM [$($AttachToVm)] does not exist. Unable to attach VHD."
		} elseif (-not ($vm | Get-VMHardDiskDrive | Where-Object { $_.Path -eq $vhdxFilePath })) {
			$vm | Add-VMHardDiskDrive -Path $vhdxFilePath
			Write-Verbose -Message "Attached VHDX [$($vhdxFilePath)] to VM [$($AttachToVM)]."
		} else {
			Write-Verbose -Message "VHDX [$($vhdxFilePath)] already attached to VM [$($AttachToVM)]."
		}
	}
}