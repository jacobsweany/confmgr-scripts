$session = New-PSSession -ComputerName LON-DC1
Invoke-Command -Session $session -ScriptBlock { Import-Module activedirectory }
Import-PSSession $session
$LocalComputer = $env:COMPUTERNAME
$TargetOU = 'ou=Servers,dc=adatum,dc=com'
$events = Get-WinEvent -ComputerName $LocalComputer -FilterHashtable @{ Logname = "Application"; ID = 41015 }
foreach ($event in $events) {
  $eventXML = [xml]$event.ToXML()
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
