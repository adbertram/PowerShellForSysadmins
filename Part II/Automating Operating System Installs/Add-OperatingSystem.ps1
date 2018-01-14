function Add-OperatingSystem {
 [CmdletBinding()]
	param
	(
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[object]$Vm,
	
		[Parameter(Mandatory)]
		[ValidateNotNullOrEmpty()]
		[string]$OperatingSystem,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$VmType,

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[switch]$DomainJoined
	)

	$ErrorActionPreference = 'Stop'

	try {
		$templateAnswerFilePath = Get-Item -Path "\\HYPERVSRV\c$\PowerLab\$OperatingSystem.xml"
		if ($OperatingSystem -eq 'Windows Server 2016') {
			$isoConfig = @{
				FileName   = 'en_windows_server_2016_x64_dvd_9718492.iso'
				Type       = 'OS'
				Name       = 'Windows Server 2016'
				ProductKey = '78NRB-C3P3J-DG4RM-36C7V-8HWT4'
			}
		} else {
			throw "The operating system [$OperatingSystem] is not currently supported."
		}
		
		$ipAddress = New-VmIpAddress
		$prepParams = @{
			Path         = $templateAnswerFilePath
			VMName       = $vm.Name
			IpAddress    = $ipAddress
			DnsServer    = '192.168.0.100'
			ProductKey   = $isoConfig.ProductKey
			UserName     = 'PowerLabUser'
			UserPassword = 'P@$$w0rd12'
			DomainName   = 'powerlab.local'
		}
		if ($PSBoundParameters.ContainsKey('VmType')) {
			$prepParams.VmType = $VmType
		}
		$answerFile = Prepare-UnattendXmlFile @prepParams

		if (-not ($vhd = New-LabVhd -OperatingSystem $OperatingSystem -AnswerFilePath $answerFile.FullName -Name $vm.Name -PassThru)) {
			throw 'VHD creation failed'
		}

		$invParams = @{
			Scriptblock  = {
				$vm = Get-Vm -Name $args[0]
				$vm | Add-VMHardDiskDrive -Path $args[1]
				$bootOrder = ($vm | Get-VMFirmware).Bootorder
				if ($bootOrder[0].BootType -ne 'Drive') {
					$vm | Set-VMFirmware -FirstBootDevice $vm.HardDrives[0]
				}
			}
			ArgumentList = $Vm.Name, $vhd.Path
		}
		Invoke-Command @invParams
	} catch {
		$PSCmdlet.ThrowTerminatingError($_)
	}
}