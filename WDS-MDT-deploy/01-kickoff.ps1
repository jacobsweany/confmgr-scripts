# Automated WDS/MDT/SCCM Deployment Script
# Created by Jacob Sweany 8/8/2017
# Stage 1: Kickoff deployment
# This script creates AD and SCCM PSSessions with implicit remoting, uses a Computers.txt file to start initial kickoff actions.
# Blocked inheritance StageOU is used because group policy prohibits certain MDT task sequence processes. Computer is moved to prod OU after task sequence.

# Define wave
$Wave = Get-Content "\\server\share\CurrentWave.txt"
$LogPath = Get-Content "\\server\share\CurrentWavePath.txt"

# Log file variables
$LogS1 = "$LogPath\Stage1_Prep.txt"
$LogS1Err0 = "$LogPath\Stage1Err_Offline.txt"
$LogS1Err1 = "$LogPath\Stage1Err_AlreadyWin10.txt"
$LogS1Err2 = "$LogPath\Stage1Err_UserLoggedOn.txt"

# Source file variables
$SourcePath = "\\server\share\$Wave\sources"
$CurrentWavePath = "\\server\share\CurrentWavePath.txt"
$Computers = "$SourcePath\Computers.txt"
$ComputersTxt = $Computers
$LogV = "$LogPath\Verbose.txt"

$Source = "(Source: KickoffDeployment)"

# Update current wave path file (used for stage 2)
Write-Output $LogPath | Out-File $CurrentWavePath -Force

Write-Output "$(Get-Date -Format g) $Source INFO: Starting kickoff deployment script now" | Out-File $LogV -Append

# Create AD PSSession
$ADSession = New-PSSession -ComputerName ADSERVER
Invoke-Command -Session $ADSession { Import-Module activedirectory }
Import-PSSession -Session -Module activedirectory -AllowClobber

# Create ConfMgr PSSession
$CMSession = New-PSSession -ComputerName CMSERVER
# Load the CM module in the remote PSSession and change the current location to CMSite
Import-Module 'c:\Program Files\Microsoft Configuration Manager\AdminConsole\bin\ConfigurationManager.psd1' -PSSession $CMSession
Get-Module -Name ConfigurationManager
Invoke-Command -Session $CMSession { Set-Location -Path SITECODE: }

# Preinstall task variables
$StageOU = "OU=OUToWin10Staging,DC=domain,DC=com"
$SecLogDestinationDir = "\\server\share\"
$SecLogDate = Get-Date -Format ddMMyyyy

# If Computers log contains "False" or "True" and nothing else (no computer names were found), then clear log
if ((Get-Content $Computers) -eq "False" -or (Get-Content $Computers) -eq "True") {
    Clear-Content $Computers
    Write-Output "$(Get-Date -Format g) $Source INFO: Computers source file is empty" | Out-File $LogV -Append
}

# Switch $Computers variable to the content of the text file
$Computers = Get-Content $Computers

# Perform preinstall tasks for all machines
foreach ($Computer in $Computers) {
    $TargetDir = "\\$SecLogDestinationDir\$Computer\"
    $Test = Test-Connection -ComputerName $Computer -Count 1 -Quiet
    $ADCheck = Get-ADComputer -Identity $Computer -Properties Name,operatingSystem | Select Name,operatingSystem
    # If Computers log contains "False" or "True" and nothing else (no computer names were found), then clear log
    if ((Get-Content $Computers) -eq "False" -or (Get-Content $Computers) -eq "True") {
        Clear-Content $Computers
        Write-Output "$(Get-Date -Format g) $Source INFO: Computers source file is empty" | Out-File $LogV -Append
    }
    # Check that machine is online (pingable), if unable to ping don't do anything and log error
    if (!$Test) {
        Write-Output "$Computer" | Out-File $LogS1Err0 -Append
        Write-Output "$(Get-Date -Format g) $Source WARNING: $Computer is not online. Will retry script in 10 minutes" | Out-File $LogV -Append
        Start-ScheduledTask -TaskName "KickoffDeployment-Retry"
    }
    else {
        # Check if machines is Windows 7, if not, skip block
        if ($ADCheck.OperatingSystem -eq "Windows 7 Enterprise") {
            # Do not proceed if interactive user is logged on, detected by presence of explorer.exe in processes
            $UserLoggedOn = (Get-WmiObject -ComputerName $Computer -Query "Select * FROM WIN32_Process WHERE Name='explorer.exe'" )
            if ($UserLoggedOn -ne $null) {
                Write-Output "$Computer" | Out-File $LogS1Err2 -Append
            } else {
                $EVTX = $SecLogDestinationDir + $Computer + "_Security_" + $SecLogDate + ".evtx"
                # Move computer entry from Computer log to Stage1_Preparation
                (Get-Content $ComputersTxt) -notmatch "$Computer" | Out-File $ComputersTxt
                Write-Output $Computer | Out-File $LogS1 -Append
                Write-Output "$(Get-Date -Format g) $Source INFO: $Computer moved from Computers.txt to Stage1_Preparation.txt" | Out-File $LogV -Append
                # Copy security logs to share
                Copy-Item \\$Computer\c$\Windows\System32\winevt\Logs\Security.evtx $EVTX
                # Move to stage OU
                Move-ADObject -Identity (Get-ADComputer $Computer).objectguid -TargetPath $StageOU
                # Remove computer account from SCCM
                Remove-CMDevice -DeviceName $(Get-CMDevice -Name $Computer).Name -Force
                Write-Output "$Computer" | Out-File $LogS1
                # Shut down computer - used for more easily identifying machines that are being imaged
                Stop-Computer -ComputerName $Computer -Force
            }
        }
        else {
            # Computer is already running Windows 10
        }
    }
}

# If Computers log contains "False" or "True" and nothing else (no computer names were found), then clear log
if ((Get-Content $Computers) -eq "False" -or (Get-Content $Computers) -eq "True") {
    Clear-Content $Computers
    Write-Output "$(Get-Date -Format g) $Source INFO: Computers source file is empty" | Out-File $LogV -Append
}

# Remove ConfMgr session
Remove-PSSession -Session $CMSession

# Remove AD session
Remove-PSSession -Session $ADSession
