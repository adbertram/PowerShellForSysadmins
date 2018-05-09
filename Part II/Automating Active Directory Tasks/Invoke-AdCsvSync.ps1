$syncFieldMap = @{
	fname = 'GivenName'
	lname = 'Surname'
	dept  = 'Department'
}

$fieldMatchIds = @{
	AD  = @('givenName', 'surName')
	CSV = @('fname', 'lname')
}

function Get-AcmeEmployeeFromCsv {
	[CmdletBinding()]
	param
	(
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[string]$CsvFilePath = 'C:\Employees.csv'
	)
	try {
		## "Map" the properties of the CSV to AD property names
		$properties = $syncFieldMap.GetEnumerator() | ForEach-Object {
			@{
				Name       = $_.Value
				Expression = [scriptblock]::Create("`$_.$($_.Key)")
			}
		}

		## Create a unique ID on the fly and make that a property
		$uniqueIdProperty = '"{0}{1}" -f '
		$uniqueIdProperty = $uniqueIdProperty += ($fieldMatchIds.CSV | ForEach-Object { '$_.{0}' -f $_ }) -join ','

		$properties += @{
			Name       = 'UniqueID'
			Expression = [scriptblock]::Create($uniqueIdProperty)
		}

		## Read the CSV and use Select-Object's calculated properties to do the "conversion"
		Import-Csv -Path $CsvFilePath | Select-Object -Property $properties

	} catch {
		Write-Error -Message $_.Exception.Message
	}
}

function Get-AcmeEmployeeFromAD {
	[CmdletBinding()]
	param
	()

	try {
		$uniqueIdProperty = '"{0}{1}" -f '
		$uniqueIdProperty += ($fieldMatchIds.AD | ForEach-Object { '$_.{0}' -f $_ }) -join ','

		$uniqueIdProperty = @{
			Name       = 'UniqueID'
			Expression = [scriptblock]::Create($uniqueIdProperty)
		}

		Get-AdUser -Filter * -Properties @($syncFieldMap.Values) | Select-Object *, $uniqueIdProperty

	} catch {
		Write-Error -Message $_.Exception.Message
	}
}

function Find-UserMatch {
	[OutputType()]
	[CmdletBinding()]
	param
	(
		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[object[]]$AdUsers = (Get-AcmeEmployeeFromAD),

		[Parameter()]
		[ValidateNotNullOrEmpty()]
		[object]$CsvUsers = (Get-AcmeEmployeeFromCsv)
	)

	$AdUsers.foreach({
			$adUniqueId = $_.UniqueID
			if ($adUniqueId) {
				$output = @{
					CSVProperties    = 'NoMatch'
					ADSamAccountName = $_.samAccountName
				}
				if ($adUniqueId -in $CsvUsers.UniqueId) {
					$output.CSVProperties = ($CsvUsers.Where({ $_.UniqueId -eq $adUniqueId}))
				}
				[pscustomobject]$output
			}
		})
}

## Find all of the CSV <--> AD user account matches
$positiveMatches = (Find-UserMatch).where({ $_.CSVProperties -ne 'NoMatch' })
foreach ($positiveMatch in $positiveMatches) {
	## Create the splatting parameters for Set-AdUser using the identity of the AD samAccountName
	$setAdUserParams = @{
		Identity = $positiveMatch.ADSamAccountName
	}

	## Read each property value that was in the CSV file
	$positiveMatch.CSVProperties.foreach({
			## Add a parameter to Set-AdUser for all of the CSV properties excluding UniqueId
			$_.PSObject.Properties.where({ $_.Name -ne 'UniqueID' }).foreach({
					$setAdUserParams[$_.Name] = $_.Value
				})
		})
	Set-AdUser @setAdUserParams
}