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

if (-not ($vhd = & "$scriptPath\New-LabVhd.ps1" -OperatingSystem $OperatingSystem -AnswerFilePath $answerFile.FullName -Name $vm.Name -PassThru)) {
	throw 'VHD creation failed'
}

$vm = Get-Vm -Name $vm.Name
$vm | Add-VMHardDiskDrive -Path $vhd.Path
$bootOrder = ($vm | Get-VMFirmware).Bootorder
if ($bootOrder[0].BootType -ne 'Drive') {
	$vm | Set-VMFirmware -FirstBootDevice $vm.HardDrives[0]
}