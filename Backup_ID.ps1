<#

.Synopsis
 This Script will execute the cmd to check the backup ID.

.DESCRIPTION
 This Script will execute the cmd to check the backup ID from the given text input list.

.INPUT
 InputClientList.txt - TXT file containing below fields   
        
.OUTPUT
 The text file 'Output_BackupI_$date.txt' will be generated in the same folder from where the script is being executed.
 
.NOTES
 Version:        1.0.0
 Author :        Yuvasri.C
 Author email:   <yuvasri.c@dxc.com>
 Creation Date:  19/04/2023
 
 #>

######################################## File Declarations #####################################

$path = "$((Get-Location).Path)"

################### Input File ###################

$client_inputfile = "$path\InputClientList.txt"
$InputFile_Import   = Get-Content -Path $client_inputfile

##################################################

################### Output File ##################

$output_file = "$path\Output_BackupID_$date.txt"
$tranScriptPath = "$path\Transcript.txt"

##################################################

Start-Transcript -Path $tranScriptPath

######### Prompting for start & end Date #########

$date = "{0,10:dd.MM.yyyy}" -f $(Get-Date)
$startDate = Get-Date (Read-Host -Prompt 'Enter the start date')
$endDate = Get-Date (Read-Host -Prompt 'Enter the end date')

##################################### End of Declarations ######################################

################################### Removing Previous file #####################################

if (Test-Path $output_file -PathType Leaf) 
{      
    Write-Host "`tPrevious error log report exists" 
    write-host "`tDeleting previous log report" -ForegroundColor Green
    Remove-Item -Path $output_file
} 

################################################################################################

######################################### Execution ############################################

Write-Host -ForegroundColor Green "Execution started"

foreach ($backup in $InputFile_Import)
{
   $execution = ./bpimagelist -client $backup -d $startDate -e $endDate -L | findstr "Backup ID:"
   $Backup_output = $execution | Select-String "Backup ID:"
   $Backup_output
   $Backup_output | out-file -FilePath "$path\Output_BackupID_$date.txt" -Append 
}

Write-Host -ForegroundColor Green "Execution Finished"

Stop-Transcript

########################################## End of Script #######################################