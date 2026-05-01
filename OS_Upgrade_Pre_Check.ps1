## Enter the Backup registry keys ##
$Folder = 'C:\temp' + "\pre_post_check"

#Enter the Backup registry keys
$Keys = "HKEY_CURRENT_CONFIG", "HKEY_LOCAL_MACHINE", "HKEY_CURRENT_USER", "HKEY_CLASSES_ROOT", "HKEY_USERS"

## Creates Folder which contains all output files ##
if (Test-Path -Path $Folder) 
{
write-host "`tPrePostCheck folder exists!" -ForegroundColor Yellow
} 
else 
{
New-Item -Path '$Folder' -ItemType Directory -Force
Write-Host "`tNew Directory for storing the prepostcheck files" -ForegroundColor Green
}


## Output files ##                    
$PreTextFile = "C:\temp\pre_post_check\Pre_check_File.txt"

## Creates Registry folder ##         
$PreDirectory = "C:\temp\pre_post_check\PreCheck_Registry"

if (Test-Path -Path $PreDirectory) 
{
   write-host "`tPreCheck Registry folder exists!" -ForegroundColor Yellow
}
 
else 
{
    New-Item -ItemType Directory -Force -Path $PreDirectory
    Write-Host "`tNew Directory for storing the preCheck Registry files" -ForegroundColor Green
}


## Removing old file ##
if (Test-Path $PreTextFile -PathType Leaf) 
{
    Write-Host "`tPrevious Pre-check Output Text File exists !!!" -ForegroundColor yellow
    write-host "`tDeleting previous Pre-check Output Text File" -ForegroundColor Green
    Remove-Item -Path $PreTextFile 
    write-host "`tSuccessfully deleted the previous Pre-check Output Text File !!!" 
}

# Function to get installed programs #

function Get-InstalledPrograms {
    Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* |
        Select-Object DisplayName, Publisher, InstallDate, DisplayVersion
} 


# Server name and OS version #
Write-Output "----- Server Name -----" >> $PreTextFile
$server = $env:COMPUTERNAME 
$server >> $PreTextFile

Write-Output "----- OS Version -----" >> $PreTextFile
$osVersion = Get-WmiObject Win32_OperatingSystem | Select-Object Caption, Version >> $PreTextFile


# Domain relationship #
Write-Output "----- Domain Relationship -----" >> $PreTextFile
$domainRelationship = (Get-WmiObject Win32_ComputerSystem).Domain >> $PreTextFile


# NIC Names and IP addresses #
Write-Output "----- NIC Names and IP addresses -----" >> $PreTextFile
$nicInfo = Get-WmiObject Win32_NetworkAdapterConfiguration | Where-Object { $_.IPEnabled -eq $true } 
$nicDetails = $nicInfo | Select-Object Description, IPAddress >> $PreTextFile


# Route print details #
Write-Output "----- Routeprint details -----" >> $PreTextFile
$routePrintDetails = route print >> $PreTextFile


# MTU value #
Write-Output "----- MTU value -----" >> $PreTextFile
$mtuValue = netsh interface ipv4 show subinterfaces >> $PreTextFile


# Installed programs or software #
Write-Output "----- Installed programs or softwares -----" >> $PreTextFile
$installedPrograms = Get-InstalledPrograms >> $PreTextFile


# Computer Management #
Write-Output "----- Computer Management -----" >> $PreTextFile
$Adminst = Get-LocalGroup | select name >> $PreTextFile

# Backup Registry #
$reg_path = $PreDirectory + "*.reg"

## Creates Merged folder for Registry keys ##
$Fin_BackupDirectory = "C:\temp\pre_post_check\Merged_PreCheck"

if (Test-Path -Path $Fin_BackupDirectory) 
{
write-host "`tPreCheck Merged Registry folder exists!" -ForegroundColor Yellow
} 

else 
{
New-Item -ItemType Directory -Force -Path $Fin_BackupDirectory
Write-Host "`tNew Directory for storing the merged_precheck files" -ForegroundColor Green
}
 
$output_File = "$Fin_BackupDirectory\PreBackup_Registry.reg"


## Removing Merged files ##
if (Test-Path $reg_path -PathType Leaf) 
{
    Write-Host "`tPrevious registry file exists !!!" -ForegroundColor yellow
    write-host "`tDeleting previous registry file" -ForegroundColor Green
    Remove-Item -Path $reg_path
    write-host "`tSuccessfully deleted the previous registry file !!!" 
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
  & reg export $_ "$PreDirectory\$($i).reg" /y
}
Get-Content "$PreDirectory\*.reg" | Set-Content $output_File

        Write-Host "Registry backup completed."

Write-Host "`tScript execution completed..!" -ForegroundColor Green
