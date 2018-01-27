function New-PowerLabSwitch {
	param(
		[Parameter(Mandatory)]
		[string]$SwitchName,

		[Parameter(Mandatory)]
		[string]$SwitchType
	)

	if (-not (Get-VmSwitch -Name $SwitchName -SwitchType $SwitchType -ErrorAction SilentlyContinue)) {
		$null = New-VMSwitch -Name $SwitchName -SwitchType $SwitchType
	} else {
		Write-Verbose -Message "The switch [$($SwitchName)] has already been created."
	}
}

function New-PowerLabVm {
	param (
		[Parameter(Mandatory)]
		[string]$Name,

		[Parameter(Mandatory)]
		[string]$Path,

		[Parameter(Mandatory)]
		[string]$Memory,

		[Parameter(Mandatory)]
		[string]$Switch,

		[Parameter(Mandatory)]
		[ValidateRange(1, 2)]
		[int]$Generation
	)

	if (-not (Get-Vm -Name $Name -ErrorAction SilentlyContinue)) {
		$null = New-VM -Name $Name -Path $Path -MemoryStartupBytes $Memory -Switch $Switch -Generation $Generation
	} else {
		Write-Verbose -Message "The VM [$($Name)] has already been created."
	}
}

function New-PowerLabVhd {
	param
	(
		[Parameter(Mandatory)]
		[string]$Name,

		[Parameter(Mandatory)]
		[ValidateRange(512MB, 1TB)]
		[int64]$Size,

		[Parameter(Mandatory)]
		[ValidateSet('Dynamic', 'Fixed')]
		[string]$Sizing,

		[Parameter(Mandatory)]
		[string]$Path,

		[Parameter(Mandatory)]
		[string]$AttachToVm
	)

	$vhdxFileName = "$Name.vhdx"
	$vhdxFilePath = Join-Path -Path $Path -ChildPath "$Name.vhdx"

	### Convert the Hyper-V host local path to a UNC
	$remoteFilePathDrive = ($Path | Split-Path -Qualifier).TrimEnd(':')
	$uncPath = '\\{0}\{1}${2}\{3}' -f $ComputerName, $remoteFilePathDrive, ($Path | Split-Path -NoQualifier), $vhdxFileName

	### Ensure we don't try to create a VHD when there's already one there
	if (-not (Test-Path -Path $uncPath -PathType Leaf)) {
		$params = @{
			SizeBytes    = $Size
			ComputerName = $ComputerName
			Path         = $vhdxFilePath
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
		if (-not ($vm = Get-VM -Name $AttachToVm -ComputerName $ComputerName -ErrorAction SilentlyContinue)) {
			Write-Warning -Message "The VM [$($AttachToVm)] does not exist. Unable to attach VHD."
		} elseif (-not ($vm | Get-VMHardDiskDrive | Where-Object { $_.Path -eq $vhdxFilePath })) {
			$vm | Add-VMHardDiskDrive -Path $vhdxFilePath
			Write-Verbose -Message "Attached VHDX [$($vhdxFilePath)] to VM [$($AttachToVM)]."
		} else {
			Write-Verbose -Message "VHDX [$($vhdxFilePath)] already attached to VM [$($AttachToVM)]."
		}
	}
}