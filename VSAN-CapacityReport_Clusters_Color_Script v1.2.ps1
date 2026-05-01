<#
.SYNOPSIS
  vCenter Email and alert notification vSAN Capacity report for clusters with colour code
.DESCRIPTION
  To capture vSAN Capacity info from multiple vCenters is collected, and the percent used is highlighted with different color codes for specific range and send it in a mail.
    
.OUTPUTS
  HTML output file will be stored in in powershell solution path and same will be sent in a mail as a body.
.NOTES
  Version:        1.0
  Authors:        Yuvasri C <yuvasri.c@dxc.com>.
  Creation Date:  10/08/2023.
  Purpose: To capture VSan capacity info.
  
.EXAMPLE
  #To capture VSan capacity info which the percent used is highlighted with different color codes for specific range and send it in a mail
  .\VSAN-CapacityReport_Clusters_Color_Script v1.2.ps1
#>

#----------------------------------------------------------[Declarations]----------------------------------------------------------


$vCenters = @("","") # Enter vCenter Domain Name or IP

$From = ""
$To = ""
$Cc = ""
$SMTPServer = ""
$SMTPPort = "25"


# ------------------------------------------------------------- Credential File --------------------------------------------------- #


#To reset the credential make this variable $true and execute the script. 
#Copy paste the encoded user and password generated in the blue console into $EncodedUserString and $EncodedPasswordString respectively.
#After the resetting credential is done change the $resetCredential back to $false.
$reset_Credential = $false

if($reset_Credential -eq $true){
    Write-Host "`tDo you want to reset password"
    $check = Read-Host "`tEnter 'y' if yes and 'n' if no"
    if($check -eq 'y'){
        $User = Read-Host "Enter vCenter user name"
        $pass = Read-Host "Enter vCenter password"

        # Gets the bytes of String
        $UserBytes = [System.Text.Encoding]::Unicode.GetBytes($User)
        $passBytes = [System.Text.Encoding]::Unicode.GetBytes($pass)

        # Encode string content to Base64 string
        $EncodedUser =[Convert]::ToBase64String($UserBytes)
        $Encodedpwd = [Convert]::ToBase64String($passBytes)

        Write-Host "`nEncode User name:`n $EncodedUser " 
        Write-Host "`nEncode password:`n $Encodedpwd " 
    }
}

$EncodedUserString = "YQBkAG0AaQBuAGkAcwB0AHIAYQB0AG8AcgBAAHYAcwBwAGgAZQByAGUALgBsAG8AYwBhAGwA"
$EncodedPasswordString = "SAB5AHAAMwByAEMAMABuADEAbgBmAHIAYQAhAA=="

$DecodedUser = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($EncodedUserString))
$DecodedPass = [System.Text.Encoding]::Unicode.GetString([System.Convert]::FromBase64String($EncodedPasswordString ))

$StartedTime = (Get-Date).ToString('MM/dd/yyyy hh:mm:ss tt K') + " $([TimeZoneInfo]::Local.Id)"
$Subject = "[Action Needed] VSan capacity Alert info at " + $StartedTime


#---------------------------------------------------------[Initialisations]--------------------------------------------------------


#Set Error Action to Silently Continue
$ErrorActionPreference = "Stop"
$CurrentPath = Split-Path -Path $MyInvocation.MyCommand.Path -Parent
$CredPath = [string]$CurrentPath + "\cred.xml"
$OutputFile = [string]$CurrentPath + "\Vsancapcitysummary.html"


# ------------------------------------------------- Removing Existing Output files ----------------------------------------------- #


if (Test-Path $OutputFile -PathType Leaf) 
{
    Write-Host "`tPrevious log report exists !!!" -ForegroundColor yellow
    write-host "`tDeleting previous log report" -ForegroundColor Green
    Remove-Item -Path $OutputFile
    write-host "`tSuccessfully deleted the previous log report !!!" -ForegroundColor Green 

}


#----------------------------------------------------------- Sample HTML Table --------------------------------------------------- #


$table = "<table border='1' align='Left' cellpadding='6' cellspacing='0' style='color:black;font-family:arial,helvetica,sans-serif;text-align:left;width:21%;'>
<tr style ='font-size:15px;font-weight: normal;background:#5F249F;color:white;'>
<th align=center><b>Range</b></th>
<th align=center ><b>Color Code</b></th>


</tr>"

    $table += "<tr style='font-size:14px;background-color:#FFFFFF;'>
<td>" + "Below 70%" + "</td>
<td style=background:#228B22>" + "Healthy" + "</td>
</tr>
<tr style='font-size:14px;background-color:#FFFFFF'>
<td>" + "Between 70%-80%" + "</td>
<td style=background:#FFFF00>" + "Warning" + "</td>
</tr>
<tr style='font-size:14px;background-color:#FFFFFF'>
<td>" + "Above 80%" + "</td>
<td style=background:#FF0000>" + "Critical" + "</td>
</tr>"


$table += "</table>"
$table > $OutputFile


#-----------------------------------------------------------[Functions]------------------------------------------------------------


Write-Host -ForegroundColor Magenta "`tStarting the script execution..."


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
$table
<br> <br><br> <br>
<br> <br><br> <br>
$tabledata
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
        $DecodedUser,
        $DecodedPass      
    )
    Write-Host "`tConnecting to the vCenter $vCenter..." -ForegroundColor Green
    if ($vCenter) {
        $vc = Connect-VIServer -server $vCenter -User $DecodedUser -Password $DecodedPass        
    }
    else {
        $vc = Connect-VIServer $vCenter
    }
    if (!$vc) {
        Write-Host "`tFailure connecting to the vCenter $vCenter.." -ForegroundColor Red
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
        $AllCapacityInfo_sort = $AllCapacityInfo | Sort-Object -Descending PercentUsed
 
    }

    # Disconnecting vCenter 
    Disconnect-VIServer $vCenter -Confirm:$false
    Write-Host "`tvCenter $vCenter server disconnected" -ForegroundColor Green
    return $AllCapacityInfo_sort
}


#-----------------------------------------------------------[Execution]------------------------------------------------------------


Write-Host ("`tGetting the VSAN Capcity from {0} vCenters." -f $vCenters.Length) -ForegroundColor Cyan
$All = @()

foreach ($vCenter in $vCenters) {
    try {
        Write-Host "`tGetting VSAN Capcity details from $vCenter" -ForegroundColor Green
        $All += Get-VsancapcityInfo -vCenter $vCenter -DecodedUser $DecodedUser -DecodedPass $DecodedPass
        Write-Host "`tActivity completed for server $vCenter." -ForegroundColor Magenta

    }
    catch [Exception] 
    {
        Write-Host "`tUnable to capture VSAN Capcity info from vcenter $vCenter. Error occurred is: $($_ | Out-String)"
    }

}


if ($All) {
    Write-Host "`tDetails collected. Generating html data" -ForegroundColor Green
    $html_body = write_HTML_body -CollectionData $All
    $html_body | Out-File -FilePath $OutputFile
    $Body = Get-Content $OutputFile | Out-String

    # Send mail
    Send-MailMessage -From $From -to $To -Subject $Subject -Cc $Cc -Body $Body -BodyAsHtml -SmtpServer $SMTPServer -port $SMTPPort
  

}
else {
    Write-Host "`tNo vsan capacity reached threshold limit" -ForegroundColor Yellow
}


Write-Host "`tScript Execution completed" -ForegroundColor Green