# NOTES
# Copy this script and the 64 bit version of ServiceUI (found in C:\Program Files\Microsoft Deployment Toolkit\Templates\Distribution\Tools\x64) to share to be used for package.
# Run this command within the package in the task sequence right after formatting the hard drive:
# ServiceUI.exe -process:TSProgressUI.exe %SYSTEMROOT%\System32\WindowsPowerShell\v1.0\powershell.exe -NoProfile -ExecutionPolicy Bypass -File [SCRIPTNAME].ps1
# This script has to be run in 32 bit mode due to the COM Object Microsoft.SMS.TSEnvironment. 
# If it works, during the task sequence stage you will see a PowerShell window pop up for 3 seconds showing the formatted computer name.

# Found original script from https://github.com/happysccm/Files/tree/master/Check%20for%20Asset%20Tag%20-%20OSD%20AssetTag%20Check%20-%20Most%20code%20by%20Nickolaj%20and%20Dave%20Green
# Main page was here https://happysccm.com/set-the-computer-name-using-the-bios-asset-tag/

$model = Get-WmiObject -Class Win32_ComputerSystem | ForEach-Object {$_.Model}
    If ($model -like "*vmware*")  {
    Write-Host "vm"
    exit 0
    }

    ElseIf ($model -like "*Parallels*")  {
    Write-Host "Parallels"
    exit 0
    } 

    ElseIf ($model -like "*Virtual*")  {
    Write-Host "Virtual Machine"
    exit 0
    } 


$tsenv = New-Object -COMObject Microsoft.SMS.TSEnvironment
$machineName =  $tsenv.Value("_SMSTSMachineName")

#If ([string]::IsNullOrWhitespace($machineName) -or ($machineName -like 'MININT*')) {}


$bios = Get-WmiObject -Class Win32_SystemEnclosure | Select-Object -ExpandProperty SMBIOSAssetTag

If ([string]::IsNullOrWhitespace($bios)) {
    # No asset tag info found
    exit 0
    }

$trim = $bios.Trim("TRIM00")
$biosComputerName = "SITE-$trim"
$TSEnv.Value("OSDComputerName") = $biosComputerName
Write-Host "Changed OSDComputerName to $biosComputerName. Resuming in 3 seconds."
Start-Sleep -Seconds 3
