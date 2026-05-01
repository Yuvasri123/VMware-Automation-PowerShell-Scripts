<#


.Synopsis
 MSVx-FRK- User Account Creation in AD

.DESCRIPTION
 The script will create a new Active Directory (AD) user account based on the specified template account.
 It will incorporate the details of the template user and add the new user to the specified member-of groups under the designated domain. 
 This task is completed for the two accounts, MSVx and FRK

.INPUT
 userInput.csv - CSV file contains the list of user information. 
        
.OUTPUT
 The text file 'transcript.txt' will be generated in the same folder from where the script is being executed.
 
.NOTES
 Version:        1.0.0
 Author :        Yuvasri.C
 Author email:   <yuvasri.c@dxc.com>
 Creation Date:  12/03/2024
 
 #>


###----------------------------- Import the Active Directory module ------------------------ ###


Import-Module ActiveDirectory


########################################## SCRIPT BEGINS #######################################


###-------------------------------------- Transcripts ---------------------------------------###


Start-Transcript -path "$((Get-Location).Path)\transcript.txt"


###--------------------------------------- Input File --------------------------------------###


$path="$((Get-Location).Path)"

$inputCSV = "$path\userInput.csv"

$userDetails = Import-Csv $inputCSV


###---------------------------------- Removing Previous files ------------------------------###


if (Test-Path $Output_Report -PathType Leaf) 
{
    Write-Host "`tPrevious log file exists !!!" -ForegroundColor yellow
    write-host "`tDeleting previous log file" -ForegroundColor Green
    Remove-Item -Path $Output_Report
    write-host "`tSuccessfully deleted the previous log file !!!" -ForegroundColor Magenta
}


###--------------------------------------- Execution ---------------------------------------###


Write-Host -ForegroundColor Green "`tStarting the script execution..."


### Create a new AD user based on the template user ###

foreach ($user in $userDetails) 
{
    try 
    {
    
        ### Specify template user details ###

        $template_account = Get-ADUser -Identity $user.TemplateAccount -Properties State,Department,Country,City
        $template_account.UserPrincipalName = $null

        $newUser = New-ADUser -SamAccountName $user.LogonName -UserPrincipalName $($user.LogonName + "@" + $user.Domain) -GivenName $user.Firstname -Surname $user.LastName -Name $($user.Firstname+ " " + $user.LastName) `
                              -EmailAddress $user.Email -DisplayName $user.Displayname -Description $user.Description `
                              -Enabled $true -Path $user.OU -AccountPassword ($user.Password | ConvertTo-SecureString -AsPlainText -Force) -Instance $template_account -PasswordNeverExpires $true
                               

        write-host -ForegroundColor Green "`tNew user is added Successfully: $newUser"

        ### Adding the User to the member of groups ###

        $groups = Get-ADUser -Identity $template_account -Properties memberof | Select-Object -ExpandProperty memberof |  Add-ADGroupMember -Members (Get-ADUser -Identity $user.LogonName)

        Write-Host -ForegroundColor Green "`tMembers are added to the groups: $groups" 

        Write-Host -ForegroundColor Green "`tUser accounts created based on the input CSV file and added to groups successfully."

    } 
    catch
    {
        write-host -ForegroundColor Red "`tNew user is failed to add: $newUser - $_"
        Write-Host -ForegroundColor Magenta "`tError adding user to groups: $_"
    }
}


Write-Host "`tScript execution completed..!" -ForegroundColor Green


###-------------------------------------- End Transcripts ----------------------------------###


Stop-Transcript 


########################################## END OF SCRIPT ######################################

