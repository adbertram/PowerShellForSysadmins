describe 'PowerLab setup' {
	context 'Virtual Switch' {
		it 'created a virtual switch called PowerLab' {
			Get-VmSwitch -Name 'PowerLab' -ErrorAction SilentlyContinue | should not benullorEmpty
		}
	}
}

describe 'LABDC VM' {

	$createdVM = Get-Vm -Name 'LABDC' -ErrorAction SilentlyContinue

	context 'Virtual Machine' {
		it 'created a virtual machine called LABDC' {
			$createdVM | should not benullorEmpty
		}
	}

	context 'Virtual Hard Disk' {
		it 'created a VHDX called MYVM at C:\PowerLab\VHDs' {
			'C:\PowerLab\VHDs\MYVM.vhdx' | should exist
		}

		it 'attached the MYVM VHDX to the MYVM VM' {
			$createdVM | Get-VMHardDiskDrive | Where-Object { $_.Path -eq 'C:\PowerLab\VHDs\MYVM.vhdx' } | should not benullorEmpty
		}
	}
}

describe 'LABDC Operating System' {

	BeforeAll {
		$cred = Import-Clixml -Path C:\PowerLab\VMCredential.xml
		$session = New-PSSession -VMName 'LABDC' -Credential $cred
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