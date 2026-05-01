<#


.Synopsis
 This Script will execute to check the NetBackup Client is Installed or not. If its Installed, it UnInstall the NetBackup Client for multiple Servers.

.DESCRIPTION
 This Script will execute and UnInstall the NetBackup Client for multiple Servers.

.INPUT
 Inputserver.csv - CSV file contains server list. 
        
.OUTPUT
 The csv file 'Uninstall_Outputfile.csv' will be generated in the same folder from where the script is being executed.
 
.NOTES
 Version:        1.0.0
 Author :        Yuvasri.C
 Author email:   <yuvasri.c@dxc.com>
 Creation Date:  05/06/2023
 
 #>


########################################## SCRIPT BEGINS #######################################


###------------------------------------- Transcripts ---------------------------------------###


Start-Transcript -path "$((Get-Location).Path)\transcript.txt"


###--------------------------------------- Input File --------------------------------------###


$path="$((Get-Location).Path)"
$Netbackup_servers =  "$path\Inputserver.csv"
$InputserverFile = Import-Csv -path $Netbackup_servers


###--------------------------------------- Declarations ------------------------------------###


$Netbackups = "Pulse Secure"
$FinalStatus = @()


###--------------------------------------- Output File -------------------------------------###


$Output_Report = "$path\Uninstall_Outputfile.csv"
$CredPath = "$path\cred.xml"


###---------------------------------- Removing Previous files ------------------------------###


if (Test-Path $Output_Report -PathType Leaf) 
{
    Write-Host "`tPrevious log report exists !!!" -ForegroundColor yellow
    write-host "`tDeleting previous log report" -ForegroundColor Green
    Remove-Item -Path $Output_Report
    write-host "Successfully deleted the previous log report !!!" -ForegroundColor Magenta
}


###--------------------------------------- Execution ---------------------------------------###


Write-Host -ForegroundColor Green "`tStarting the script execution..."


if (Test-Path $CredPath -PathType Leaf) 
{
        $SerCred = Import-CliXml -Path $CredPath

}
else
{
        $SerCred = Get-Credential -Message "Enter PS-session Credential for computer"
        $SerCred | Export-CliXml -Path $CredPath
}


foreach ($server in $InputserverFile)
{
    $RemoteServer = $server.ServerIP
    Write-Output "Connecting to Netbackup Server $RemoteServer" 

    try
    {   
        $session = New-PSSession -ComputerName  $RemoteServer -Credential $SerCred -Verbose
        $ServOutput = Invoke-Command -Session $session -ScriptBlock {
           param($Netbackups)
           $Check_Install = Get-WmiObject -class Win32_Product | Where-Object {$_.Name -match $Netbackups} | Select -ExpandProperty Name -First 1 
           $Uninstall_Client = Uninstall-Package -Name "$Check_Install"
           Start-Sleep -Seconds 300
            
            if($Uninstall_Client -eq 0)
            {
            $status_success = "NetBackup Client $Check_Install is UnInstalled: Check Success" 
            Write-Output "NetBackup Client $Check_Install is UnInstalled: Check Success" 
            }
            else 
            {
            $status_success = "NetBackup Client $Check_Install is not UnInstalled: Check Failed" 
            Write-Output "NetBackup Client $Check_Install is not UnInstalled: Check Failed"
            }
           
          Write-Output "$env:ComputerName : UnInstalled NetBackup Clients are: $Check_Install"
          }  -ArgumentList $Netbackups


         if ($session) {
             Remove-PSSession -Session $session
         }
         Write-Host "Process completed on Server $RemoteServer" 

    }

    catch [Exception] 
    {
       Write-Output "Unable to connect or complete the process on $($RemoteServer). Error occurred is: $($_ | Out-String)"
       
        if ($session) {
            Remove-PSSession -Session $session
        } 
    }


    ###-------------------- Exporting CSV file -------------------###

    $FinArray = @()
    $FinArray  = "" | Select-Object NetBackupServer, InstallationOutput, UnInstallationStatus
    $FinArray.NetBackupServer = $Remoteserver
    $FinArray.InstallationOutput = $ServOutput
    $FinArray.UnInstallationStatus = $status_success
    $FinalStatus += $FinArray
  
}

$FinalStatus | Export-Csv -Path $Output_Report -NoTypeInformation


Write-Host "Script execution completed..!" -ForegroundColor Green


###-------------------------------------- End Transcripts ----------------------------------###


Stop-Transcript 


########################################## END OF SCRIPT ######################################


