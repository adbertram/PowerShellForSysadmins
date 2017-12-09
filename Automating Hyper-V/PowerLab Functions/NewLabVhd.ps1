function NewLabVhd {
	[CmdletBinding(DefaultParameterSetName = 'None')]
	param
	(
		
		[Parameter(Mandatory, ParameterSetName = 'OSInstall')]
		[ValidateNotNullOrEmpty()]
		[string]$Name,
		
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[ValidateRange(512MB, 1TB)]
		[int64]$Size = (Invoke-Expression $script:LabConfiguration.DefaultVirtualMachineConfiguration.VHDConfig.Size),
	
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[ValidateSet('Dynamic', 'Fixed')]
		[string]$Sizing = $script:LabConfiguration.DefaultVirtualMachineConfiguration.VHDConfig.Sizing,
	
		[Parameter(Mandatory, ParameterSetName = 'OSInstall')]
		[ValidateNotNullOrEmpty()]
		[ValidateScript({ TestIsOsNameValid $_ })]
		[string]$OperatingSystem,

		[Parameter(Mandatory, ParameterSetName = 'OSInstall')]
		[ValidateNotNullOrEmpty()]
		[string]$AnswerFilePath,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[switch]$PassThru
	)
	begin {
		$ErrorActionPreference = 'Stop'
	}
	process {
		try {	
			$params = @{
				'SizeBytes' = $Size
			}
			$vhdPath = $script:LabConfiguration.DefaultVirtualMachineConfiguration.VHDConfig.Path
			if ($PSBoundParameters.ContainsKey('OperatingSystem')) {
				$isoFileName = $script:LabConfiguration.ISOs.where({ $_.Name -eq $OperatingSystem }).FileName

				$cvtParams = $params + @{
					IsoFilePath    = Join-Path -Path $script:LabConfiguration.IsoFolderPath -ChildPath $isoFileName
					VhdPath        = '{0}.vhdx' -f (Join-Path -Path $vhdPath -ChildPath $Name)
					VhdFormat      = 'VHDX'
					Sizing         = $Sizing
					AnswerFilePath = $AnswerFilePath
				}
				
				$vhd = ConvertToVirtualDisk @cvtParams
			} else {
				$params.ComputerName = $script:LabConfiguration.HostServer.Name
				$params.Path = "$vhdPath\$Name.vhdx"
				if ($Sizing -eq 'Dynamic') {
					$params.Dynamic = $true
				} elseif ($Sizing -eq 'Fixed') {
					$params.Fixed = $true
				}

				$invParams = @{
					ScriptBlock  = { $params = $args[0]; New-VHD @params }
					ArgumentList = $params
				}
				$vhd = InvokeHyperVCommand @invParams
			}
			if ($PassThru.IsPresent) {
				$vhd
			}
		} catch {
			Write-Error $_.Exception.Message
		}
	}
}