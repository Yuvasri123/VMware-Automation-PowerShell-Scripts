<#
.Synopsis
 London Market - UK15 and UK16 vBlocks Storage Arrays Automated Storage Fault Status Report using Automation Script

  Mail Declarations containing below fields
    $EmailTo = " " 
    $EmailFrom = " "
    $EmailSubject = " "
    $body = " "
    $SMTPServer = " "


.DESCRIPTION
 The Script will perform checks and collect the fault status and storage pool information from given Storage Arrays for UK15 and UK16 vBlocks.
 It has two reports: csv file and the other is html file.  

.INPUT
1)InputCredFile.csv - CSV file containing below fields updated by user.
    Array,ip,user,pass


.OUTPUT
 The HTML report will be generated in 'Array_StoragePool_HTMLReport.html' file stored in the powershell solution path. 
 The CSV file will be generated in 'Array_StoragePool_CSVReport.csv' file stored in the powershell solution path

 Also output HTML files and CSV files will be send to the configured mailid's


.NOTES
 Version:         1.0.0
 Author :         Yuvasri.C 
 Author email:    <yuvasri.c@dxc.com>
 Creation Date:   06/09/2023

#>


########################################### Function ##########################################


Function Set-DirectoryPath{
    try {
        $scriptPath = $PSScriptRoot
        if (!$scriptPath)
        {
            if ($psISE)
            {
                $scriptPath = Split-Path -Parent -Path $psISE.CurrentFile.FullPath
            }
            else {
                Write-Host -ForegroundColor Red "`tCannot resolve script file's path"                
            }
        }
    Write-Host "`tCurrent directory path: $scriptPath" -ForegroundColor Green
    return $scriptPath
    }
    catch {    
        Write-Host -ForegroundColor Red "`tCaught Exception: $($Error[0].Exception.Message)"
    }
}


########################################## SCRIPT BEGINS #######################################


###------------------------------------- Transcripts ---------------------------------------###


#Start-Transcript -path "D:\Storage\transcript.txt"


###--------------------------------------- Output File -------------------------------------###


$path = Set-DirectoryPath
$OutputCSV_file = $path+"\Array_StoragePool_CSVReport.csv"
$htmlreport = $path+"\Array_StoragePool_HTMLReport.html"


###---------------------------------- Removing Previous files ------------------------------###


if (Test-Path $OutputCSV_file -PathType Leaf) 
{      
    Write-Host "`tPrevious csv report exists" -ForegroundColor Yellow
    write-host "`tDeleting previous csv report" -ForegroundColor Green
    Remove-Item -Path $OutputCSV_file
}


if (Test-Path $htmlreport -PathType Leaf) 
{      
    Write-Host "`tPrevious html report exists" -ForegroundColor Yellow
    write-host "`tDeleting previous html report" -ForegroundColor Green
    Remove-Item -Path $htmlreport 
}


###------------------------------- Mail Variables Declarations -----------------------------###


$EmailTo = " "," "                                             # Enter the mail id to send a mail to requestor [ ex: $EmailTo="abc@dxc.com" ]
$EmailFrom = " "                                               # Enter the from mail id [ ex: $EmailFrom="xyz@dxc.com" ]
$body = "Hi,Team. Please find the Output Report Attachment"    # If want, you can change the body of the mail 
$EmailSubject = "LM Storage arrays Fault Status Report"        # Also the Subject  
$SMTPServer = " "                                              # Enter the SMTPServer 


###---------------------------------  Hash Table Declarations -----------------------------###
 

$myHashTable = @{} 

$myHashTable."Fault Subsystem" = @()
$myHashTable."Pool Name" = @() 
$myHashTable."Pool ID" = @()
$myHashTable."Raid Type" = @()
$myHashTable."Percent Full Threshold" = @()
$myHashTable."Disk Type" = @()
$myHashTable."State" = @()
$myHashTable."Status" = @()
$myHashTable."Current Operation" = @()
$myHashTable."Current Operation State" = @()
$myHashTable."Current Operation Status" = @()
$myHashTable."Current Operation Percent Completed" = @()
$myHashTable."Raw Capacity Blocks" = @()
$myHashTable."Raw Capacity (GBs)" = @()
$myHashTable."User Capacity (Blocks)" = @()
$myHashTable."User Capacity (GBs)" = @()
$myHashTable."Consumed Capacity (Blocks)" = @()
$myHashTable."Consumed Capacity (GBs)" = @()
$myHashTable."Available Capacity (Blocks)" = @()
$myHashTable."Available Capacity (GBs)" = @()
$myHashTable."Percent Full" = @()
$myHashTable."Total Subscribed Capacity (Blocks)" = @()
$myHashTable."Total Subscribed Capacity (GBs)" = @()
$myHashTable."Percent Subscribed" = @()
$myHashTable."Oversubscribed by (Blocks)" = @()
$myHashTable."Oversubscribed by (GBs)" = @()


# Declaration of CSV Array #
$reportArray = @()


###----------------------------------------- Execution ----------------------------------------###


Write-Host -ForegroundColor Green "`tStarting the script execution..."


# Extracting Credential Input File #
$inputDatas = Import-Csv "D:\Storage\InputCredFile.csv"


foreach($inputData in $inputDatas)
{                                                                                                             
       
    $StorageArray = $inputData.Array 
    $myarrayip = $inputData.ip
    $myarrayuser = $inputData.user
    $myarrayuserpasswd = $inputData.pass       
    

    # Running Fault Status and Storage Pool Commands #
    NaviSECCli.exe -removeusersecurity -address $myarrayip
    NaviSECCli.exe -addusersecurity -address $myarrayip -scope 0 -user $myarrayuser -password $myarrayuserpasswd
    $statuses = naviseccli -h $myarrayip faults -list
    $storages = naviseccli.exe -h $myarrayip -User $myarrayuser -Password $myarrayuserpasswd -Scope 0 storagepool -list


    # Array Declaration of Fault Status #
    $stringStatus = @()

    # Processing each Fault status #  -and ($status -notlike "Faulted Subsystem:*" )
    foreach ($status in $statuses )
    {
    if (![string]::IsNullorWhiteSpace($status)) {
    $stringStatus += $status + "`n"
    }
   
    }
    [string]$string = $stringStatus


    # Processing each Storage Pool #
    $count = $storages.Count
    for($i=0;$i -lt $count; $i++)
    {
        if($storages[$i] -like "Disks:*")
        {
            #Write-Host "`nDetected- $($storages[$i]) in line number- $($i)" -ForegroundColor Yellow
            #Write-Host "`nPrinting:`n $($storages[$i])"
        
            while(!($storages[$i] -like "LUNs:*"))
            {
                $i++
            }
        }
        else
        {
 
            if ($storages[$i] -like "Pool Name:*"){
                $storageSplit = $storages[$i].Split(':') 
                $myHashTable."Pool Name" += $storageSplit[1]
            
            }
            if ($storages[$i] -like "Pool ID:*"){
                $storageSplit = $storages[$i].Split(':') 
                $myHashTable."Pool ID" += $storageSplit[1]
            
            }
            if ($storages[$i] -like "Raid Type:*"){
                $storageSplit = $storages[$i].Split(':') 
                $myHashTable."Raid Type" += $storageSplit[1]
            
            }  
            if ($storages[$i] -like "Percent Full Threshold:*"){
                $storageSplit = $storages[$i].Split(':') 
                $myHashTable."Percent Full Threshold" += $storageSplit[1]
            
            }  
            if ($storages[$i] -like "Disk Type:*"){
                $storageSplit = $storages[$i].Split(':') 
                $myHashTable."Disk Type" += $storageSplit[1]
            
            }

            if ($storages[$i] -like "State:*"){
                $storageSplit = $storages[$i].Split(':') 
                $myHashTable."State" += $storageSplit[1]
            
            }
            if ($storages[$i] -like "Status:*"){
                $storageSplit = $storages[$i].Split(':') 
                $myHashTable."Status" += $storageSplit[1]
            
            }
            if ($storages[$i] -like "Current Operation:*"){
                $storageSplit = $storages[$i].Split(':') 
                $myHashTable."Current Operation" += $storageSplit[1]
            
            }  
            if ($storages[$i] -like "Current Operation State:*"){
                $storageSplit = $storages[$i].Split(':') 
                $myHashTable."Current Operation State" += $storageSplit[1]
            
            }  
            if ($storages[$i] -like "Current Operation Status:*"){
                $storageSplit = $storages[$i].Split(':') 
                $myHashTable."Current Operation Status" += $storageSplit[1]
            
            }

            if ($storages[$i] -like "Current Operation Percent Completed:*"){
                $storageSplit = $storages[$i].Split(':') 
                $myHashTable."Current Operation Percent Completed" += $storageSplit[1]
            
            }
            if ($storages[$i] -like "Raw Capacity (Blocks):*"){
                $storageSplit = $storages[$i].Split(':') 
                $myHashTable."Raw Capacity Blocks" += $storageSplit[1]
            
            }
            if ($storages[$i] -like "Raw Capacity (GBs):*"){
                $storageSplit = $storages[$i].Split(':') 
                $myHashTable."Raw Capacity (GBs)" += $storageSplit[1]
            
            }  
            if ($storages[$i] -like "User Capacity (Blocks):*"){
                $storageSplit = $storages[$i].Split(':') 
                $myHashTable."User Capacity (Blocks)" += $storageSplit[1]
            
            }  
            if ($storages[$i] -like "User Capacity (GBs):*"){
                $storageSplit = $storages[$i].Split(':') 
                $myHashTable."User Capacity (GBs)" += $storageSplit[1]
            
            }

            if ($storages[$i] -like "Consumed Capacity (Blocks):*"){
                $storageSplit = $storages[$i].Split(':') 
                $myHashTable."Consumed Capacity (Blocks)" += $storageSplit[1]
            
            }
            if ($storages[$i] -like "Consumed Capacity (GBs):*"){
                $storageSplit = $storages[$i].Split(':') 
                $myHashTable."Consumed Capacity (GBs)" += $storageSplit[1]
            
            }
            if ($storages[$i] -like "Available Capacity (Blocks):*"){
                $storageSplit = $storages[$i].Split(':') 
                $myHashTable."Available Capacity (Blocks)" += $storageSplit[1]
            
            }  
            if ($storages[$i] -like "Available Capacity (GBs):*"){
                $storageSplit = $storages[$i].Split(':') 
                $myHashTable."Available Capacity (GBs)" += $storageSplit[1]
            
            }  
            if ($storages[$i] -like "Percent Full:*"){
                $storageSplit = $storages[$i].Split(':') 
                $myHashTable."Percent Full" += $storageSplit[1]
            
            }

            if ($storages[$i] -like "Total Subscribed Capacity (Blocks):*"){
                $storageSplit = $storages[$i].Split(':') 
                $myHashTable."Total Subscribed Capacity (Blocks)" += $storageSplit[1]
            
            }
            if ($storages[$i] -like "Total Subscribed Capacity (GBs):*"){
                $storageSplit = $storages[$i].Split(':') 
                $myHashTable."Total Subscribed Capacity (GBs)" += $storageSplit[1]
            
            }
            if ($storages[$i] -like "Percent Subscribed:*"){
                $storageSplit = $storages[$i].Split(':') 
                $myHashTable."Percent Subscribed" += $storageSplit[1]
            
            }  
            if ($storages[$i] -like "Oversubscribed by (Blocks):*"){
                $storageSplit = $storages[$i].Split(':') 
                $myHashTable."Oversubscribed by (Blocks)" += $storageSplit[1]
            
            }  
            if ($storages[$i] -like "Oversubscribed by (GBs):*"){
                $storageSplit = $storages[$i].Split(':') 
                $myHashTable."Oversubscribed by (GBs)" += $storageSplit[1]
            
            }
                                                                                                         
        }
    }

                                                                                                           
###----------------------------------- Captures in CSV file -----------------------------------###


    $tableCount = $myHashTable."Pool Name".Count
    for($j=0;$j -lt $tableCount;$j++)
    {
        $report  = ''| Select "Array Name","Fault Subsystem", "Pool Name", "Pool ID", "Raid Type", "Percent Full Threshold", "Percent Full", "Disk Type", "State", "Status", "Current Operation", "Current Operation State", "Current Operation Status", "Current Operation Percent Completed", "Raw Capacity (Blocks)", "Raw Capacity (GBs)", "User Capacity (Blocks)", "User Capacity (GBs)", "Consumed Capacity (Blocks)", "Consumed Capacity (GBs)", "Available Capacity (Blocks)", "Available Capacity (GBs)", "Total Subscribed Capacity (Blocks)", "Total Subscribed Capacity (GBs)", "Percent Subscribed", "Oversubscribed by (Blocks)", "Oversubscribed by (GBs)"  
        $report."Array Name"                           = $StorageArray
        $report."Pool Name"                            = $myHashTable."Pool Name"[$j]
        $report."Pool ID"                              = $myHashTable."Pool ID"[$j]
        $report."Raid Type"                            = $myHashTable."Raid Type"[$j]
        $report."Percent Full Threshold"               = $myHashTable."Percent Full Threshold"[$j]
        $report."Disk Type"                            = $myHashTable."Disk Type"[$j]
        $report."State"                                = $myHashTable."State"[$j]
        $report."Status"                               = $myHashTable."Status"[$j]
        $report."Current Operation"                    = $myHashTable."Current Operation"[$j]
        $report."Current Operation State"              = $myHashTable."Current Operation State"[$j]
        $report."Current Operation Status"             = $myHashTable."Current Operation Status"[$j]
        $report."Current Operation Percent Completed"  = $myHashTable."Current Operation Percent Completed"[$j]
        $report."Raw Capacity (Blocks)"                = $myHashTable."Raw Capacity Blocks"[$j]
        $report."Raw Capacity (GBs)"                   = $myHashTable."Raw Capacity (GBs)"[$j]
        $report."User Capacity (Blocks)"               = $myHashTable."User Capacity (Blocks)"[$j]
        $report."User Capacity (GBs)"                  = $myHashTable."User Capacity (GBs)"[$j]
        $report."Consumed Capacity (Blocks)"           = $myHashTable."Consumed Capacity (Blocks)"[$j]
        $report."Consumed Capacity (GBs)"              = $myHashTable."Consumed Capacity (GBs)"[$j]
        $report."Available Capacity (Blocks)"          = $myHashTable."Available Capacity (Blocks)"[$j]
        $report."Available Capacity (GBs)"             = $myHashTable."Available Capacity (GBs)"[$j]
        $report."Percent Full"                         = $myHashTable."Percent Full"[$j]
        $report."Total Subscribed Capacity (Blocks)"   = $myHashTable."Total Subscribed Capacity (Blocks)"[$j]
        $report."Total Subscribed Capacity (GBs)"      = $myHashTable."Total Subscribed Capacity (GBs)"[$j]
        $report."Percent Subscribed"                   = $myHashTable."Percent Subscribed"[$j]
        $report."Oversubscribed by (Blocks)"           = $myHashTable."Oversubscribed by (Blocks)"[$j]
        $report."Oversubscribed by (GBs)"              = $myHashTable."Oversubscribed by (GBs)"[$j]
        $report."Fault Subsystem"                      = $string
        $reportArray += $report

    }                                                                                                            

}

$reportArray | Export-Csv -path "$OutputCSV_file" -NoTypeInformation -Append


Write-Host -ForegroundColor Green "`tSuccessfully Generated the Output CSV File."


###------------------------------------ Define the Html -------------------------------------###


$a = "<style>"
$a = $a + "BODY{background-color:white;}"
$a = $a + "TABLE{border-width: 1px;border-style: solid;border-color: white;border-collapse: collapse;}"
$a = $a + "TH{border-width: 1px;padding: 2px;border-style: solid;border-color: black;background-color:#5F249F;color: #ffffff;}"
$a = $a + "TD{border-width: 1px;padding: 4px;border-style: solid;border-color: Black;background-color:white}"
$a = $a + "</style>"


####-------- HTML Table for Storage Pool --------####


Write-Host -ForegroundColor Magenta "`tGenerating HTML table for Fault Status and Storage Pool Arrays"


$reportArray | ConvertTo-Html -head $a -Body "<H2 align=Center> Fault Status Storage Pool Report </H2>" >> $htmlreport


###--------------------------------------- Sending Email -----------------------------------###      


Send-MailMessage -to $EmailTo -Subject $EmailSubject -Body $body -BodyAsHTML -SMTPServer $SMTPServer -From $EmailFrom -Attachments $htmlreport, $OutputCSV_file
Write-Host -ForegroundColor Green "`tSuccessfully sent email attaching the Output HTML Report."


Write-Host "`tScript execution completed..!" -ForegroundColor Green


###-------------------------------------- End Transcripts ----------------------------------###


#Stop-Transcript -path "D:\Storage\transcript.txt"


########################################## END OF SCRIPT ######################################
