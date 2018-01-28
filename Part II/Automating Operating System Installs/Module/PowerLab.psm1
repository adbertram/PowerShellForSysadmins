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

function Install-PowerLabOperatingSystem {
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$VmName,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$OperatingSystem = 'Server 2016',

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[ValidateSet('ServerStandardCore')]
		[string]$OperatingSystemEdition = 'ServerStandardCore',

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$DiskSize = 40GB,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$VhdFormat = 'VHDX',

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$VhdType = 'Dynamic',

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$VhdPartitionStyle = 'GPT',

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$VhdPath
	)
	
	## Assuming we have multiple unattend XML files in this folder named <VMName>.xml
	$answerFile = Get-Item -Path "$PSScriptRoot\$VMName.xml"

	## Dot-source the script. Since the script has a function, doing this will make the function inside the script available
	. "$PSScriptRoot\Convert-WindowsImage.ps1"

	## Here is where we could add mulitple OS support picking the right ISO depending on the OS version chosen
	$baseIsoPath = 'C:\PowerLab\ISOs'
	switch ($OperatingSystem) {
		'Server 2016' {
			$isoFilePath = "$baseIsoPath\en_windows_server_2016_x64_dvd_9718492.iso"
		}
		default {
			throw "Unrecognized input: [$_]"
		}
	}

	## Assuming all VHDs live here and are called <VMName>.vhdx
	$vhdBasePath = 'C:\PowerLab\VHDs'

	$convertParams = @{
		SourcePath        = $isoFilePath
		SizeBytes         = $DiskSize
		Edition           = $OperatingSystemEdition
		VHDFormat         = $VhdFormat
		VHDType           = $VhdType
		VHDPartitionStyle = 'GPT'
		UnattendPath      = $answerFile.FullName
	}
	if ($PSBoundParameters.ContainsKey('VhdPath')) {
		$convertParams.VHDPath = $VhdPath
	} else {
		$convertParams.VHDPath = "$vhdBasePath\$VMName.vhdx"
	}

	Convert-WindowsImage @convertParams

	$vm = Get-Vm -Name $VmName
	$vm | Add-VMHardDiskDrive -Path $convertParams.VHDPath
	$bootOrder = ($vm | Get-VMFirmware).Bootorder
	if ($bootOrder[0].BootType -ne 'Drive') {
		$vm | Set-VMFirmware -FirstBootDevice $vm.HardDrives[0]
	}
}