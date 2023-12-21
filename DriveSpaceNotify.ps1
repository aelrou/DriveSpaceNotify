# Set-ExecutionPolicy RemoteSigned
# Unblock-File -Path "C:\Users\Public\PowerShell\DriveSpaceNotify\DriveSpaceNotify.ps1"
# "C:\Windows\System32\WindowsPowerShell\v1.0\powershell.exe" -File "C:\Users\Public\PowerShell\DriveSpaceNotify\DriveSpaceNotify.ps1"

$StartTime = Get-Date
$DriveInformationBatch = (Get-Volume | Select-Object -Property DriveLetter, FriendlyName, FileSystemType, DriveType, HealthStatus, OperationalStatus, SizeRemaining, Size | Where-Object {$_.DriveType -eq "Fixed"} | Where-Object {$_.DriveLetter -ne $null})
$FirstLine = $true
$Warning = $false
[string]$WarningDetails = $null

foreach ($DriveInformation in $DriveInformationBatch) {
    [String]$DriveLetter = $null
    [String]$FriendlyName = $null
    [long]$SizeRemaining = $null
    [long]$Size = $null

    [String]$DriveLetter = ($DriveInformation | Select-Object -ExpandProperty DriveLetter)
    [String]$FriendlyName = ($DriveInformation | Select-Object -ExpandProperty FriendlyName)
    [long]$SizeRemaining = ($DriveInformation | Select-Object -ExpandProperty SizeRemaining)
    [long]$Size = ($DriveInformation | Select-Object -ExpandProperty Size)
    
    if ($FirstLine -eq $true) {
        $WarningDetails = $WarningDetails + "Storage space on $($StartTime.ToString("yyyy-MM-dd"))`r`n"
        $WarningDetails = $WarningDetails + "----------------`r`n"
        $FirstLine = $false
    }
	
    if (!($null -eq $FriendlyName)){
        if (!($FriendlyName -eq "")){
            $WarningDetails = $WarningDetails + "Drive $($DriveLetter): ($($FriendlyName))`r`n"
        }
        else {
            $WarningDetails = $WarningDetails + "Drive $($DriveLetter):`r`n"
        }
    }
    else {
        $WarningDetails = $WarningDetails + "Drive $($DriveLetter):`r`n"
    }

    if ($SizeRemaining/$Size -lt 0.1) {
        $Warning = $true
        $WarningDetails = $WarningDetails + "$([System.Math]::Round(((1-($SizeRemaining/$Size))*100),0))% full        >>>>>>>> WARNING <<<<<<<<`r`n"
    } else {
        $WarningDetails = $WarningDetails + "$([System.Math]::Round(((1-($SizeRemaining/$Size))*100),0))% full`r`n"
    }
    
    $WarningDetails = $WarningDetails + "$([System.Math]::Round(($SizeRemaining/1024/1024/1024),0)) GB free space`r`n"
    $WarningDetails = $WarningDetails + "$([System.Math]::Round(($Size/1024/1024/1024),0)) GB capacity`r`n"
    $WarningDetails = $WarningDetails + "----------------`r`n"
}

if ($Warning -or $StartTime.ToString("ddd") -eq "Mon") {
    $SMTPSecureString = ConvertTo-SecureString -String "password" -AsPlainText -Force
    $SMTPCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "username", $SMTPSecureString
    [string]$SMTPServer = "smtp.server.com"
    [int]$SMTPPort = 587
    [string]$Sender = "sender@address.com"
    [string]$Recipient = "recipient@address.com"
    [string]$MailSubject = "Storage status"
    Send-MailMessage -From $Sender -To $Recipient -Subject $MailSubject -Body $WarningDetails -SmtpServer $SMTPServer -Port $SMTPPort -Credential $SMTPCredential -UseSsl
}

exit 0
