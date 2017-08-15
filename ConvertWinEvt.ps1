
# Import AD session
$session = New-PSSession -ComputerName LON-DC1
Invoke-Command -Session $session -ScriptBlock { Import-Module activedirectory }
Import-PSSession $session

$LocalComputer = $env:COMPUTERNAME

$TargetOU = 'ou=Servers,dc=adatum,dc=com'
$events = Get-WinEvent -ComputerName $LocalComputer -FilterHashtable @{ Logname = "Application"; ID = 41015 }

# Loop through each event within specified parameters
foreach ($event in $events) {
  # Convert to XML
  $eventXML = [xml]$event.ToXML()
    # Convert to data readable by PowerShell
    $eventData = $eventXML.Event.EventData.Data
    $eventData | % {
        if ($_ -match "computer (.+).") {
            $computerName = $Matches[1]
            Write-Host "Found event for computer name $computerName."
            Move-ADObject -Identity (Get-ADComputer $computerName).objectguid -TargetPath $TargetOU
            }
        }
}

Remove-PSSession $session
