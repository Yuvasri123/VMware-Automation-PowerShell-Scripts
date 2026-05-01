<#
.SYNOPSIS
  To capture VSan capacity which matches with given threshold and send it in a mail.
.DESCRIPTION
 VSan capacity from multiple vcenters are collected and filtered with specific threshold and will be sent in a mail.
    
.OUTPUTS
  HTML output file will be stored in in powershell solution path and same will be sent in a mail as a body.
.NOTES
  Version:        1.0
  Authors:       Yuvasri C <yuvasri.c@dxc.com>.
  Creation Date:  24/08/2022.
  Purpose: To capture VSan capacity info.
  
.EXAMPLE
  #To capture VSan capacity info which matches with given threshold and send it in a mail
  .\VSAN-CapacityInfo_v1.0.ps1
#>

#----------------------------------------------------------[Declarations]----------------------------------------------------------


$vCenters = @('scc-m1-vc.hci.cloud1.cibc.com','scc-w1-vc.hci.cloud1.cibc.com','scc-w2-vc.hci.cloud1.cibc.com','scc-w3-vc.hci.cloud1.cibc.com','mcc-m1-vc.hci.cloud1.cibc.com','mcc-w1-vc.hci.cloud1.cibc.com','mcc-w2-vc.hci.cloud1.cibc.com','mcc-w3-vc.hci.cloud1.cibc.com') # Enter vCenter Domain Name or IP
$CapacityThreshold = 80

$From = "dcchealthcheck@dxc.com"
$To = "dxccibcvmwareops@dxc.com"
$Cc = ""
$SMTPServer = ""
$SMTPPort = "25"

$vCuser = "administrator@vsphere.local"
$VCPass = "Hyp3rC0n1nfra!"

$StartedTime = (Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt K') + " $([TimeZoneInfo]::Local.Id)"
$Subject = "[Action Needed] VSan capacity Alert info at " + $StartedTime


#---------------------------------------------------------[Initialisations]--------------------------------------------------------

#Set Error Action to Silently Continue
$ErrorActionPreference = "Stop"
$CurrentPath = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$CredPath = [string]$CurrentPath + "\cred.xml"
$OutputFile = [string]$CurrentPath + "\Vsancapcitysummary.html"


if (Test-Path $OutputFile -PathType Leaf) 
{
    Remove-Item -Path $OutputFile

}


#-----------------------------------------------------------[Functions]------------------------------------------------------------

function write_HTML_body {

    param(
        $CollectionData
    )    
    $tabledata = '<table class="styled-table">'
    $tabledata += '<thead><tr>'
    foreach ($head in "VCenter", "Cluster", "VSANDatastore", "CapacityTB", "ProvisionedTB", "FreeSpaceTB", "PercentUsed"){
        $tabledata += '<th>' + $head + '</th>'
    }
    $tabledata += '</tr></thead>'
    $tabledata += '<tbody>'
    foreach ($row in $CollectionData) {
        $tabledata += '<tr>'
        $tabledata += '<td>' + $($row.VCenter) + '</td>'
        $tabledata += '<td>' + $($row.Cluster) + '</td>'
        $tabledata += '<td>' + $($row.VSANDatastore) + '</td>'
        $tabledata += '<td>' + $($row.CapacityTB) + '</td>'
        $tabledata += '<td>' + $($row.ProvisionedTB) + '</td>'
        $tabledata += '<td>' + $($row.FreeSpaceTB) + '</td>'
       
        if($row.PercentUsed -ge $CapacityThreshold){
           $Statuscolor = "red"
        } elseif($row.PercentUsed -gt ($CapacityThreshold - 10) ){
           $Statuscolor = "yellow"
        } else {
           $Statuscolor = "green"
        }
        $tabledata += '<td style="background-color:' + $($Statuscolor) +'">' + $($row.PercentUsed) + '</td>'
        
        $tabledata += '</tr>'
    }
    $tabledata += '</tbody>'
    $tabledata += '</table>'


    $html = @"
<html>
<head>
<style>
.styled-table {
border-collapse: collapse;
margin: 5px 0;
font-size: 0.8em;
font-family: sans-serif;
min-width: 150px;
box-shadow: 0 0 20px rgba(0, 0, 0, 0.15);
align: center;
font-weight: bold;
}



.styled-table thead tr {
background-color: #5F249F;
color: #ffffff;
text-align: left;
}



.styled-table th,
.styled-table td {
padding: 5px;
border: 1px solid black;
}



.styled-table tbody tr {
border-bottom: 1px solid #dddddd;
}



.styled-table tbody tr:nth-of-type(even) {
background-color: #f3f3f3;
}


.styled-table tbody tr:last-of-type {
border-bottom: 2px solid #5F249F;
}

body {
font-size: 1 em;
font-family: sans-serif;
}
</style>
</head>
<body>
<p>Hi Team,<br><br>
 Please find the VSan Capacity for your VMWare environment $($vCenters -join "|") collected at : $($StartedTime). <br> <br>
$($tabledata)
<br>
Thank you,
</p>
<br>
Regards <br>
Automation Team.
</p>
</body>
</html>
"@
    return $html
}



Function Get-VsancapcityInfo {
    param (
        $vCenter = $(throw "A vCenter must be specified."),
        $VCUsername,
        $VCPassword
    )
    Write-Host "Connecting to the vCenter $vCenter..."
    if ($vCenter) {
        $vc = Connect-VIServer -Server $vCenter -User $VCUsername -Password $VCPassword
    }
    else {
        $vc = Connect-VIServer $vCenter
    }
    if (!$vc) {
        Write-Host "Failure connecting to the vCenter $vCenter."
    }

    $AllCapacityInfo = @()
    $Clusters = Get-Cluster

    foreach ($Onecluster in $Clusters) {

        $DataInfo = Get-Cluster -Name $Onecluster.Name | Get-Datastore | Where-Object {$_.Type -match 'vsan'} | Select-Object Name, @{N="CapacityTB";E={[math]::Round($_.CapacityGB/1024,2)}},
            @{N="ProvisionedTB";E={([math]::Round($_.CapacityGB/1024,2) - [math]::Round($_.FreeSpaceGB/1024,2))}},
            @{N="FreeSpaceTB";E={[math]::Round($_.FreeSpaceGB/1024,2)}},  @{N="PercentUsed";E={[math]::Round((($_.CapacityGB - $_.FreeSpaceGB)/$_.CapacityGB)*100,2)}}

        $VsanCap = "" | Select-Object VCenter, Cluster, VSANDatastore, CapacityTB, ProvisionedTB, FreeSpaceTB, PercentUsed
        $VsanCap.VCenter = $vCenter
        $VsanCap.Cluster = $Onecluster.Name
        $VsanCap.VSANDatastore = $DataInfo.Name
        $VsanCap.CapacityTB = $DataInfo.CapacityTB
        $VsanCap.ProvisionedTB = $DataInfo.ProvisionedTB
        $VsanCap.FreeSpaceTB = $DataInfo.FreeSpaceTB
        $VsanCap.PercentUsed = $DataInfo.PercentUsed

        $AllCapacityInfo += $VsanCap

 
    }
    Disconnect-VIServer $vCenter -Confirm:$false
    Write-Host "vCenter $vCenter server disconnected"
    return $AllCapacityInfo
}



#-----------------------------------------------------------[Execution]------------------------------------------------------------


#if (Test-Path $CredPath -PathType Leaf) 
#{
#    $vCCreds = Import-CliXml -Path $CredPath
#
#}
#else
#{
#    $vCCreds = Get-Credential -Message "Please Enter vCeter Credential"
#    $vCCreds | Export-CliXml -Path $CredPath
#}


Write-Host ("Getting the VSAN Capcity from {0} vCenters." -f $vCenters.Length)
$All = @()

foreach ($vCenter in $vCenters) {
    try {
        Write-Host "Getting VSAN Capcity details from $vCenter."
        $All += Get-VsancapcityInfo -vCenter $vCenter -VCUsername $vCuser -VCPassword $VCPass
        Write-Host "Activity completed for server $vCenter."

    }
    catch [Exception] 
    {
        Write-Host "Unable to capture VSAN Capcity info from vcenter $vCenter. Error occurred is: $($_ | Out-String)"
    }

}

$AllThreshold = $All | Where-Object { $_.PercentUsed -ge $CapacityThreshold }

if ($AllThreshold) {
    Write-Host "Details collected. Generating html data"
    $html_body = write_HTML_body -CollectionData $AllThreshold
    $html_body | Out-File -FilePath $OutputFile
    $Body = Get-Content $OutputFile | Out-String
    Send-MailMessage -From $From -to $To -Subject $Subject -Cc $Cc -Body $Body -BodyAsHtml -SmtpServer $SMTPServer -port $SMTPPort
    # Recording the last checked time

}
else {
    Write-Host "No vsan capacity reached threshold limit"
}
Write-Host "Script Execution completed."