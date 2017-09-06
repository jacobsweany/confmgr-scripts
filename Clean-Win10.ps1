<#
.SYNOPSIS
    This script configures Windows 10 with minimal configuration.
.DESCRIPTION
    This script configures Windows 10 with minimal configuration.
    
    This is a heavily customized version of the script ConfigAsVDI.ps1 found at:
    https://github.com/cluberti/VDI/blob/master/ConfigAsVDI.ps1
    Original script created by Carl Luberti.
    It has been customized to not affect the local system in ways that I do not need.
.PARAMETER NoWarn
    Removes the warning prompts at the beginning and end of the script - do this only when you're sure everything works properly!
.EXAMPLE
    .\ConfigWin10asVDI.ps1 -NoWarn $true
.LOG
    1.0.1 - modified sc command to sc.exe to prevent PS from invoking set-content
    1.0.2 - modified UWP Application section to avoid issues with CopyProfile, updated onedrive removal, updated for TH2
    1.0.3 - modified UWP Application section to disable "Consumer Experience" features, modified scheduled tasks to align with 1511 and further version supportability
    1.0.4 - fixed duplicates / issues in service config
    1.0.5 - updated applist for Win10 1607, moved some things out of the critical area (if you've run this before, please review!)
    1.0.6 - blocked disabling of the Device Association service, disabling service can cause logon delays on domain-joined Win10 1607 systems
    1.0.7 - took out most actions that we do not need, added several HKLM registry strings
#>


# Parse Params:
[CmdletBinding()]
Param(
    [Parameter(
        Position=0,
        Mandatory=$False,
        HelpMessage="True or False, do you want to see the warning prompts"
        )] 
        [bool] $NoWarn = $False
    )


# Throw caution (to the wind?) - show if NoWarn param is not passed, or passed as $false:
If ($NoWarn -ne $True)
{
    Write-Host "THIS SCRIPT MAKES CONSIDERABLE CHANGES TO THE DEFAULT CONFIGURATION OF WINDOWS." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Please review this script THOROUGHLY before applying to your virtual machine, and disable changes below as necessary to suit your current environment." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "This script is provided AS-IS - usage of this source assumes that you are at the very least familiar with PowerShell, and the tools used to create and debug this script." -ForegroundColor Yellow
    Write-Host ""
    Write-Host ""
    Write-Host "In other words, if you break it, you get to keep the pieces." -ForegroundColor Magenta
    Write-Host ""
    Write-Host ""
}


$ProgressPreference = "SilentlyContinue"
$ErrorActionPreference = "SilentlyContinue"


# Validate Windows 10 Enterprise:
$Edition = Get-WindowsEdition -Online
If ($Edition.Edition -ne "Enterprise")
{
    Write-Host "This is not an Enterprise SKU of Windows 10, exiting." -ForegroundColor Red
    Write-Host ""
    Exit
}


# Configure Constants (true removes item):
$Cortana = "True"
$DiagService = "True"
$MSSignInService = "True"
$OneDrive = "True"
$SMB1 = "False"
$SMBPerf = "False"

$Search = "True"
$Touch = "True"
$StartApps = "True"

$StoreApps = "False"

$Install_NetFX3 = "False"
$NetFX3_Source = "D:\Sources\SxS"

$RDPEnable = 1
$RDPFirewallOpen = 1
$NLAEnable = 1


# Set up additional registry drives:
New-PSDrive -Name HKCR -PSProvider Registry -Root HKEY_CLASSES_ROOT | Out-Null
New-PSDrive -Name HKU -PSProvider Registry -Root HKEY_USERS | Out-Null


# Get list of Provisioned Start Screen Apps
$Apps = Get-ProvisionedAppxPackage -Online


# // ============
# // Begin Config
# // ============


# Set VM to High Perf scheme:
Write-Host "Setting machine to High Performance Power Scheme..." -ForegroundColor Green
Write-Host ""
POWERCFG -SetActive '8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'


#Install NetFX3
If ($Install_NetFX3 -eq "True")
{
    Write-Host "Installing .NET 3.5..." -ForegroundColor Green
    dism /online /Enable-Feature /FeatureName:NetFx3 /All /LimitAccess /Source:$NetFX3_Source /NoRestart
    Write-Host ""
    Write-Host ""
}


# Remove (Almost All) Inbox UWP Apps:
If ($StartApps -eq "True")
{
    # Disable "Consumer Features" (aka downloading apps from the internet automatically)
    New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\' -Name 'CloudContent' | Out-Null
    New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableWindowsConsumerFeatures' -PropertyType DWORD -Value '1' | Out-Null
    # Disable the "how to use Windows" contextual popups
    New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent' -Name 'DisableSoftLanding' -PropertyType DWORD -Value '1' | Out-Null 

    Write-Host "Removing (most) built-in UWP Apps..." -ForegroundColor Yellow
    Write-Host ""
    
    ForEach ($App in $Apps)
    {
        # News / Sports / Weather
        If ($App.DisplayName -eq "Microsoft.BingFinance")
        {
            Write-Host "Removing Finance App..." -ForegroundColor Yellow
            Remove-AppxProvisionedPackage -Online -PackageName $App.PackageName | Out-Null
            Remove-AppxPackage -Package $App.PackageName | Out-Null
        }

        If ($App.DisplayName -eq "Microsoft.BingNews")
        {
            Write-Host "Removing News App..." -ForegroundColor Yellow
            Remove-AppxProvisionedPackage -Online -PackageName $App.PackageName | Out-Null
            Remove-AppxPackage -Package $App.PackageName | Out-Null
        }

        If ($App.DisplayName -eq "Microsoft.BingSports")
        {
            Write-Host "Removing Sports App..." -ForegroundColor Yellow
            Remove-AppxProvisionedPackage -Online -PackageName $App.PackageName | Out-Null
            Remove-AppxPackage -Package $App.PackageName | Out-Null
        }

        If ($App.DisplayName -eq "Microsoft.BingWeather")
        {
            Write-Host "Removing Weather App..." -ForegroundColor Yellow
            Remove-AppxProvisionedPackage -Online -PackageName $App.PackageName | Out-Null
            Remove-AppxPackage -Package $App.PackageName | Out-Null
        }

        # Help / "Get" Apps
        If ($App.DisplayName -eq "Microsoft.Getstarted")
        {
            Write-Host "Removing Get Started App..." -ForegroundColor Yellow
            Remove-AppxProvisionedPackage -Online -PackageName $App.PackageName | Out-Null
            Remove-AppxPackage -Package $App.PackageName | Out-Null
        }

        If ($App.DisplayName -eq "Microsoft.SkypeApp")
        {
            Write-Host "Removing Get Skype App..." -ForegroundColor Yellow
            Remove-AppxProvisionedPackage -Online -PackageName $App.PackageName | Out-Null
            Remove-AppxPackage -Package $App.PackageName | Out-Null
        }

        If ($App.DisplayName -eq "Microsoft.MicrosoftOfficeHub")
        {
            Write-Host "Removing Get Office App..." -ForegroundColor Yellow
            Remove-AppxProvisionedPackage -Online -PackageName $App.PackageName | Out-Null
            Remove-AppxPackage -Package $App.PackageName | Out-Null
        }

        # Games / XBox apps
        If ($App.DisplayName -eq "Microsoft.XboxApp")
        {
            Write-Host "Removing XBox App..." -ForegroundColor Yellow
            Remove-AppxProvisionedPackage -Online -PackageName $App.PackageName | Out-Null
            Remove-AppxPackage -Package $App.PackageName | Out-Null
        }

        If ($App.DisplayName -eq "Microsoft.ZuneMusic")
        {
            Write-Host "Removing Groove Music App..." -ForegroundColor Yellow
            Remove-AppxProvisionedPackage -Online -PackageName $App.PackageName | Out-Null
            Remove-AppxPackage -Package $App.PackageName | Out-Null
        }

        If ($App.DisplayName -eq "Microsoft.ZuneVideo")
        {
            Write-Host "Removing Movies & TV App..." -ForegroundColor Yellow
            Remove-AppxProvisionedPackage -Online -PackageName $App.PackageName | Out-Null
            Remove-AppxPackage -Package $App.PackageName | Out-Null
        }

        If ($App.DisplayName -eq "Microsoft.MicrosoftSolitaireCollection")
        {
            Write-Host "Removing Microsoft Solitaire Collection App..." -ForegroundColor Yellow
            Remove-AppxProvisionedPackage -Online -PackageName $App.PackageName | Out-Null
            Remove-AppxPackage -Package $App.PackageName | Out-Null
        }

        If ($App.DisplayName -eq "Microsoft.Microsoft.XboxIdentityProvider")
        {
            Write-Host "Removing Xbox Identity Provider helper App..." -ForegroundColor Yellow
            Remove-AppxProvisionedPackage -Online -PackageName $App.PackageName | Out-Null
            Remove-AppxPackage -Package $App.PackageName | Out-Null
        }

        If ($App.DisplayName -eq "Microsoft.Office.OneNote")
        {
            Write-Host "Removing OneNote App..." -ForegroundColor Yellow
            Remove-AppxProvisionedPackage -Online -PackageName $App.PackageName | Out-Null
            Remove-AppxPackage -Package $App.PackageName | Out-Null
        }

        If ($App.DisplayName -eq "Microsoft.3DBuilder")
        {
            Write-Host "Removing 3D Builder App..." -ForegroundColor Yellow
            Remove-AppxProvisionedPackage -Online -PackageName $App.PackageName | Out-Null
            Remove-AppxPackage -Package $App.PackageName | Out-Null
        }

        If ($App.DisplayName -eq "Microsoft.People")
        {
            Write-Host "Removing People App..." -ForegroundColor Yellow
            Remove-AppxProvisionedPackage -Online -PackageName $App.PackageName | Out-Null
            Remove-AppxPackage -Package $App.PackageName | Out-Null
        }


        If ($App.DisplayName -eq "Microsoft.WindowsAlarms")
        {
            Write-Host "Removing Alarms App..." -ForegroundColor Yellow
            Remove-AppxProvisionedPackage -Online -PackageName $App.PackageName | Out-Null
            Remove-AppxPackage -Package $App.PackageName | Out-Null
        }


        If ($App.DisplayName -eq "Microsoft.WindowsCamera")
        {
            Write-Host "Removing Camera App..." -ForegroundColor Yellow
            Remove-AppxProvisionedPackage -Online -PackageName $App.PackageName | Out-Null
            Remove-AppxPackage -Package $App.PackageName | Out-Null
        }

        If ($App.DisplayName -eq "Microsoft.WindowsMaps")
        {
            Write-Host "Removing Maps App..." -ForegroundColor Yellow
            Remove-AppxProvisionedPackage -Online -PackageName $App.PackageName | Out-Null
            Remove-AppxPackage -Package $App.PackageName | Out-Null
        }

        If ($App.DisplayName -eq "Microsoft.WindowsPhone")
        {
            Write-Host "Removing Phone Companion App..." -ForegroundColor Yellow
            Remove-AppxProvisionedPackage -Online -PackageName $App.PackageName | Out-Null
            Remove-AppxPackage -Package $App.PackageName | Out-Null
        }

        If ($App.DisplayName -eq "Microsoft.CommsPhone")
        {
            Write-Host "Removing Phone App..." -ForegroundColor Yellow
            Remove-AppxProvisionedPackage -Online -PackageName $App.PackageName | Out-Null
            Remove-AppxPackage -Package $App.PackageName | Out-Null
        }

        If ($App.DisplayName -eq "Microsoft.WindowsSoundRecorder")
        {
            Write-Host "Removing Voice Recorder App..." -ForegroundColor Yellow
            Remove-AppxProvisionedPackage -Online -PackageName $App.PackageName | Out-Null
            Remove-AppxPackage -Package $App.PackageName | Out-Null
        }
        
        If ($App.DisplayName -eq "Microsoft.Office.Sway")
        {
            Write-Host "Removing Office Sway App..." -ForegroundColor Yellow
            Remove-AppxProvisionedPackage -Online -PackageName $App.PackageName | Out-Null
            Remove-AppxPackage -Package $App.PackageName | Out-Null
        }
        
        If ($App.DisplayName -eq "Microsoft.Messaging")
        {
            Write-Host "Removing Messaging App..." -ForegroundColor Yellow
            Remove-AppxProvisionedPackage -Online -PackageName $App.PackageName | Out-Null
            Remove-AppxPackage -Package $App.PackageName | Out-Null
        }
        
        If ($App.DisplayName -eq "Microsoft.ConnectivityStore")
        {
            Write-Host "Removing Microsoft Wi-Fi App..." -ForegroundColor Yellow
            Remove-AppxProvisionedPackage -Online -PackageName $App.PackageName | Out-Null
            Remove-AppxPackage -Package $App.PackageName | Out-Null
        }

        If ($App.DisplayName -eq "Microsoft.OneConnect")
        {
            Write-Host "Removing Paid Wi-Fi/Cellular helper App..." -ForegroundColor Yellow
            Remove-AppxProvisionedPackage -Online -PackageName $App.PackageName | Out-Null
            Remove-AppxPackage -Package $App.PackageName | Out-Null
        }

        If ($App.DisplayName -eq "Microsoft.MicrosoftStickyNotes")
        {
            Write-Host "Removing Sticky Notes App..." -ForegroundColor Yellow
            Remove-AppxProvisionedPackage -Online -PackageName $App.PackageName | Out-Null
            Remove-AppxPackage -Package $App.PackageName | Out-Null
        }

        If ($App.DisplayName -eq "Microsoft.WindowsFeedbackHub")
        {
            Write-Host "Removing Feedback Hub App..." -ForegroundColor Yellow
            Remove-AppxProvisionedPackage -Online -PackageName $App.PackageName | Out-Null
            Remove-AppxPackage -Package $App.PackageName | Out-Null
        }
    }

    Start-Sleep -Seconds 5
    Write-Host ""
    Write-Host ""

    # !!!!!!!!!!!!!!! Remove store-based UWP apps - do this with caution, you cannot get the store back without a reinstall of the OS !!!!!!!!!!!!!!!
    If ($StoreApps -eq "True")
    {
        Write-Host "Removing (the rest of the) built-in UWP Apps..." -ForegroundColor Magenta
        Write-Host ""
        ForEach ($App in $Apps)
        {
            If ($App.DisplayName -eq "Microsoft.DesktopAppInstaller")
            {
                Write-Host "Removing Desktop App Sideloading helper App..." -ForegroundColor Magenta
                Remove-AppxProvisionedPackage -Online -PackageName $App.PackageName | Out-Null
                Remove-AppxPackage -Package $App.PackageName | Out-Null
            }

            # Helps apps like Skype UWP access the Camera, for instance
            If ($App.DisplayName -eq "Microsoft.Appconnector")
            {
                Write-Host "Removing AppX/Services Connectivity helper App..." -ForegroundColor Red
                Remove-AppxProvisionedPackage -Online -PackageName $App.PackageName | Out-Null
                Remove-AppxPackage -Package $App.PackageName | Out-Null
            }

            If ($App.DisplayName -eq "Microsoft.StorePurchaseApp")
            {
                Write-Host "Removing Store Purchase helper App..." -ForegroundColor Red
                Remove-AppxProvisionedPackage -Online -PackageName $App.PackageName | Out-Null
                Remove-AppxPackage -Package $App.PackageName | Out-Null
            }

            If ($App.DisplayName -eq "Microsoft.WindowsStore")
            {
                Write-Host "Removing Store App..." -ForegroundColor Red
                Remove-AppxProvisionedPackage -Online -PackageName $App.PackageName | Out-Null
                Remove-AppxPackage -Package $App.PackageName | Out-Null
            }
        }
        Start-Sleep -Seconds 5
        Write-Host ""
        Write-Host ""
    }
}


# Disable Cortana:
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\' -Name 'Windows Search' | Out-Null
If ($Cortana -eq "True")
{
    Write-Host "Disabling Cortana..." -ForegroundColor Yellow
    Write-Host ""
    New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'AllowCortana' -PropertyType DWORD -Value '0' | Out-Null
}


# Remove OneDrive:
If ($OneDrive -eq "True")
{
    # Remove OneDrive (not guaranteed to be permanent - see https://support.office.com/en-US/article/Turn-off-or-uninstall-OneDrive-f32a17ce-3336-40fe-9c38-6efb09f944b0):
    Write-Host "Removing OneDrive..." -ForegroundColor Yellow
    C:\Windows\SysWOW64\OneDriveSetup.exe /uninstall
    Start-Sleep -Seconds 30
    New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\' -Name 'Skydrive' | Out-Null
    New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Skydrive' -Name 'DisableFileSync' -PropertyType DWORD -Value '1' | Out-Null
    New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Skydrive' -Name 'DisableLibrariesDefaultSaveToSkyDrive' -PropertyType DWORD -Value '1' | Out-Null 
    Remove-Item -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{A52BBA46-E9E1-435f-B3D9-28DAA648C0F6}' -Recurse
    Remove-Item -Path 'HKLM:\SOFTWARE\Wow6432Node\Microsoft\Windows\CurrentVersion\Explorer\FolderDescriptions\{A52BBA46-E9E1-435f-B3D9-28DAA648C0F6}' -Recurse
    Set-ItemProperty -Path 'HKCR:\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}' -Name 'System.IsPinnedToNameSpaceTree' -Value '0'
    Set-ItemProperty -Path 'HKCR:\Wow6432Node\CLSID\{018D5C66-4533-4307-9B53-224DE2ED1FE6}' -Name 'System.IsPinnedToNameSpaceTree' -Value '0' 
}

# Configure PeerCaching:
Write-Host "Configuring PeerCaching..." -ForegroundColor Cyan
Write-Host ""
Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\DeliveryOptimization\Config' -Name 'DODownloadMode' -Value '1'


# Disable Services:
Write-Host "Configuring Services..." -ForegroundColor Cyan
Write-Host ""
Write-Host "Disabling AllJoyn Router Service..." -ForegroundColor Cyan
Set-Service AJRouter -StartupType Disabled

Write-Host "Disabling Application Layer Gateway Service..." -ForegroundColor Cyan
Set-Service ALG -StartupType Disabled

Write-Host "Disabling Bluetooth Handsfree Service..." -ForegroundColor Cyan
Set-Service BthHFSrv -StartupType Disabled

Write-Host "Disabling Bluetooth Support Service..." -ForegroundColor Cyan
Set-Service bthserv -StartupType Disabled

Write-Host "Disabling Device Setup Manager Service..." -ForegroundColor Cyan
Set-Service DsmSvc -StartupType Disabled

Write-Host "Disabling Diagnostic Policy Service..." -ForegroundColor Cyan
Set-Service DPS -StartupType Disabled

If ($DiagService -eq "True")
{
    Write-Host "Disabling Diagnostics Tracking Service..." -ForegroundColor Yellow
    Set-Service DiagTrack -StartupType Disabled
}

Write-Host "Disabling Fax Service..." -ForegroundColor Cyan
Set-Service Fax -StartupType Disabled

Write-Host "Disabling Function Discovery Resource Publication Service..." -ForegroundColor Cyan
Set-Service FDResPub -StartupType Disabled

Write-Host "Disabling Geolocation Service..." -ForegroundColor Cyan
Set-Service lfsvc -StartupType Disabled

Write-Host "Disabling Home Group Listener Service..." -ForegroundColor Cyan
Set-Service HomeGroupListener -StartupType Disabled

Write-Host "Disabling Home Group Provider Service..." -ForegroundColor Cyan
Set-Service HomeGroupProvider -StartupType Disabled

If ($MSSignInService -eq "True")
{
    Write-Host "Disabling Microsoft Account Sign-in Assistant Service..." -ForegroundColor Yellow
    Set-Service wlidsvc -StartupType Disabled
}

Write-Host "Disabling Microsoft Software Shadow Copy Provider Service..." -ForegroundColor Cyan
Set-Service swprv -StartupType Disabled

Write-Host "Disabling Microsoft Storage Spaces SMP Service..." -ForegroundColor Cyan
Set-Service smphost -StartupType Disabled

Write-Host "Disabling Offline Files Service..." -ForegroundColor Cyan
Set-Service CscService -StartupType Disabled

Write-Host "Disabling Optimize drives Service..." -ForegroundColor Cyan
Set-Service defragsvc -StartupType Disabled

Write-Host "Disabling Program Compatibility Assistant Service..." -ForegroundColor Cyan
Set-Service PcaSvc -StartupType Disabled

Write-Host "Disabling Quality Windows Audio Video Experience Service..." -ForegroundColor Cyan
Set-Service QWAVE -StartupType Disabled

Write-Host "Disabling Retail Demo Service..." -ForegroundColor Cyan
Set-Service RetailDemo -StartupType Disabled

Write-Host "Disabling Secure Socket Tunneling Protocol Service..." -ForegroundColor Cyan
Set-Service SstpSvc -StartupType Disabled

Write-Host "Disabling Sensor Data Service..." -ForegroundColor Cyan
Set-Service SensorDataService -StartupType Disabled

Write-Host "Disabling Sensor Monitoring Service..." -ForegroundColor Cyan
Set-Service SensrSvc -StartupType Disabled

Write-Host "Disabling Sensor Service..." -ForegroundColor Cyan
Set-Service SensorService -StartupType Disabled

Write-Host "Disabling Spot Verifier Service..." -ForegroundColor Cyan
Set-Service svsvc -StartupType Disabled

Write-Host "Disabling Telephony Service..." -ForegroundColor Cyan
Set-Service TapiSrv -StartupType Disabled

If ($Touch -eq "True")
{
    Write-Host "Disabling Touch Keyboard and Handwriting Panel Service..." -ForegroundColor Yellow
    Set-Service TabletInputService -StartupType Disabled
}

Write-Host "Disabling UPnP Device Host Service..." -ForegroundColor Cyan
Set-Service upnphost -StartupType Disabled

Write-Host "Disabling Volume Shadow Copy Service..." -ForegroundColor Cyan
Set-Service VSS -StartupType Disabled

Write-Host "Disabling Windows Color System Service..." -ForegroundColor Cyan
Set-Service WcsPlugInService -StartupType Disabled

Write-Host "Disabling Windows Connect Now - Config Registrar Service..." -ForegroundColor Cyan
Set-Service wcncsvc -StartupType Disabled

Write-Host "Disabling Windows Error Reporting Service..." -ForegroundColor Cyan
Set-Service WerSvc -StartupType Disabled

Write-Host "Disabling Windows Image Acquisition (WIA) Service..." -ForegroundColor Cyan
Set-Service stisvc -StartupType Disabled

Write-Host "Disabling Windows Media Player Network Sharing Service..." -ForegroundColor Cyan
Set-Service WMPNetworkSvc -StartupType Disabled

Write-Host "Disabling Windows Mobile Hotspot Service..." -ForegroundColor Cyan
Set-Service icssvc -StartupType Disabled

If ($Search -eq "True")
{
    Write-Host "Disabling Windows Search Service..." -ForegroundColor Yellow
    Set-Service WSearch -StartupType Disabled
}

Write-Host "Disabling WLAN AutoConfig Service..." -ForegroundColor Cyan
Set-Service WlanSvc -StartupType Disabled

Write-Host "Disabling WWAN AutoConfig Service..." -ForegroundColor Cyan
Set-Service WwanSvc -StartupType Disabled

Write-Host "Disabling Xbox Live Auth Manager Service..." -ForegroundColor Cyan
Set-Service XblAuthManager -StartupType Disabled

Write-Host "Disabling Xbox Live Game Save Service..." -ForegroundColor Cyan
Set-Service XblGameSave -StartupType Disabled

Write-Host "Disabling Xbox Live Networking Service Service..." -ForegroundColor Cyan
Set-Service XboxNetApiSvc -StartupType Disabled
Write-Host ""


# Reconfigure / Change Services:
Write-Host "Configuring Network List Service to start Automatic..." -ForegroundColor Green
Write-Host ""
Set-Service netprofm -StartupType Automatic
Write-Host ""

# Disable Scheduled Tasks:
Write-Host "Disabling Scheduled Tasks..." -ForegroundColor Cyan
Write-Host ""
Disable-ScheduledTask -TaskName "\Microsoft\Windows\Autochk\Proxy" | Out-Null
Disable-ScheduledTask -TaskName "\Microsoft\Windows\Bluetooth\UninstallDeviceTask" | Out-Null
Disable-ScheduledTask -TaskName "\Microsoft\Windows\Diagnosis\Scheduled" | Out-Null
Disable-ScheduledTask -TaskName "\Microsoft\Windows\Maps\MapsToastTask" | Out-Null
Disable-ScheduledTask -TaskName "\Microsoft\Windows\Maps\MapsUpdateTask" | Out-Null
Disable-ScheduledTask -TaskName "\Microsoft\Windows\MemoryDiagnostic\ProcessMemoryDiagnosticEvents" | Out-Null
Disable-ScheduledTask -TaskName "\Microsoft\Windows\MemoryDiagnostic\RunFullMemoryDiagnostic" | Out-Null
Disable-ScheduledTask -TaskName "\Microsoft\Windows\Mobile Broadband Accounts\MNO Metadata Parser" | Out-Null
Disable-ScheduledTask -TaskName "\Microsoft\Windows\Ras\MobilityManager" | Out-Null
Disable-ScheduledTask -TaskName "\Microsoft\Windows\Registry\RegIdleBackup" | Out-Null
Disable-ScheduledTask -TaskName "\Microsoft\Windows\RetailDemo\CleanupOfflineContent" | Out-Null
Disable-ScheduledTask -TaskName "\Microsoft\Windows\Shell\FamilySafetyMonitor" | Out-Null
Disable-ScheduledTask -TaskName "\Microsoft\Windows\Shell\FamilySafetyRefresh" | Out-Null
Disable-ScheduledTask -TaskName "\Microsoft\Windows\SystemRestore\SR" | Out-Null
Disable-ScheduledTask -TaskName "\Microsoft\Windows\UPnP\UPnPHostConfig" | Out-Null
Disable-ScheduledTask -TaskName "\Microsoft\Windows\WDI\ResolutionHost" | Out-Null
Disable-ScheduledTask -TaskName "\Microsoft\Windows\Windows Media Sharing\UpdateLibrary" | Out-Null
Disable-ScheduledTask -TaskName "\Microsoft\Windows\WOF\WIM-Hash-Management" | Out-Null
Disable-ScheduledTask -TaskName "\Microsoft\Windows\WOF\WIM-Hash-Validation" | Out-Null

# Disable IE First Run Wizard:
Write-Host "Disabling IE First Run Wizard..." -ForegroundColor Green
Write-Host ""
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft' -Name 'Internet Explorer' | Out-Null
New-Item -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Internet Explorer' -Name 'Main' | Out-Null
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Internet Explorer\Main' -Name DisableFirstRunCustomize -PropertyType DWORD -Value '1' | Out-Null


# Disable New Network Dialog:
Write-Host "Disabling New Network Dialog..." -ForegroundColor Green
Write-Host ""
New-Item -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Network' -Name 'NewNetworkWindowOff' | Out-Null


# Change Explorer Default View:
Write-Host "Configuring Windows Explorer..." -ForegroundColor Green
Write-Host ""
New-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'LaunchTo' -PropertyType DWORD -Value '1' | Out-Null
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'LaunchTo' -PropertyType DWORD -Value '1' | Out-Null


# Configure Search Options:
Write-Host "Configuring Search Options..." -ForegroundColor Green
Write-Host ""
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'AllowSearchToUseLocation' -PropertyType DWORD -Value '0' | Out-Null
New-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'ConnectedSearchUseWeb' -PropertyType DWORD -Value '0' | Out-Null
New-ItemProperty -Path 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' -Name 'SearchboxTaskbarMode' -PropertyType DWORD -Value '1' | Out-Null
New-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Search' -Name 'SearchboxTaskbarMode' -PropertyType DWORD -Value '1' | Out-Null


# Enable RDP:
$RDP = Get-WmiObject -Class Win32_TerminalServiceSetting -Namespace root\CIMV2\TerminalServices -Authentication PacketPrivacy
$Result = $RDP.SetAllowTSConnections($RDPEnable,$RDPFirewallOpen)
if ($Result.ReturnValue -eq 0){
   Write-Host "Remote Connection settings changed sucessfully" -ForegroundColor Cyan
} else {
   Write-Host ("Failed to change Remote Connections setting(s), return code "+$Result.ReturnValue) -ForegroundColor Red
   exit
}

Write-Host ""
Write-Host ""
Write-Host ""
Write-Host ""


# Did this break?:
If ($NoWarn -ne $True)
{
    Write-Host "This script has completed." -ForegroundColor Green
    Write-Host ""
    Write-Host "Please review output in your console for any indications of failures, and resolve as necessary." -ForegroundColor Yellow
    Write-Host ""
    Write-Host "Reboot required" -ForegroundColor White
}
