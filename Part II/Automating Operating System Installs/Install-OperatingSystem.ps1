param
(
	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[object]$Vm
)

$scriptPath = 'C:\Automate-The-Boring-Stuff-With-PowerShell\Part II\Automating Operating System Installs'
$answerFile = Get-Item -Path "$scriptPath\LABDC.xml"

## Dot-source the script. Since the script has a function, doing this will make the function inside the script available
. "$scriptPath\Convert-WindowsImage.ps1"
$convertParams = @{
	SourcePath        = 'C:\PowerLab\ISOs\en_windows_server_2016_x64_dvd_9718492.iso'
	SizeBytes         = 40GB
	Edition           = 'ServerStandardCore'
	VHDFormat         = 'VHDX'
	VHDPath           = 'C:\PowerLab\VHDs\LABDC.vhdx'
	VHDType           = 'Dynamic'
	VHDPartitionStyle = 'GPT'
	UnattendPath      = $AnswerFile.FullName
}

Convert-WindowsImage @convertParams
Get-Vhd -Path $VHDPath

$vm = Get-Vm -Name $vm.Name
$vm | Add-VMHardDiskDrive -Path $vhd.Path
$bootOrder = ($vm | Get-VMFirmware).Bootorder
if ($bootOrder[0].BootType -ne 'Drive') {
	$vm | Set-VMFirmware -FirstBootDevice $vm.HardDrives[0]
}