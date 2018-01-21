param(
	[Parameter(Mandatory)]
	[string]$SpreadsheetPath
)

$users = Import-Excel -Path $SpreadsheetPath -WorksheetName Users
$groups = Import-Excel -Path $SpreadsheetPath -WorksheetName Groups

$cred = Import-CliXml -Path 'C:\PowerLab\DomainCredential.xml'
$dcSession = New-PSSession -VMName LABDC -Credential $cred

$scriptBlock = {
	foreach ($group in $using:groups) {
		if (-not (Get-AdOrganizationalUnit -Filter "Name -eq '$($group.OUName)'")) {
			New-AdOrganizationalUnit -Name $group.OUName
		}
		if (-not (Get-AdGroup -Filter "Name -eq '$($group.GroupName)'")) {
			New-AdGroup -Name $group.GroupName -GroupScope $group.Type -Path "OU=$($group.OUName),DC=powerlab,DC=local"
		}
	}

	foreach ($user in $using:users) {
		if (-not (Get-AdOrganizationalUnit -Filter "Name -eq '$($user.OUName)'")) {
			New-AdOrganizationalUnit -Name $user.OUName
		}
		if (-not (Get-AdUser -Filter "Name -eq '$($user.UserName)'")) {
			New-AdUser -Name $user.UserName -Path "OU=$($user.OUName),DC=powerlab,DC=local"
		}
		if ($user.UserName -notin (Get-AdGroupMember -Identity $user.MemberOf).Name) {
			Add-AdGroupMember -Identity $user.MemberOf -Members $user.UserName
		}
	}
}

Invoke-Command -Session $dcSession -ScriptBlock $scriptBlock
$dcSession | Remove-PSSession