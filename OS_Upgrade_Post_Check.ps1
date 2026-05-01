## Enter the Backup registry keys ##
$Keys = "HKEY_CURRENT_CONFIG", "HKEY_LOCAL_MACHINE" , "HKEY_CURRENT_USER", "HKEY_CLASSES_ROOT", "HKEY_USERS"

## Creates Folder which contains all output files ##
$Folder = 'C:\temp' + "\pre_post_check"

if (Test-Path -Path $Folder) 
{
write-host "`tPrePostCheck folder exists!" -ForegroundColor Yellow
} 
else 
{
New-Item -Path '$Folder' -ItemType Directory -Force
Write-Host "New Directory for storing the prepostcheck files" -ForegroundColor Green
}

## Output files ##
$PreTextFile = "C:\temp\pre_post_check\Pre_check_File.txt"
$PostTextFile = "C:\temp\pre_post_check\Post_check_File.txt"
  
## Creates Registry folder ##         
$PostDirectory = "C:\temp\pre_post_check\PostCheck_Registry"

if (Test-Path -Path $PostDirectory) 
{
   write-host "`tPostCheck Registry folder exists!" -ForegroundColor Yellow
}
 
else 
{
    New-Item -ItemType Directory -Force -Path $PostDirectory
    Write-Host "`tNew Directory for storing the postCheck Registry files" -ForegroundColor Green
}      

## Removing old file ##
if (Test-Path $PostTextFile -PathType Leaf) 
{
    Write-Host "`tPrevious Post-check Output Text File exists !!!" -ForegroundColor yellow
    write-host "`tDeleting previous Post-check Output Text File" -ForegroundColor Green
    Remove-Item -Path $PostTextFile
    write-host "`tSuccessfully deleted the previous Post-check Output Text File !!!" -ForegroundColor Green 
}

Write-Host -ForegroundColor Green "`tStarting the script execution..."


# Function to get installed programs #
function Get-InstalledPrograms {
    Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
        Select-Object DisplayName #, Publisher, InstallDate, DisplayVersion
} 

# Server name and OS version #
Write-Output "----- Server Name -----" >> $PostTextFile
$server = $env:COMPUTERNAME 
$server >> $PostTextFile

Write-Output "----- OS Version -----" >> $PostTextFile
$osVersion = Get-WmiObject Win32_OperatingSystem | Select-Object Caption, Version >> $PostTextFile


# Domain relationship #
Write-Output "----- Domain Relationship -----" >> $PostTextFile
$domainRelationship = (Get-WmiObject Win32_ComputerSystem).Domain >> $PostTextFile


# NIC Names and IP addresses #
Write-Output "----- NIC Names and IP addresses -----" >> $PostTextFile
$nicInfo = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true } 
$nicDetails = $nicInfo | Select-Object Description, IPAddress >> $PostTextFile

# Route print details #
Write-Output "----- Routeprint details -----" >> $PostTextFile
$routePrintDetails = route print >> $PostTextFile

# MTU value #
Write-Output "----- MTU value -----" >> $PostTextFile
$mtuValue = netsh interface ipv4 show subinterfaces >> $PostTextFile

# Installed programs or software #
Write-Output "----- Installed programs or softwares -----" >> $PostTextFile
$installedPrograms = Get-InstalledPrograms >> $PostTextFile


# Backup Registry #

$regis_path = $PostDirectory + "*.reg"

## Creates Merged folder for Registry keys ##
$Final_BackupDirectory = "C:\temp\pre_post_check\Merged_PostCheck"

if (Test-Path -Path $Final_BackupDirectory) 
{
write-host "`tPostCheck Merged Registry folder exists!" -ForegroundColor Yellow
} 

else 
{
New-Item -ItemType Directory -Force -Path $Final_BackupDirectory
Write-Host "`tNew Directory for storing the merged_precheck files" -ForegroundColor Green
}
 
$output_File = "$Final_BackupDirectory\PostBackup_Registry.reg"

## Removing Merged files ##
if (Test-Path $regis_path -PathType Leaf) 
{
    Write-Host "`tPrevious merged registry file exists !!!" -ForegroundColor yellow
    write-host "`tDeleting previous merged registry file" -ForegroundColor Green
    Remove-Item -Path $regis_path
    write-host "`tSuccessfully deleted the previous merged registry file !!!" 
}

if (Test-Path $output_File -PathType Leaf) 
{
    Write-Host "`tPrevious merged registry file exists !!!" -ForegroundColor yellow
    write-host "`tDeleting previous merged registry file" -ForegroundColor Green
    Remove-Item -Path $output_File
    write-host "`tSuccessfully deleted the previous merged registry file !!!" 
} 

## Creates Separate Registry file ##
$i = 0
$keys | % {
  $i++
  & reg export $_ "$PostDirectory\$($i).reg" /y
}
Get-Content "$PostDirectory\*.reg" | Set-Content $output_File

   Write-Host "Registry backup completed."

## Comparision Of Both pre and post check files ##
Write-Output "-----Compared Data-----" >> $PostTextFile
$DataComparision = Compare-Object -ReferenceObject (Get-Content $PreTextFile) -DifferenceObject (Get-Content $PostTextFile) >> $PostTextFile 

Write-Host "`tScript execution completed..!" -ForegroundColor Green
