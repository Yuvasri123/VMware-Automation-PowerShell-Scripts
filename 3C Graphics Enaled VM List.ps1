<#
.Synopsis
 MSV: Request for getting 3D Graphic enabled VM information from vCenter

.DESCRIPTION
 The Script will check the VM information like VM name, powerstate and OS name from multiple vCenters, 
 and verifying whether 3D Graphics is enabled. 


.INPUT
 vcenter Declaration containing below fields

 $vcenters = "1.1.1.1", "2.2.22.21"  [ Enter vCenter Domain Name or IP ]

        
.OUTPUT
 The CSV file will be generated in '3D_Graphics_Output.csv' file stored in the powershell solution path
 The text file 'transcript.txt' will be generated in the same folder from where the script is being executed.


.NOTES
 Version:        1.0.0
 Author :        Yuvasri.C 
 Author email:   <yuvasri.c@dxc.com>
 Creation Date:  21/02/2024

#>



########################################## SCRIPT BEGINS #######################################


###------------------------------------- Transcripts ---------------------------------------###


Start-Transcript -path "$((Get-Location).Path)\transcript.txt"


###------------------------------------- Declarations --------------------------------------###


$path="$((Get-Location).Path)"

$vcenters = "", "" # Enter vCenter Domain Name or IP inside the double quotes


###--------------------------------------- Output File -------------------------------------###


$output_file = "$path\3D_Graphics_Output.csv"


###---------------------------------- Removing Previous files ------------------------------###


if (Test-Path $output_file -PathType Leaf) 
{
    Write-Host "`tPrevious log report exists" 
    write-host "`tDeleting previous log report" -ForegroundColor Green
    Remove-Item -Path $output_file
} 


###--------------------------------------- Execution ---------------------------------------###


Write-Host -ForegroundColor Green "`tStarting the script execution..."


if (Test-Path $CredPath -PathType Leaf) 
{
    $vCCreds = Import-CliXml -Path $CredPath

}
else
{
    $vCCreds = Get-Credential -Message "Please Enter the vCenter Credential"
    $vCCreds | Export-CliXml -Path $CredPath
}


foreach ($vcenter in $vcenters)
{
  Write-host "`tConnecting vCenter server....."
  Connect-VIServer -server $vcenter -Credential $vCCreds 
  write-host "`tSuccessfully connected to the $vcenter vCenter"


### Get a list of virtual machines ###

$vmList = Get-VM


### Display VM information ###

foreach ($vm in $vmList) 
{
    Write-Host "`tCalculating the VM Information - $vm" -ForegroundColor Green
    $vmName = $vm.Name
    $powerState = $vm.PowerState
    $osName = $vm.Guest.OSFullName
    $graphicsEnabled = $vm.ExtensionData.Config.Hardware.Device.Enable3DSupport # | Where-Object {$_.Key -eq "svga.present" -and $_.Value -eq "TRUE"} -ne $null
    
    Write-Host "VM Name: $vmName | Power State: $powerState | OS Name: $osName | 3D Graphics Enabled: $graphicsEnabled"


### Captures in CSV file ###

 $vmInfo = [PSCustomObject]@{
        'VM Name' = $vmName
        'Power State' = $powerState
        'OS Name' = $osName
        '3D Graphics Enabled' = $graphicsEnabled
    }

    $vmInfo | Export-Csv -Path $output_file -Append -NoTypeInformation
}


### Disconnect from the vCenter Server ###
   Disconnect-VIServer $vcenter -Confirm:$false
   Write-Host "`tvCenter $vcenter server disconnected"
} 


Write-Host "`tScript execution completed..!" -ForegroundColor Green


###-------------------------------------- End Transcripts ----------------------------------###


Stop-Transcript 


########################################## END OF SCRIPT ######################################


