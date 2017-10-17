# Set WDS server name
$WDSServer = $env:COMPUTERNAME

# Create AD PSSession
$ADSession = New-PSSession -ComputerName DCSERVER
Invoke-Command -Session $ADSession { Import-Module ActiveDirectory }
Import-PSSession -Session $ADSession -Module ActiveDirectory -AllowClobber

# Create ConfMgr PSSession
$CMSession = New-PSSession -ComputerName SCCMSERVER
# Load the CM module in the remote PSSession and change the current location to CMSite
Import-Module 'c:\Program Files\microsoft configuration manager\AdminConsole\bin\ConfigurationManager.psd1' -PSSession $CMSession
Get-Module -Name ConfigurationManager
# Change SMS to whatever your site code is
Invoke-Command -Session $CMSession { Set-Location -Path SMS: }

# Set target OUs as variables, stage OU for searching if computer accounts exist in staging OU
