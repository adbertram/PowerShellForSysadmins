describe 'Creating an Active Directory Forest' {

	BeforeAll {
		$domainCred = Import-Clixml -Path C:\PowerLab\DomainCredential.xml
		$session = New-PSSession -VMName 'LABDC' -Credential $domainCred

		$adobjectSpreadsheetPath = 'C:\Automate-The-Boring-Stuff-With-PowerShell\Part II\Creating an Active Directory Forest\ActiveDirectoryObjects.xlsx'
		$expectedUsers = Import-Excel -Path $adobjectSpreadsheetPath -WorksheetName Users
		$expectedGroups = Import-Excel -Path $adobjectSpreadsheetPath -WorksheetName Groups
	}

	AfterAll {
		$session | Remove-PSSession
	}

	context 'Domain' {
		$domain = Invoke-Command -Session $session -ScriptBlock { Get-AdDomain }
		$forest = Invoke-Command -Session $session -ScriptBlock { Get-AdForest }

		it "the domain mode should be WinThreshold" {
			$domain.DomainMode | should be 'WinThreshold'
		}

		it "the forest mode should be WinThreshold" {
			$forest.DomainMode | should be 'WinThreshold'
		}

		it "the domain name should be powerlab.local" {
			$domain.Name | should be 'powerlab.local'
		}
	}

	context 'Organizational Units' {

		$allOus = ($expectedUsers.OUName + $expectedGroups.OUName) | Select-Object -Unique
		$allOus | ForEach-Object {
			Invoke-Command -Session $session -ScriptBlock { Get-AdOrganizationalUnit -Filter "Name -eq '$_'" } | should not benullorempty
		}
	}

	context 'Users' {
		$expectedUsers | ForEach-Object {
			$actualUser = Invoke-Command -Session $session -ScriptBlock { Get-AdUser -Filter "Name -eq '$_'" }
			$actualUser | should not benullorempty
			$actualUser.Name | should be $_.Name
			$actualUser.Path | should be "OU=$($_.OUName),DC=powerlab,DC=local"
			(Get-AdGroupMember -Identity $_.MemberOf).Name | should contain $_.Name
		}
	}

	context 'Groups' {
		$expectedGroups | ForEach-Object {
			$actualGroup = Invoke-Command -Session $session -ScriptBlock { Get-AdGroup -Filter "Name -eq '$_'" }
			$actualGroup | should not benullorempty
			$actualGroup.Name | should be $_.Name
			$actualGroup.Path | should be "OU=$($_.OUName),DC=powerlab,DC=local"
		}
	}
}