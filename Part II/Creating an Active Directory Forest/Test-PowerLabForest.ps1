$domainCred = Import-CliXml -Path C:\PowerLab\DomainCredential.xml
Invoke-Command -VMName 'LABDC' -Credential $domainCred -ScriptBlock { Get-AdUser -Filter * }