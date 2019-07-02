$isoFilePath = 'C:\PowerLab\ISOs\en_windows_server_2016_x64_dvd_9718492.iso'
$answerFilePath = 'C:\PowerShellForSysAdmins\Part II\Automating Operating System Installs\LABDC.xml'

$convertParams = @{
    SourcePath        = $isoFilePath
    SizeBytes         = 40GB
    Edition           = 'ServerStandardCore'
    VHDFormat         = 'VHDX'
    VHDPath           = 'C:\PowerLab\VHDs\LABDC.vhdx'
    VHDType           = 'Dynamic'
    VHDPartitionStyle = 'GPT'
    UnattendPath      = $answerFilePath
}

. 'C:\PowerShellForSysAdmins\Part II\Automating Operating System Installs\Convert-WindowsImage.ps1'

Convert-WindowsImage @convertParams

$vm = Get-Vm -Name 'LABDC'
$vm | Add-VMHardDiskDrive -Path 'C:\PowerLab\VHDs\LABDC.vhdx'
$bootOrder = ($vm | Get-VMFirmware).Bootorder
if ($bootOrder[0].BootType -ne 'Drive') {
    $vm | Set-VMFirmware -FirstBootDevice $vm.HardDrives[0]
}