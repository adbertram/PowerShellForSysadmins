param
(
	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[ValidatePattern('\.vhdx?$')]
	[string]$VhdPath,
		
	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$IsoFilePath,
		
	[Parameter()]
	[ValidateNotNullOrEmpty()]
	[string]$AnswerFilePath,
		
	[Parameter()]
	[ValidateNotNullOrEmpty()]
	[ValidateSet('Dynamic', 'Fixed')]
	[string]$Sizing = 'Dynamic',
		
	[Parameter()]
	[ValidateNotNullOrEmpty()]
	[string]$Edition = 'ServerStandardCore',
		
	[Parameter()]
	[ValidateNotNullOrEmpty()]
	[ValidateRange(512MB, 64TB)]
	[Uint64]$SizeBytes = 40GB,
		
	[Parameter()]
	[ValidateNotNullOrEmpty()]
	[ValidateSet('VHD', 'VHDX')]
	[string]$VhdFormat = 'VHDX',
	
	[Parameter()]
	[ValidateNotNullOrEmpty()]
	[string]$VHDPartitionStyle = 'GPT'
		
)

## Dot-source the script. Since the script has a function, doing this will make the function inside the script available
. 'C:\Automate-The-Boring-Stuff-With-PowerShell\Part II\Automating Operating System Installs\Convert-WindowsImage.ps1'
$convertParams = @{
	SourcePath        = $IsoFilePath
	SizeBytes         = $SizeBytes
	Edition           = $Edition
	VHDFormat         = $VhdFormat
	VHDPath           = $VhdPath
	VHDType           = $Sizing
	VHDPartitionStyle = $VHDPartitionStyle
	UnattendPath      = $AnswerFilePath
}

Convert-WindowsImage @convertParams
Get-Vhd -Path $VHDPath