#Termination Script v 1.2
#.........................ChangeLog..........................................................
#redacted
#.............................................................................................
#Random Password Function
$Chars1 = [Char[]]"BDFGHKLMNPRSTVWZ"
$Chars21 = [Char[]]"aeiou"
$Chars22 = [Char[]]"bdfghkmnprstvwz"
$Chars3 = [Char[]]"2345679"
$P1 = ($Chars1 | Get-Random -Count 1) -join ""
$P2 = ($Chars21 | Get-Random -Count 1) -join ""
$P3 = ($Chars22 | Get-Random -Count 1) -join ""
$P4 = ($Chars21 | Get-Random -Count 1) -join ""
$P5 = ($Chars22 | Get-Random -Count 1) -join ""
$P6 = ($Chars21 | Get-Random -Count 1) -join ""
$P7 = ($Chars3 | Get-Random -Count 2) -join ""
$P8 = ($Chars3 | Get-Random -Count 2) -join ""
$P9 = ($Chars3 | Get-Random -Count 2) -join ""
$P10 = ($Chars3 | Get-Random -Count 2) -join ""
$P11 = ($Chars3 | Get-Random -Count 2) -join ""
$Password = $P1 + $P2 + $P3 + $P4 + $P5 + $P6 + $P7 + $P8 + $P9 + $P10 + $P11
#generate today's date
$date = Get-Date -Format "MM/dd/yyyy"
$transcriptDate = Get-Date -Format "hmm tt"
$currentYear = Get-Date -Format "yyyy"
$currentMonth = Get-Date -Format "MM"
$currentDayOfMonth = Get-Date -Format "dd"


Write-Host "Welcome to Stout's Termination Script. Please wait a moment!"
Start-Transcript "\\redacted\$transcriptDate.txt" -NoClobber
Import-Module ActiveDirectory
Import-Module -Name AzureAD
Write-Host "Please Wait!"
Start-Sleep -Seconds 5
Try {
Connect-AzureAD 
}
catch {
Write-Host "AzureAD not connected! Please enter your credentials in the pop up box!"
pause
break
}
#Analyst doing term
$supportAnalyst = Read-Host 'Welcome! Please enter your initials (Please use first,middle,last initial!)'
if($?)
{
    Write-Output "Log File Name Updated Successfully!"
}
else
{
    Write-Output "Please Check the Path and make sure the log file created successfully!"
}
Write-Output "The following will be applied as the random password for this account: $Password"
#Analyst specified user to term
$terminatedUser = Read-Host 'Enter the SamAccountName of the user you are terminating (like redacted)'

#used to block M365 sign in
$terminatedUserM365Name = "$terminatedUser"+"@stout.com"

$confirmation = Read-Host "Did you enter the SamAccountName of the user you are terminating correctly? [y/n]"
while($confirmation -ne "y")
{
    if ($confirmation -eq 'n') {exit}
    $confirmation = Read-Host "Ready? [y/n]"
}
Try {
get-aduser -Identity $terminatedUser
}
catch{
Write-Host "User does not Exist! Please exit the script and make sure the SamAccount Name is spelled correctly."
pause
break
}
pause
Write-Host "Disabling $terminatedUser in M365"
#disables user in M365
Set-AzureADUser -ObjectID "$terminatedUserM365Name" -AccountEnabled $false
if($?)
{
    Write-Output "$terminatedUser has been disabled in M365"
}
else
{
    Write-Output "$terminatedUser has NOT been disabled in M365! Please login to the portal and block-sign in!"
}

#variable for move function
$terminatedUserDistinguishedName = get-aduser $terminatedUser | select distinguishedname

Write-Output "You entered $terminatedUser. Beginning Termination Process."
pause
Write-Output "Disabling Account"
Disable-ADAccount -Identity $terminatedUser
if($?)
{
    Write-Output "$terminatedUser has been disabled successfully!"
}
else
{
    Write-Output "This user was not disabled! Did you spell the samaccount name correctly?"
}
pause
Write-Output "Changing Password to something random!"
Set-AdAccountPassword -Identity $terminatedUser -Reset -NewPassword (ConvertTo-SecureString -AsPlainText $Password -Force)
if($?)
{
    Write-Output "$terminatedUser password has been changed to a random string."
}
else
{
    Write-Output "The password was not changed. Are you connected to VPN? Please change manually within AD."
}
pause
Write-Output "Moving User Object to Srr\Other\Closeout in Progress."
Move-ADObject -Identity $terminatedUserDistinguishedName.distinguishedname -TargetPath "OU=Closeout in Progress,OU=Other,OU=SRR,DC=gosrr,DC=com"
if($?)
{
    Write-Output "$terminatedUser has been moved to srr\other\closeout in progress"
}
else
{
    Write-Output "$terminatedUser has NOT been moved! Please move the user object in AD."
}
pause
Write-Output "Changing Description"
Set-AdUser -Identity $TerminatedUser -Description "~TERMINATED {$date}, {$supportAnalyst}"
if($?)
{
    Write-Output "$terminatedUser description has been updated with the following: ~TERMINATED {$date}, {$supportAnalyst}."
}
else
{
    Write-Output "Description not updated. Please check connection to VPN, and that the SamAccountName is correct."
}
pause
Write-Output "Clearing Manager Field"
Set-AdUser -Identity $terminatedUser -Manager $null
if($?)
{
    Write-Output "$terminatedUser manager has been cleared."
}
else
{
    Write-Output "The manager field has not been cleared. Please clear manually in AD!"
}
pause
Write-Output "Clearing IP Phone Field"
Set-Aduser -Identity $terminatedUser -Clear ipPhone
if($?)
{
    Write-Output "IP Phone Field has been cleared."
}
else
{
    Write-Output "IP Phone Field has NOT been cleared. Please clear manually in AD."
}
pause
Write-Output "Listing All Current Groups"
Get-ADPrincipalGroupMembership $terminatedUser | select name
Write-Output "Adding to Terminated Users Group"
Add-ADGroupMember -Identity Terminated -Members $terminatedUser
if($?)
{
    Write-Output "$terminatedUser has been added to Terminated Group in AD."
}
else
{
    Write-Output "$terminatedUser has NOT been added to Terminated Group in AD! Please add manually in AD."
}
pause
Write-Output "Setting Terminated Group as Primary Group in AD"
$primaryGroup = get-adgroup "Terminated" -properties @("primaryGroupToken")
get-aduser "$terminatedUser" | set-aduser -replace @{primaryGroupID=$primaryGroup.primaryGroupToken}
if($?)
{
    Write-Output "Terminated is now the primary user group."
}
else
{
    Write-Output "Terminated is NOT the primary user group. Please make Terminated the primary user group in AD."
}
pause
Write-Output "Deleting user from all other groups in AD"
$groups = Get-ADPrincipalGroupMembership $terminatedUser
foreach ($group in $groups) {
    if ($group.name -ne "Terminated") {
        Remove-ADGroupMember -identity $group.name -member $terminatedUser -Confirm:$false
    }
}
if($?)
{
        Write-Output "All Groups Deleted"
}
else
{
    Write-Output "Groups have not been deleted. Please delete manually"
}
pause
Write-Output "Changing msexch Attribute"
Set-Aduser -Identity $terminatedUser -Replace @{msExchHideFromAddressLists=$True}
if($?)
{
    Write-Output "$terminatedUser has been hidden from the exchange list"
}
else
{
    Write-Output "$terminatedUser has NOT been hidden from the exchange list! Please go into Active Directory Administrative Center and switch the value to TRUE."
}
pause
#Write-Output "Searching for Computer Object"
#$computerObject = Get-ADComputer -Filter 'Name -like "$terminateduser*"' | select distinguishedname
#if $computerObject 

#variables for future reference
#variable for manager
#$terminatedUserManager = Get-aduser $terminatedUser -properties Manager | Select-Object manager

#$terminatedUserGroups = get-aduser -identity -$terminatedUser -properties MemberOf

#Email Section
#Email to Broadgun to Delete PDF Machine License
#Write-Output "Sending an E-mail message to redacted to disable $terminatuedUser Account""
#$broadgunSupportEmailAddress = "jgorman@stout.com"
#Send-MailMessage -To "$broadGunSupportEmailAddress" -From "jgorman@stout.com" -Subject "$Terminateduser - Please delete from Stout's Broadgun License Pool" -Body "Hello, please delete $terminatedUser from Stout's PDF Machine license pool. Thanks!" -SmtpServer redacted

#Email to Peter/Steve to clear app passwords
$appPasswordClearRecipients = "xx@xx.com", "xx@xx.com"
$aCMClear = ""
$sharefileClear = "redacted"
Write-Output "Sending an e-mail message to clear app passwords to $appPasswordClearRecipients!"
Send-MailMessage -To $appPasswordClearRecipients -From "xx@xx.com" -Subject "$Terminateduser - Please Clear App Passwords" -Body "Hello, Please clear $terminatedUser's App Passwords. Thanks! -$supportAnalyst" -SmtpServer nc1vmexchangep2.gosrr.com
if($?)
{
    Write-Output "Email Sent Successfully!"
}
else
{
    Write-Output "Email NOT Sent Successfully! Please e-mail $apppasswordClearRecipients to clear app passwords!"
}
pause
Send-MailMessage -To $aCMClear -From "xx@xx.com" -Subject "$Terminateduser - Please Remove from ACM" -Body "Hello, Please clear $terminatedUser from ACM. Thanks! -$supportAnalyst" -SmtpServer redacted
if($?)
{
    Write-Output "Email Sent Successfully to $acCmClear!"
}
else
{
    Write-Output "Email NOT Sent Successfully! Please e-mail $acCMClear to delete from ACM!"
}
pause
Send-MailMessage -To $sharefileClear -From "hd@stout.com" -Subject "$Terminateduser - Please Remove from Sharefile" -Body "Hello, Please clear $terminatedUser from Sharefile. Thanks! -$supportAnalyst" -SmtpServer redacted
if($?)
{
    Write-Output "Email Sent Successfully to $sharefileClear!"
}
else {
    Write-Output "Email NOT sent Successfully! Please e-mail $sharefileClear to delete from ACM!"
}
Write-Host "PLEASE WAIT!"
Stop-Transcript
Write-Host "Creating Log File!"
Rename-Item -Path "\$currentYear\$currentMonth\$currentDayOfMonth\$transcriptDate.txt" -NewName "$terminatedUser.txt"
Write-Host "Finished. Please move the computer object, remove user from all other groups, and finish the rest of the external checklist items in Sharepoint."
pause
