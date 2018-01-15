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

## Define the base folder
$scriptPath = 'C:\Automate-The-Boring-Stuff-With-PowerShell\Part II\Automating Operating System Installs'

## Assuming we have multiple unattend XML files in this folder named <VMName>.xml
$answerFile = Get-Item -Path "$scriptPath\$VMName.xml"

## Dot-source the script. Since the script has a function, doing this will make the function inside the script available
. "$scriptPath\Convert-WindowsImage.ps1"

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
	VHDPath           = 
	VHDType           = $VhdType
	VHDPartitionStyle = 'GPT'
	UnattendPath      = $UnattendFilePath
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