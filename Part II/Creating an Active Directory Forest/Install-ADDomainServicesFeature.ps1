$cred = Import-CliXml -Path C:\PowerLab\VMCredential.xml
Invoke-Command -VMName 'LABDC' -Credential $cred -ScriptBlock { Install-windowsfeature -Name AD-Domain-Services }