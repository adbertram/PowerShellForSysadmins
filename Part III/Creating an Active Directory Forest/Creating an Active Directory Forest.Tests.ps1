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

}

describe 'LABDC Operating System' {

	BeforeAll {
		$cred = Import-Clixml -Path C:\PowerLab\DomainCredential.xml
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

	context 'Windows' {

		it 'sets the expected IP defined in the unattend XML file' {
			invoke-command -Session $session -ScriptBlock { (Get-NetIPAddress -AddressFamily IPv4 | where { $_.InterfaceAlias -notmatch 'Loopback' }).IPAddress } | should be '10.0.0.100'
		}

		it 'deploys the expected Windows version' {
			Invoke-Command -Session $session -ScriptBlock { (Get-CimInstance -ClassName Win32_OperatingSystem).Caption } | should belike 'Microsoft Windows Server 2016*'

		}
	}
}

describe 'Active Directory Forest' {

	BeforeAll {
		$domainCred = Import-Clixml -Path C:\PowerLab\DomainCredential.xml
		$session = New-PSSession -VMName 'LABDC' -Credential $domainCred

		$adobjectSpreadsheetPath = 'C:\PowerShellForSysAdmins\Part II\Creating an Active Directory Forest\ActiveDirectoryObjects.xlsx'
		$expectedUsers = Import-Excel -Path $adobjectSpreadsheetPath -WorksheetName Users
		$expectedGroups = Import-Excel -Path $adobjectSpreadsheetPath -WorksheetName Groups
	}

	AfterAll {
		$session | Remove-PSSession
	}

	context 'Domain' {
		$domain = Invoke-Command -Session $session -ScriptBlock { Get-AdDomain }
		$forest = Invoke-Command -Session $session -ScriptBlock { Get-AdForest }

		it "the domain mode should be Windows2016Domain" {
			$domain.DomainMode | should be 'Windows2016Domain'
		}

		it "the forest mode should be WinThreshold" {
			$forest.ForestMode | should be 'Windows2016Forest'
		}

		it "the domain name should be powerlab.local" {
			$domain.Name | should be 'powerlab'
		}
	}

	context 'Organizational Units' {

		$allOus = ($expectedUsers.OUName + $expectedGroups.OUName) | Select-Object -Unique
		foreach ($ou in $allOus) {
			it "the OU [$ou] should exist" {
				Invoke-Command -Session $session -ScriptBlock { Get-AdOrganizationalUnit -Filter "Name -eq '$using:ou'" } | should not benullorempty
			}
		}
	}

	context 'Users' {
		foreach ($user in $expectedUsers) {
			$actualUser = Invoke-Command -Session $session -ScriptBlock { Get-AdUser -Filter "Name -eq '$($using:user.UserName)'" }
			it "the user [$($user.UserName)] should exist" {
				$actualUser | should not benullorempty
			}
			it "the user [$($user.UserName)] should be in the [$($user.OUName)] OU" {
				($actualUser.DistinguishedName -replace "CN=$($user.UserName),") | should be "OU=$($user.OUName),DC=powerlab,DC=local"
			}
			it "the user [$($user.UserName)] should be in the [$($user.MemberOf)] group" {
				$groupMembers = Invoke-Command -Session $session -ScriptBlock { (Get-AdGroupMember -Identity $using:user.MemberOf).Name }
				$groupMembers -eq $user.UserName | should not benullorempty
			}
		}
	}

	context 'Groups' {
		foreach ($group in $expectedGroups) {
			$actualGroup = Invoke-Command -Session $session -ScriptBlock { Get-AdGroup -Filter "Name -eq '$($using:group.GroupName)'" }
			it "the group [$($group.GroupName)] should exist" {
				$actualGroup | should not benullorempty
			}
			it "the group [$($group.GroupName)] should be in the [$($group.OUName)] OU" {
				($actualGroup.DistinguishedName -replace "CN=$($group.GroupName),") | should be "OU=$($group.OUName),DC=powerlab,DC=local"
			}
		}
	}
}