Start-Transcript -path "$((Get-Location).Path)\transcript.txt"

$path="$((Get-Location).Path)"

$packageFileNames = "setup64.exe", "NDP481-Web.exe" 
$sharePath = "C:\temp\VMware-Tools-windows-12.3.0-22234872"
$output_file = "$path\Installed_StatusFile.txt"

### Removing old files ###

if (Test-Path $output_file -PathType Leaf) 
{
    Write-Host "`tPrevious output text file exists !!!" -ForegroundColor yellow
    write-host "`tDeleting previous output text file" -ForegroundColor Green
    Remove-Item -Path $output_file
    write-host "`tSuccessfully deleted the previous output text file !!!" -ForegroundColor Magenta
}


# Checks installed programs #
$Installed_Software = Get-ItemProperty HKLM:\Software\Wow6432Node\Microsoft\Windows\CurrentVersion\Uninstall\* | Select-Object DisplayName #, Publisher, InstallDate, DisplayVersion


foreach ($packageFileName in $packageFileNames){
$packageFilePath = Join-Path -Path $sharePath -ChildPath $packageFileName


if (Test-Path $packageFilePath) 
{
    Write-output "$packageFileName exists in $sharePath." >> $output_file 
    
            if ($Installed_Software -match "VMwareTools") 
            {  
                Write-Host "VMwareTools Software is already installed on the VM's."
                Write-Output "VMwareTools Software is already installed on the VM's." >> $output_file 
            }
            else
            {
                Write-Host  "VMwareTools Software is not installed on the VM's." 
                Write-Output  "VMwareTools Software is not installed on the VM's." >> $output_file
                $vmtools = C:\temp\VMware-Tools-windows-12.3.0-22234872\setup64.exe /s /v /qn
                Write-Output "VMwareTools Software is installing...." >> $output_file
                Write-Host "VMwareTools Software is now installed on the VM's." 
                Write-Output "VMwareTools Software is now installed on the VM's." >> $output_file
            }

            if ($Installed_Software -match ".net")
            {
                Write-Host ".Net Framework Software is already installed on the VM's." 
                Write-Output ".Net Framework Software is already installed on the VM's." >> $output_file
            }
    
            else
            {
                Write-Host ".Net Framework Software is not installed on the VM's."
                Write-output ".Net Framework Software is not installed on the VM's." >> $output_file
                $Dotnet = Start-Process -FilePath "C:\temp\VMware-Tools-windows-12.3.0-22234872\NDP481-Web.exe" -ArgumentList "/Q /verysilent /norestart" -NoNewWindow -Wait
                Write-output ".Net Framework Software is installing....." >> $output_file
                Write-Host ".Net Framework Software is now installed on the VM's."
                Write-output ".Net Framework Software is now installed on the VM's." >> $output_file
            }

} 
else
{
    Write-Host "$packageFileName does not exist in $sharePath." 
    Write-output "$packageFileName does not exist in $sharePath." >> $output_file
}
}


 # Clean up temporary files after installation

if (Test-Path $packageFilePath)
 {
        Write-Host "Cleaning up temporary files..."
        Remove-Item $packageFilePath -Force
        Write-Host "Temporary files removed."
        Write-Output "Temporary files removed." >> $output_file
 }
else 
 {
        Write-Host "No temporary files found to clean up."
        Write-Output "No temporary files found to clean up." >> $output_file
 }


Stop-Transcript 

#Get-WmiObject -class Win32_Product | Where-Object {$_.Name -match "VMware Tools"}
#Get-WmiObject -class Win32_Product | Where-Object {$_.Name -match ".Net"}


