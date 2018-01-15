describe 'Automating Operating System Installs' {

	BeforeAll {
		## Create a PSCredential object with the same user and password that's defined in the unattend XML file
		$secpasswd = ConvertTo-SecureString 'P@$$w0rd12' -AsPlainText -Force
		$mycreds = New-Object System.Management.Automation.PSCredential ('PowerLabUser', $secpasswd)
		$session = New-PSSession -VMName 'LABDC' -Credential $mycreds
	}

	AfterAll {
		$session | Remove-PSSession
	}

	context 'Virtual Disk' {
		
		$expectedVhdPath = 'C:\PowerLab\VHDs\LABDC.vhdx'

		it 'created a VHDX called LABDC in the expected location' {
			$expectedVhdPath | should exist
		}

		it 'attached the virtual disk to the expected VM' {
			Get-VM -Name LABDC | Get-VMHardDiskDrive | Where-Object { $_.Path -eq $expectedVhdPath } | should not benullorEmpty
		}

		it 'creates the expected VHDX format' {
			(Get-VHD -Path $expectedVhdPath).VhdFormat | should be 'VHDX'
		}

		it 'creates the expected VHDX partition style' {
			(Invoke-Command -Session $session -ScriptBlock { Get-CimInstance Win32_DiskPartition -Filter "Index = '1'"}).Type | should be 'GPT: Basic Data'
		}

		it 'creates the expected VHDX type' {
			(Get-VHD -Path $expectedVhdPath).VhdType | should be 'Dynamic'
		}

		it 'creates the VHDDX of the expected size' {
			(Get-VHD -Path $expectedVhdPath).Size / 1GB | should be 40
		}
	}

	context 'Operating System' {

		it 'sets the expected IP defined in the unattend XML file' {
			invoke-command -Session $session -ScriptBlock { (Get-NetIPAddress -AddressFamily IPv4 | where { $_.InterfaceAlias -notmatch 'Loopback' }).IPAddress } | should be '10.0.0.100'
		}

		it 'deploys the expected Windows version' {
			Invoke-Command -Session $session -ScriptBlock { (Get-CimInstance -ClassName Win32_OperatingSystem).Caption } | should belike 'Microsoft Windows Server 2016*'

		}
	}
}