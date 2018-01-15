param
(
	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[object]$Vm,
	
	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$OperatingSystem
)

$scriptPath = 'C:\Automate-The-Boring-Stuff-With-PowerShell\Part II\Automating Operating System Installs'
$answerFile = Get-Item -Path "$scriptPath\LABDC.xml"

$cvtParams = @{
	IsoFilePath    = 'C:\PowerLab\ISOs\en_windows_server_2016_x64_dvd_9718492.iso'
	VhdPath        = 'C:\PowerLab\VHDs\LABDC.vhdx'
	AnswerFilePath = $AnswerFile.FullName
}

$vhd = & "$scriptPath\ConvertTo-VirtualDisk.ps1" @cvtParams

$vm = Get-Vm -Name $vm.Name
$vm | Add-VMHardDiskDrive -Path $vhd.Path
$bootOrder = ($vm | Get-VMFirmware).Bootorder
if ($bootOrder[0].BootType -ne 'Drive') {
	$vm | Set-VMFirmware -FirstBootDevice $vm.HardDrives[0]
}