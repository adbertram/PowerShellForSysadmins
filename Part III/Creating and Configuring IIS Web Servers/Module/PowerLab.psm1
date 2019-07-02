function New-PowerLabSwitch {
    param(
        [Parameter()]
        [string]$SwitchName = 'PowerLab',

        [Parameter()]
        [string]$SwitchType = 'External'
    )

    if (-not (Get-VmSwitch -Name $SwitchName -SwitchType $SwitchType -ErrorAction SilentlyContinue)) {
        $null = New-VMSwitch -Name $SwitchName -SwitchType $SwitchType
    } else {
        Write-Verbose -Message "The switch [$($SwitchName)] has already been created."
    }
}

function New-PowerLabVm {
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter()]
        [string]$Path = 'C:\PowerLab\VMs',

        [Parameter()]
        [string]$Memory = 4GB,

        [Parameter()]
        [string]$Switch = 'PowerLab',

        [Parameter()]
        [ValidateRange(1, 2)]
        [int]$Generation = 2,

        [Parameter()]
        [switch]$PassThru
    )

    if (-not (Get-Vm -Name $Name -ErrorAction SilentlyContinue)) {
        $null = New-VM -Name $Name -Path $Path -MemoryStartupBytes $Memory -Switch $Switch -Generation $Generation
    } else {
        Write-Verbose -Message "The VM [$($Name)] has already been created."
    }
    if ($PassThru.IsPresent) {
        Get-VM -Name $Name
    }
}

function New-PowerLabVhd {
    param
    (
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter()]
        [string]$AttachToVm,

        [Parameter()]
        [ValidateRange(512MB, 1TB)]
        [int64]$Size = 50GB,

        [Parameter()]
        [ValidateSet('Dynamic', 'Fixed')]
        [string]$Sizing = 'Dynamic',

        [Parameter()]
        [string]$Path = 'C:\PowerLab\VHDs'
    )

    $vhdxFileName = "$Name.vhdx"
    $vhdxFilePath = Join-Path -Path $Path -ChildPath "$Name.vhdx"

    ### Ensure we don't try to create a VHD when there's already one there
    if (-not (Test-Path -Path $vhdxFilePath -PathType Leaf)) {
        $params = @{
            SizeBytes = $Size
            Path      = $vhdxFilePath
        }
        if ($Sizing -eq 'Dynamic') {
            $params.Dynamic = $true
        } elseif ($Sizing -eq 'Fixed') {
            $params.Fixed = $true
        }

        New-VHD @params
        Write-Verbose -Message "Created new VHD at path [$($vhdxFilePath)]"
    }

    ### Attach either the newly created VHD or the one that was already there to the VM.
    if ($PSBoundParameters.ContainsKey('AttachToVm')) {
        if (-not ($vm = Get-VM -Name $AttachToVm -ErrorAction SilentlyContinue)) {
            Write-Warning -Message "The VM [$($AttachToVm)] does not exist. Unable to attach VHD."
        } elseif (-not ($vm | Get-VMHardDiskDrive | Where-Object { $_.Path -eq $vhdxFilePath })) {
            $vm | Add-VMHardDiskDrive -Path $vhdxFilePath
            Write-Verbose -Message "Attached VHDX [$($vhdxFilePath)] to VM [$($AttachToVM)]."
        } else {
            Write-Verbose -Message "VHDX [$($vhdxFilePath)] already attached to VM [$($AttachToVM)]."
        }
    }
}

function Install-PowerLabOperatingSystem {
    param
    (
        [Parameter(Mandatory)]
        [string]$VmName,

        [Parameter()]
        [string]$OperatingSystem = 'Server 2016',

        [Parameter()]
        [ValidateSet('ServerStandardCore')]
        [string]$OperatingSystemEdition = 'ServerStandardCore',

        [Parameter()]
        [string]$DiskSize = 40GB,

        [Parameter()]
        [string]$VhdFormat = 'VHDX',

        [Parameter()]
        [string]$VhdType = 'Dynamic',

        [Parameter()]
        [string]$VhdPartitionStyle = 'GPT',

        [Parameter()]
        [string]$VhdBaseFolderPath = 'C:\PowerLab\VHDs',

        [Parameter()]
        [string]$IsoBaseFolderPath = 'C:\PowerLab\ISOs',

        [Parameter()]
        [string]$VhdPath
    )
	
    ## Assuming we have multiple unattend XML files in this folder named <VMName>.xml
    $answerFile = Get-Item -Path "$PSScriptRoot\$VMName.xml"

    ## Dot-source the script. Since the script has a function, doing this will make the function inside the script available
    . "$PSScriptRoot\Convert-WindowsImage.ps1"

    ## Here is where we could add mulitple OS support picking the right ISO depending on the OS version chosen
    switch ($OperatingSystem) {
        'Server 2016' {
            $isoFilePath = "$IsoBaseFolderPath\en_windows_server_2016_x64_dvd_9718492.iso"
        }
        default {
            throw "Unrecognized input: [$_]"
        }
    }

    $convertParams = @{
        SourcePath        = $isoFilePath
        SizeBytes         = $DiskSize
        Edition           = $OperatingSystemEdition
        VHDFormat         = $VhdFormat
        VHDType           = $VhdType
        VHDPartitionStyle = 'GPT'
        UnattendPath      = $answerFile.FullName
    }
    if ($PSBoundParameters.ContainsKey('VhdPath')) {
        $convertParams.VHDPath = $VhdPath
    } else {
        $convertParams.VHDPath = "$VhdBaseFolderPath\$VMName.vhdx"
    }

    Convert-WindowsImage @convertParams

    $vm = Get-Vm -Name $VmName
    if (($vm | Get-VMHardDiskDrive).Path -ne $convertParams.VHDPath) {
        $vm | Add-VMHardDiskDrive -Path $convertParams.VHDPath
    }	
    $bootOrder = ($vm | Get-VMFirmware).Bootorder
    if ($bootOrder[0].BootType -ne 'Drive') {
        $vm | Set-VMFirmware -FirstBootDevice $vm.HardDrives[0]
    }
}

function New-PowerLabActiveDirectoryTestObject {
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
}

function New-PowerLabActiveDirectoryForest {
    param(
        [Parameter(Mandatory)]
        [pscredential]$Credential,

        [Parameter(Mandatory)]
        [string]$SafeModePassword,

        [Parameter()]
        [string]$VMName = 'LABDC',

        [Parameter()]
        [string]$DomainName = 'powerlab.local',

        [Parameter()]
        [string]$DomainMode = 'WinThreshold',

        [Parameter()]
        [string]$ForestMode = 'WinThreshold'
    )

    Invoke-Command -VMName $VMName -Credential $Credential -ScriptBlock {

        Install-windowsfeature -Name AD-Domain-Services
		
        $forestParams = @{
            DomainName                    = $using:DomainName
            DomainMode                    = $using:DomainMode
            ForestMode                    = $using:ForestMode
            Confirm                       = $false
            SafeModeAdministratorPassword = (ConvertTo-SecureString -AsPlainText -String $using:SafeModePassword -Force)
            WarningAction                 = 'Ignore'
        }
        $null = Install-ADDSForest @forestParams
    }
}

function Test-PowerLabActiveDirectoryForest {
    param(
        [Parameter(Mandatory)]
        [pscredential]$Credential,

        [Parameter()]
        [string]$VMName = 'LABDC'
    )

    Invoke-Command -Credential $Credential -ScriptBlock { Get-AdUser -Filter * }
}

function New-PowerLabServer {
    [CmdletBinding(DefaultParameterSetName = 'Generic')]
    param
    (
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [pscredential]$DomainCredential,

        [Parameter(Mandatory)]
        [pscredential]$VMCredential,

        [Parameter()]
        [string]$VMPath = 'C:\PowerLab\VMs',

        [Parameter()]
        [int64]$Memory = 4GB,

        [Parameter()]
        [string]$Switch = 'PowerLab',

        [Parameter()]
        [int]$Generation = 2,

        [Parameter()]
        [string]$DomainName = 'powerlab.local',

        [Parameter()]
        [ValidateSet('SQL', 'Web')]
        [string]$ServerType,

        [Parameter(ParameterSetName = 'SQL')]
        [ValidateNotNullOrEmpty()]
        [string]$AnswerFilePath = "C:\Program Files\WindowsPowerShell\Modules\PowerLab\SqlServer.ini",

        [Parameter(ParameterSetName = 'Web')]
        [switch]$NoDefaultWebsite
    )

    ## Build the VM
    $vmparams = @{
        Name       = $Name
        Path       = $VmPath
        Memory     = $Memory
        Switch     = $Switch
        Generation = $Generation
    }
    New-PowerLabVm @vmParams

    Install-PowerLabOperatingSystem -VmName $Name
    Start-VM -Name $Name

    Wait-Server -Name $Name -Status Online -Credential $VMCredential

    $addParams = @{
        DomainName = $DomainName
        Credential = $DomainCredential
        Restart    = $true
        Force      = $true
    }
    Invoke-Command -VMName $Name -ScriptBlock { Add-Computer @using:addParams } -Credential $VMCredential

    Wait-Server -Name $Name -Status Offline -Credential $VMCredential

    Wait-Server -Name $Name -Status Online -Credential $DomainCredential

    if ($PSBoundParameters.ContainsKey('ServerType')) {
        switch ($ServerType) {
            'Web' {
                Install-PowerLabWebServer -ComputerName $Name -DomainCredential $DomainCredential
                break
            }
            'SQL' {
                $tempFile = Copy-Item -Path $AnswerFilePath -Destination "C:\Program Files\WindowsPowerShell\Modules\PowerLab\temp.ini" -PassThru
                Install-PowerLabSqlServer -ComputerName $Name -AnswerFilePath $tempFile.FullName -DomainCredential $DomainCredential
                break
            }
            'Generic' {
                break
            }
            default {
                throw "Unrecognized server type: [$_]"
            }
        }
    }
}

function Wait-Server {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [ValidateSet('Online', 'Offline')]
        [string]$Status,

        [Parameter(Mandatory)]
        [pscredential]$Credential
    )

    if ($Status -eq 'Online') {
        $scriptBlock = { Invoke-Command -VmName $Name -ScriptBlock { 1 } -Credential $Credential -ErrorAction Ignore }
    } elseif ($Status -eq 'Offline') {
        $scriptBlock = { (-not (Invoke-Command -VmName $Name -ScriptBlock { 1 } -Credential $Credential -ErrorAction Ignore)) }
    }
    while (-not (& $scriptBlock)) {
        Start-Sleep -Seconds 10
        Write-Host 'Waiting for SQLSRV to come up...'
    }
}

function Install-PowerLabSqlServer {
    param
    (
        [Parameter(Mandatory)]
        [string]$ComputerName,

        [Parameter(Mandatory)]
        [pscredential]$DomainCredential,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$AnswerFilePath,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$IsoFilePath = 'C:\PowerLab\ISOs\en_sql_server_2016_standard_x64_dvd_8701871.iso'
    )

    try {
        ## Create a PowerShell Direct session to copy files from host server to VM
        Write-Verbose -Message "Creating a new PSSession to [$($ComputerName)]..."
        $session = New-PSSession -VMName $ComputerName -Credential $DomainCredential

        ## Test to see if SQL Server is already installed
        if (Invoke-Command -Session $session -ScriptBlock { Get-Service -Name 'MSSQLSERVER' -ErrorAction Ignore }) {
            Write-Verbose -Message 'SQL Server is already installed'
        } else {

            PrepareSqlServerInstallConfigFile -Path $AnswerFilePath

            $copyParams = @{
                Path        = $AnswerFilePath
                Destination = 'C:\'
                ToSession   = $session
            }
            Copy-Item @copyParams
            Copy-Item -Path $IsoFilePath -Destination 'C:\' -Force -ToSession $session

            $icmParams = @{
                Session      = $session
                ArgumentList = $AnswerFilePath, $IsoFilePath
                ScriptBlock  = {
                    $image = Mount-DiskImage -ImagePath $args[1] -PassThru
                    $installerPath = "$(($image | Get-Volume).DriveLetter):"
                    $null = & "$installerPath\setup.exe" "/CONFIGURATIONFILE=C:\$($args[0])"
                    $image | Dismount-DiskImage
                }
            }
            Invoke-Command @icmParams

            $scriptBlock = { Remove-Item -Path $using:IsoFilePath, $using:AnswerFilePath -ErrorAction Ignore }
            Invoke-Command -ScriptBlock $scriptBlock -Session $session
        }
        $session | Remove-PSSession
    } catch {
        $PSCmdlet.ThrowTerminatingError($_)
    }
}

function PrepareSqlServerInstallConfigFile {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [string]$Path,

        [Parameter()]
        [string]$ServiceAccountName = 'PowerLabUser',

        [Parameter()]
        [string]$ServiceAccountPassword = 'P@$$w0rd12',

        [Parameter()]
        [string]$SysAdminAcountName = 'PowerLabUser'
    )

    $configContents = Get-Content -Path $Path -Raw
    $configContents = $configContents.Replace('SQLSVCACCOUNT=""', ('SQLSVCACCOUNT="{0}"' -f $ServiceAccountName))
    $configContents = $configContents.Replace('SQLSVCPASSWORD=""', ('SQLSVCPASSWORD="{0}"' -f $ServiceAccountPassword))
    $configContents = $configContents.Replace('SQLSYSADMINACCOUNTS=""', ('SQLSYSADMINACCOUNTS="{0}"' -f $SysAdminAcountName))
    Set-Content -Path $Path -Value $configContents
}

function New-IISCertificate {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$WebServerName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$PrivateKeyPassword,

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$CertificateSubject = 'powershellforsysadmins',
		
        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$PublicKeyLocalPath = 'C:\PublicKey.cer',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$PrivateKeyLocalPath = 'C:\PrivateKey.pfx',

        [Parameter()]
        [ValidateNotNullOrEmpty()]
        [string]$CertificateStore = 'LocalMachine\My'
    )

    ## Create the temporary self-signed cert
    $null = New-SelfSignedCertificate -Subject $CertificateSubject

    ## Export the public key
    $tempLocalCert = Get-ChildItem -Path "Cert:\$CertificateStore" | Where-Object { $_.Subject -match $CertificateSubject }
    $null = $tempLocalCert | Export-Certificate -FilePath $PublicKeyLocalPath

    ## Find the thumbprint
    $certPrint = New-Object System.Security.Cryptography.X509Certificates.X509Certificate2
    $certPrint.Import($PublicKeyLocalPath)
    $certThumbprint = $certprint.Thumbprint

    ## Export the private key
    $privKeyPw = ConvertTo-SecureString -String $PrivateKeyPassword -AsPlainText -Force
    $null = $tempLocalCert | Export-PfxCertificate -FilePath $PrivateKeyLocalPath -Password $privKeyPw
	
    ## Create a new PowerShell Direct session
    $session = New-PSSession -VMName $WebServerName -Credential (Import-CliXml -Path C:\PowerLab\DomainCredential.xml)

    ## Import the WebAdministration module into the session
    Invoke-Command -Session $session -ScriptBlock { Import-Module -Name WebAdministration }
	
    ## Check to see if the certificate has already been imported
    if (Invoke-Command -Session $session -ScriptBlock { $using:certThumbprint -in (Get-ChildItem -Path Cert:\LocalMachine\My).Thumbprint }) {
        Write-Warning -Message 'The certificate has already been imported.'		
    } else {
        ## Copy the private key to the web server
        Copy-Item -Path $PrivateKeyLocalPath -Destination 'C:\' -ToSession $session

        ## Import the private key
        Invoke-Command -Session $session -ScriptBlock { $null = Import-PfxCertificate -FilePath 'C:\PrivKey.pfx' -CertStoreLocation "Cert:\$using:CertificateStore" -Password $using:privKeyPw }

        ## Set the SSL binding
        Invoke-Command -Session $session -ScriptBlock { Set-ItemProperty "IIS:\Sites\PowerShellForSysAdmns" -Name bindings -Value @{protocol='https'; bindingInformation='*:443:*' } }

        ## Force the SSL binding to use the private key
        Invoke-Command -Session $session -ScriptBlock {
            $cert = Get-ChildItem -Path "Cert:\$using:CertificateStore" | Where-Object { $_.Subject -match $using:CertificateSubject }
            $null = Get-item -Path "Cert:\$using:CertificateStore\$($cert.Thumbprint)" | New-Item 'IIS:\SSLBindings\0.0.0.0!443' }
    }

    ## Cleanup the remoting session
    $session | Remove-PSSession
}