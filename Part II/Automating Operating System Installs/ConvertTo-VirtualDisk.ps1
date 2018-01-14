function ConvertTo-VirtualDisk {
	[CmdletBinding()]
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

	$ErrorActionPreference = 'Stop'

	$projectRootUnc = '\\HYPERVSRV\c$\PowerLab'
	Copy-Item -Path "$projectRootUnc\Convert-WindowsImage.ps1" -Destination $projectRootUnc -Force
		
	## Copy the answer file to the Hyper-V host
	$answerFileName = $AnswerFilePath | Split-Path -Leaf
	Copy-Item -Path $AnswerFilePath -Destination $projectRootUnc -Force
	$localTempAnswerFilePath = Join-Path -Path ($projectrootunc -replace '.*(\w)\$', '$1:') -ChildPath $answerFileName
		
	$sb = {
		. $args[0]
		$convertParams = @{
			SourcePath        = $args[1]
			SizeBytes         = $args[2]
			Edition           = $args[3]
			VHDFormat         = $args[4]
			VHDPath           = $args[5]
			VHDType           = $args[6]
			VHDPartitionStyle = $args[7]
		}
		if ($args[8]) {
			$convertParams.UnattendPath = $args[8]
		}
		Convert-WindowsImage @convertParams
		Get-Vhd -Path $args[5]
	}

	$icmParams = @{
		ScriptBlock  = $sb
		ArgumentList = 'C:\PowerLab\Convert-WindowsImage.ps1', $IsoFilePath, $SizeBytes, $Edition, $VhdFormat, $VhdPath, $Sizing, $VHDPartitionStyle, $localTempAnswerFilePath
	}
	InvokeHyperVCommand @icmParams
}