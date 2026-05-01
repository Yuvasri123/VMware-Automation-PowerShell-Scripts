<#
.SYNOPSIS
  To find the list of vms in vCenter to get the assigned tags and send it in a csv file.
.DESCRIPTION
  To get the list of VMs from three vCenters and get the VMname, Category, and TagName, and send it in a csv output file.
    
.OUTPUTS
  The CSV output file will be stored in the powershell solution path.
.NOTES
  Version:        1.0
  Authors:        Yuvasri C <yuvasri.c@dxc.com>.
  Creation Date:  08/11/2022.
  Purpose: To get VMs assigned tags.
  
#>

#----------------------------------------------------------------[Declarations]-----------------------------------------------------------

$vCenters = @("","","") # Enter vCenter Domain Name or IP

#----------------------------------------------------------------[Initialisations]----------------------------------------------------------

$ErrorActionPreference = "Stop"
$CurPath = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$CredPath = [string]$CurPath + "\cred.xml"
$outputfile = [string]$CurPath + "\VmInfos.csv"


if (Test-Path $outputFile -PathType Leaf) 
{
    Remove-Item -Path $outputFile
}


#----------------------------------------------------------------[Execution]--------------------------------------------------------------

if (Test-Path $CredPath -PathType Leaf) 
{
    $vCCreds = Import-CliXml -Path $CredPath

}
else
{
    $vCCreds = Get-Credential -Message "Please Enter vCenter Credential"
    $vCCreds | Export-CliXml -Path $CredPath
}


$AllVmInfo = @()

foreach ($vCenter in $vCenters)
{
  try
  {
   Write-Host "Connecting to the vCenter $vCenter..."
   connect-VIserver $vCenter -Credential $vCCreds -ErrorAction Stop
   Write-Host "Connected to the vCenter $vCenter..."
   $Infos = Get-VM | Get-TagAssignment | Select @{N='VMname';E={$_.Entity.Name}}, @{N='Category';E={$_.Tag.Category}}, @{N='TagName';E={$_.Tag.Name}}
    foreach ($OneRow in $Infos) 
    {

            $VmInfo = "" | Select-Object VCenter, VMname, Category, TagName
            $VmInfo.VCenter = $vCenter
            $VmInfo.VMname = $OneRow.VMname
            $VmInfo.Category = $OneRow.Category
            $VmInfo.TagName = $OneRow.TagName

            $AllVmInfo += $VmInfo
    }     
  }
catch [Exception]
{
    Write-Host "Unable to find vm assigned tags for vCenter $vCenter. Error occurred is: $($_ | Out-String)" 
}
    Disconnect-VIServer $vCenter -Confirm:$false
    Write-Host "vCenter $vCenter server disconnected "
}
   
$AllVmInfo | Export-Csv $outputfile -NoTypeInformation -Append

#-------------------------------------------------------------------[End]----------------------------------------------------------------







