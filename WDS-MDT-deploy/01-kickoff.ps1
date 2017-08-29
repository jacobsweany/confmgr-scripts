# Automated WDS/MDT/SCCM Deployment Script
# Created by Jacob Sweany 8/8/2017
# Stage 1: Kickoff deployment
# This script creates AD and SCCM PSSessions with implicit remoting, uses a Computers.txt file to start initial kickoff actions.

# Define wave
$Wave = Get-Content "\\server\share\CurrentWave.txt"
$LogPath = Get-Content "\\server\share\CurrentWavePath.txt"

# Log file variables
$LogS1 = "$LogPath\Stage1_Prep.txt"
$LogS1Err0 = "$LogPath\Stage1Err_Offline.txt"
$LogS1Err1 = "$LogPath\Stage1Err_AlreadyWin10.txt"
# Source file variables
$SourcePath = "\\server\share\$Wave\sources"
$CurrentWavePath = "\\server\share\CurrentWavePath.txt"
$Computers = "$SourcePath\Computers.txt"
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
