param
(
	[Parameter(Mandatory)]
	[ValidateNotNullOrEmpty()]
	[string]$ComputerName
)

try {
	$credConfig = $script:LabConfiguration.DefaultOperatingSystemConfiguration.Users.where({ $_.Name -ne 'Administrator' })
	$cred = New-PSCredential -UserName $credConfig.name -Password $credConfig.Password
	
	## Copy the SQL server config ini to the VM
	$copiedConfigFile = Copy-Item -Path "$modulePath\SqlServer.ini" -Destination "\\$ComputerName\c$" -PassThru
	PrepareSqlServerInstallConfigFile -Path $copiedConfigFile

	$sqlConfigFilePath = $copiedConfigFile.FullName.Replace("\\$ComputerName\c$\", 'C:\')
		
	$isoConfig = $script:LabConfiguration.ISOs.where({$_.Name -eq 'SQL Server 2016'})
	
	$isoPath = Join-Path -Path $script:LabConfiguration.IsoFolderPath -ChildPath $isoConfig.FileName
	$uncIsoPath = ConvertToUncPath -LocalFilePath $isoPath -ComputerName $script:LabConfiguration.HostServer.Name
	
	## Copy the ISO to the VM
	$localDestIsoPath = 'C:\{0}' -f $isoConfig.FileName
	$destIsoPath = ConvertToUncPath -ComputerName $ComputerName -LocalFilePath $localDestIsoPath
	if (-not (Test-Path -Path $destIsoPath -PathType Leaf)) {
		Write-Verbose -Message "Copying SQL Server ISO to [$($destisoPath)]..."
		Copy-Item -Path $uncIsoPath -Destination $destIsoPath -Force
	}
	
	## Execute the installer
	Write-Verbose -Message 'Running SQL Server installer...'
	$icmParams = @{
		ComputerName = $ComputerName
		ArgumentList = $sqlConfigFilePath, $localDestIsoPath
		ScriptBlock  = {
			$image = Mount-DiskImage -ImagePath $args[1] -PassThru
			$installerPath = "$(($image | Get-Volume).DriveLetter):"
			$null = & "$installerPath\setup.exe" "/CONFIGURATIONFILE=$($args[0])"
			$image | Dismount-DiskImage
		}
	}
	InvokeVmCommand @icmParams
} catch {
	$PSCmdlet.ThrowTerminatingError($_)
} finally {
	Write-Verbose -Message 'Cleaning up installer remnants...'
	Remove-Item -Path $destIsoPath, $copiedConfigFile.FullName -Recurse -ErrorAction Ignore
}