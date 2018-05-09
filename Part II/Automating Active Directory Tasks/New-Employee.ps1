#requires -Module ActiveDirectory

[CmdletBinding(ConfirmImpact = 'High', SupportsShouldProcess)]
param (
	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$FirstName,

	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$LastName,

	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$Department,

	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[int]$EmployeeNumber
)

try {
	## First attempt to create a username with first initial/last name
	$userName = '{0}{1}' -f $FirstName.Substring(0, 1), $LastName
	
	## Use a while loop to check for different variations of the username if the original is already taken
	## In this case, if first initial/last name is taken, try first second initials/last name, third initials, etc
	## until a unique username is found.
	$i = 2
	while ((Get-AdUser -Filter "samAccountName -eq '$userName'") -and ($userName -notlike "$FirstName*")) {
		Write-Warning -Message "The username [$($userName)] already exists. Trying another..."
		$userName = '{0}{1}' -f $FirstName.Substring(0, $i), $LastName
		Start-Sleep -Seconds 1
		$i++
	}

	## Ensure we didn't exhaust all username options
	if ($userName -like "$FirstName*") {
		throw 'No available username could be found'
	} elseif (-not ($ou = Get-ADOrganizationalUnit -Filter "Name -eq '$Department'")) {
		## Check to see if the OU with the name of the department exists
		throw "The Active Directory OU for department [$($Department)] could not be found."
	} elseif (-not (Get-AdGroup -Filter "Name -eq '$Department'")) {
		throw "The group [$($Department)] does not exist."
	} else {
		## Create a random password
		Add-Type -AssemblyName 'System.Web'
		$password = [System.Web.Security.Membership]::GeneratePassword((Get-Random -Minimum 20 -Maximum 32), 3)
		$secPw = ConvertTo-SecureString -String $password -AsPlainText -Force

		$newUserParams = @{
			GivenName             = $FirstName
			EmployeeNumber        = $EmployeeNumber
			Surname               = $LastName
			Name                  = $userName
			AccountPassword       = $secPw
			ChangePasswordAtLogon = $true
			Enabled               = $true
			Department            = $Department
			Path                  = $ou.DistinguishedName
			Confirm               = $false
		}
		if ($PSCmdlet.ShouldProcess("AD user [$userName]", "Create AD user $FirstName $LastName")) {
			## Create the user
			New-AdUser @newUserParams
			
			## Add the user to the department group
			Add-AdGroupMember -Identity $Department -Members $userName

			[pscustomobject]@{
				FirstName      = $FirstName
				LastName       = $LastName
				EmployeeNumber = $EmployeeNumber
				Department     = $Department
				Password       = [System.Runtime.InteropServices.marshal]::PtrToStringAuto([System.Runtime.InteropServices.marshal]::SecureStringToBSTR($secPw))
			}
		}
	}
} catch {
	Write-Error -Message $_.Exception.Message
}