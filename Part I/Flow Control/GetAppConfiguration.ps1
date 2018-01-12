# $servers = 'SRV1', 'SRV2', 'SRV3'
# foreach ($server in $servers) {
# 	$filePath = "\\$server\c$\App_configuration.txt"
# 	if (-not (Test-Connection -ComputerName $server -Quiet -Count 1)) {
# 		Write-Error -Message "The server [$server] is not responding!"
# 	} elseif (-not (Test-Path -Path $filePath)) {
# 		Write-Error -Message "The file [$filePath] could not be found!"
# 	} else {
# 		$fileContent = Get-Content -Path "\\$server\c$\App_configuration.txt"
# 	}
# }

# switch ($fileContent) {
# 	'foo' {
# 		Write-Host "The file contained [$_]. We're good."
# 		break
# 	}
# 	'bar' {
# 		Write-Host "The file contained [$_]. We're good."
# 		break
# 	}
# 	'baz' {
# 		Write-Host "The file contained [$_]. We're good."
# 		break
# 	}
# 	default {
# 		Write-Host "The file content [$_] did not contain any of the strings!"
# 	}
# }
