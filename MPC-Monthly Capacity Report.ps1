<#
.Synopsis
 Monthly Capacity Report for MPC Environment.

.DESCRIPTION
 The Script will perform checks and provide both Monthly and 24 Hours data for clusterwise report, ESXIHostwise report and Host group details report.
 This report will match the Script ESXIHost with the Input ESXIHost and gives the ESXIHost Group name with CPU and Memory Average.

.INPUT
 1)vcenterinput.csv- CSV file containing below fields.
    vCenter
 2)hostinput.csv- CSV file containing below fields
    Host_Group_Name,EXSIHost
        
.OUTPUT
 The HTML report will be generated in 'MPC-Monthly Capacity Report.html' file stored in the powershell solution path. 
 The CSV file will be generated in 'Clusterlevel_Utilization.csv' , 'ESXIHost_Utilization.csv' and 'HostGroupwise_Utilization.csv' file stored in the powershell solution path
 If any error encountered during execution an error log file 'clustererror_logfile.csv' and 'hosterror_logfile.csv' will get generated.

 Also output html files and csv files will be send to the configured mailid’s.

.NOTES
 Version:        1.0.0
 Author :        Yuvasri.C 
 Author email:   <yuvasri.c@dxc.com>
 Creation Date:  11/01/2023

#>

param (
         $DataWindow = "Last1Month"
     )

########################### Mail Variables Declarations ############################

$From = ""
$To = ""
$Cc = ""
$SMTPServer = ""
$SMTPPort = ""

####################### Monthly and 24 Hours data Declarations #####################

Start-Transcript -path "$((Get-Location).Path)\transcript.txt"

if ($DataWindow -eq "Last1Month") {

    $CURRENTDATE=GET-DATE -Hour 0 -Minute 0 -Second 0
    $MonthAgo = $CURRENTDATE.AddMonths(-1)
    $start=GET-DATE $MonthAgo -Day 1
    $stop=GET-DATE $start.AddMonths(1).AddSeconds(-1)
    #$DataWindow = $start
    #$IntervalFrame = 720
    $MaxCount = [int]::MaxValue
}
else {
    $DataWindow = (Get-date).AddHours(-24)
    #$IntervalFrame = 5
    $start=(Get-date).AddHours(-24)
    $stop= (Get-date)
    #$MaxCount = 288
    $MaxCount = [int]::MaxValue
}

Write-Host "Data window start: $DataWindow, Interval: $IntervalFrame, Max Samples: $MaxCount"

##################################### Input Files ###################################

$path="$((Get-Location).Path)"
$inputfile1="$path\vcenterinput.csv"
$inputfile2="$path\hostinput.csv"

##################################### Output Files ##################################

$reportname = "$path\MPC-Monthly Capacity Report.html"
$CredPath="$path\cred.xml"
$clustererrorlog = "$path\clustererror_logfile.csv"
$hosterrorlog = "$path\hosterror_logfile.csv"
$Files = Get-childitem "$path\*.csv"

$clustercsv = "$path\Clusterlevel_Utilization.csv"
$hostcsv = "$path\ESXIHost_Utilization.csv"
$hostgroupcsvPath = "$path\HostGroupwise_Utilization.csv"
$date = Get-Date -Format "dd/MM/yyyy hh:mm"

############################### Declaration of html arrays ############################

$tabledata1 =""
$tabledata2 =""
$tabledata3 =""

#################################### Declaration of arrays ############################

  $table1= @()
  $table2 = @()
  $table3 = @()
  $csv_file1 = @()
  $csv_file2 = @()

################################## Removing Previous files ############################

if (Test-Path $reportname -PathType Leaf) 
{
    Write-Host "`tPrevious log report exists" 
    write-host "`tDeleting previous log report" -ForegroundColor Green
    Remove-Item -Path $reportname
}

foreach($file in $Files){
if (($file -match "Clusterlevel_Utilization") -or ($file -match "ESXIHost_Utilization") -or ($file -match "HostGroupwise_Utilization"))
{
    Write-Host "`tPrevious csv files exists" 
    write-host "`tDeleting previous csv files" -ForegroundColor Green
    Remove-Item -Path $file

}
}

if (Test-Path $clustererrorlog -PathType Leaf) 
{      
    Write-Host "`tPrevious error log report exists" 
    write-host "`tDeleting previous log report" -ForegroundColor Green
    Remove-Item -Path $clustererrorlog
}
if (Test-Path $hosterrorlog -PathType Leaf) 
{      
    Write-Host "`tPrevious error log report exists" 
    write-host "`tDeleting previous log report" -ForegroundColor Green
    Remove-Item -Path $hosterrorlog
}

########################### Extracting content from input files ##########################

$InputvcenterFile = Get-Content $inputfile1 | select -Skip 1 | ConvertFrom-Csv -Delimiter "," -Header ("vCenter")
$InputHostfile = Get-Content $inputfile2| select -Skip 1 | ConvertFrom-Csv -Delimiter "," -Header ("Host_Group_Name","Hosts")

######################################## Execution #######################################

if (Test-Path $CredPath -PathType Leaf) 
{
    $vCCreds = Import-CliXml -Path $CredPath

}
else
{
    $vCCreds = Get-Credential -Message "Please Enter the vCenter Credential"
    $vCCreds | Export-CliXml -Path $CredPath
}

foreach ($vCen in $InputvcenterFile.vCenter)
{
  Write-host "Connecting vCenter server....."
  Connect-VIServer -server $vCen -Credential $vCCreds 
  write-host "`tSuccessfully connected to the $vCen vCenter"
  $clusters=Get-Cluster -Server $vCen 
  $vcenterserver = "<td>$($vCen)</td>"
  

######################################## Clusterwise Details ##########################################


    foreach ($clus1 in $clusters)
    {
    $clus = $clus1.Name
    Write-Host "`tCalculating the CPU and memory utilization of cluster- $clus" -ForegroundColor Green
    $clust = "" | Select vCenter, Cluster, CPUAvg, MemoryAvg, UsedSpace, FreeSpace
    $clust.Cluster = "<td>$($clus)</td>"
    try
    {
        $statucpu = Get-VMhost -Location $clus | Get-Stat -stat cpu.usage.average -start $start -Finish $stop -MaxSamples ($MaxCount)  | Measure-Object -Property value -Average -Maximum -Minimum -ErrorAction Stop      
        $CPUAvg = [Math]::Round((($statucpu).Average))
        
        if ($CPUAvg -ge 95) { $CPUAvg_status =  "<td class=""Redfont""; style=""background-color:#ff0000"">$($CPUAvg) % </td>" }
        else { $CPUAvg_status = "<td class=""Redfont""; style=""background-color:#6cc24a"">$($CPUAvg) % </td>" }
        $clust.CPUAvg = $CPUAvg_status

        $memoryusage = Get-VMhost -Location $clus | Get-Stat -Stat mem.usage.average -start $start -Finish $stop -MaxSamples ($MaxCount) | Measure-Object Value -Average -Maximum -Minimum
        $MEMAvg = [Math]::Round((($memoryusage).Average))
        
        if ($MEMAvg -ge 95) { $MEMAvg_status = "<td class=""Redfont""; style=""background-color:#ff0000"">$($MEMAvg) % </td>" }
        else { $MEMAvg_status = "<td class=""Redfont""; style=""background-color:#6cc24a"">$($MEMAvg) % </td>" }
        $clust.MemoryAvg = $MEMAvg_status

        $vSanSpaceUse = Get-Cluster -Name $clus | Get-Datastore |  Where-Object {$_.Type -match 'vsan'}

        $vSanUsed = $VsanspaceUse.CapacityGB - $VsanSpaceUse.FreeSpaceGB
        if ($vSanUsed) {        
        $used_capacityy=[math]::round( ($VsanUsed * 100 ) / $VsanSpaceUse.CapacityGB,2)
        $used_capac =($VsanUsed * 100 ) / $VsanSpaceUse.CapacityGB
        $utilized_percentage = [math]::Ceiling($used_capac)
       
        if ($utilized_percentage -ge 80) { $Storpercent_status = "<td class=""Redfont""; style=""background-color:#ff0000""; >$($utilized_percentage) %</td>" }
        else { $Storpercent_status = "<td class=""Redfont""; style=""background-color:#6cc24a""; >$($utilized_percentage) %</td>" }
       
        $free_space = 100-($utilized_percentage)
        $free_percentage = [math]::Ceiling($free_space)
        if ($free_percentage) { $freepercent_status = "<td class=""Redfont""; style=""background-color:#6cc24a""; >$($free_percentage) %</td>" }
        
        write-host "$VsanSpaceUse", "$Storpercent_status"
        $clust.UsedSpace = $Storpercent_status
        $clust.FreeSpace = $freepercent_status
        }
        } 
               
    #Captures Error log file for clusterwise

    catch [Exception]
    {
    Write-Host "`tError while execution. Unable to find Cluster- $clus" -ForegroundColor Red
    Write-Host "`tError: $($_.Exception.Message)"
    [psCustomObject] [Ordered]@{
                        cluster      = $clus
                        ErrorMessage = $_
                        LineNumber   = $_.InvocationInfo.ScriptLineNumber
                    } | Export-Csv -Path $clustererrorlog -NoTypeInformation -Append
    }
    $clust
    $table1 += $clust

    #Captures in CSV file for clusterwise details

    $csv1 = [psCustomObject] [Ordered]@{
                        vCenter                       = $vCen
                        Cluster                       = $clus
                        CPUAvg                        = $CPUAvg
                        MemoryAvg                     = $MEMAvg
                    } 
                    
                    $csv_file1 += $csv1
    }

    $csv_file1 | Export-Csv -Path $clustercsv -NoTypeInformation

    #Clusterwise HTML table

    $tabledata1 = '<table class="styled-table">'
    $tabledata1 += '<thead><tr>'
    foreach ($head in "vCenter","Cluster","CPUAvg","MemoryAvg"){
        $tabledata1 += '<th>' + $head + '</th>'
    }
    $tabledata1 += '</tr></thead>'
    $tabledata1 += '<tbody>'
    foreach($row in $table1){
        $tabledata1 += '<tr>'
        $tabledata1 += $vcenterserver
        $tabledata1 += $row.Cluster
        $tabledata1 += $row.CPUAvg
        $tabledata1 += $row.MemoryAvg
        $tabledata1 += '</tr>'
       }
    $tabledata1 += '</tbody>'
    $tabledata1 += '</table>'
    
########################################### ESXIHostwise Details ###########################################

$HostGroupCsvArray =  @()
foreach ($onecl in $clusters) 
{
$cl = $onecl.name
$hosts = get-cluster -name $cl -Server $vCen | Get-VMHost -Server $vCen #| Select -First 10
$cl
    foreach($vmHost1 in $hosts)
    {
        $vmHost = $vmHost1.Name
        Write-Host "`tCalculating the CPU and memory utilization of ESXi Host- $vmHost" -ForegroundColor Green
        $hostst = "" | Select vCenter, Cluster, ESXIHost, CPUAvg, MemoryAvg
        $hostst.ESXIHost = "<td>$($vmHost)</td>"
        $hostst.Cluster ="<td>$($cl)</td>"
        write-Host "$vmHost"
  
        try{
            $vmcheck = Get-VMHost -name $vmHost -ErrorAction Stop
            $statcpu =  Get-Stat -Entity $vmHost -Stat cpu.usage.average -start $start -Finish $stop -MaxSamples ($MaxCount) -ErrorAction Stop | Measure-Object -Property value -Average -Maximum -Minimum 
            $memusage = Get-Stat -Entity $vmHost -Stat mem.usage.average -start $start -Finish $stop -MaxSamples ($MaxCount) -ErrorAction Stop |Measure-Object Value -Average -Maximum -Minimum 
            $CPUAvg = [Math]::Round((($statcpu).Average))
            $MEMAvg = [Math]::Round((($memusage).Average))
            
            $HostGroupCsv           = "" | Select vCenter, Cluster, ESXIHost, CPUAvg, MemoryAvg 
            $HostGroupCsv.vCenter   = $vCen
            $HostGroupCsv.Cluster   = $cl 
            $HostGroupCsv.ESXIHost  = $vmHost
            $HostGroupCsv.CPUAvg    = $CPUAvg
            $HostGroupCsv.MemoryAvg = $MEMAvg 

            $HostGroupCsvArray     += $HostGroupCsv

            if ($CPUAvg -ge 95) { $CPUAvg_status = "<td class=""Redfont""; style=""background-color:#ff0000"">$($CPUAvg) % </td>" }
            else { $CPUAvg_status = "<td class=""Redfont""; style=""background-color:#6cc24a"">$($CPUAvg) % </td>" }
    
            if ($MEMAvg -ge 95) { $MEMAvg_status = "<td class=""Redfont""; style=""background-color:#ff0000"">$($MEMAvg) % </td>" }
            else { $MEMAvg_status = "<td class=""Redfont""; style=""background-color:#6cc24a"">$($MEMAvg) % </td>" }
  
            $hostst.CPUAvg = $CPUAvg_status
            $hostst.MemoryAvg = $MEMAvg_status
            }

         #Captures Error log file for ESXIHostwise

         catch {
            Write-Host "`tError while execution. Unable to find VMHost- $vmHost" -ForegroundColor Red 
            Write-Host "`tError: $($_.Exception.Message)"

            [psCustomObject] [Ordered]@{
                        ESXIHost     = $vmHost
                        ErrorMessage = $_.Exception.Message
                        FailedItem   = $_.Exception.ItemName
                        LineNumber   = $_.InvocationInfo.ScriptLineNumber
                    } | Export-Csv -Path $hosterrorlog -NoTypeInformation -Append
           }
        
    $table2 += $hostst

    #Captures in CSV file for ESXIHostwise details

    $csv2 = [psCustomObject] [Ordered]@{
                        vCenter         = $vCen
                        Cluster         = $cl
                        ESXIHost        = $vmHost
                        CPUAvg          = $CPUAvg
                        MemoryAvg       = $MEMAvg
                    } 
                    
                    $csv_file2 += $csv2               
    }
    
}
     $csv_file2 | Export-Csv -Path $hostcsv -NoTypeInformation

#ESXIHostwise HTML table

$tabledata2 = '<table class="styled-table">'
    $tabledata2 += '<thead><tr>'
    foreach ($head in "vCenter","Cluster","ESXIHost","CPUAvg","MemoryAvg"){
        $tabledata2 += '<th>' + $head + '</th>'
    }
    $tabledata2 += '</tr></thead>'
    $tabledata2 += '<tbody>'
    foreach($row1 in $table2){
        $tabledata2 += '<tr>'
        $tabledata2 += $vcenterserver
        $tabledata2 += $row1.Cluster
        $tabledata2 += $row1.ESXIHost
        $tabledata2 += $row1.CPUAvg
        $tabledata2 += $row1.MemoryAvg
        $tabledata2 += '</tr>'
       }
    $tabledata2 += '</tbody>'
    $tabledata2 += '</table>'

######################################## ESXIHost Group Details ####################################

$allhostgroup = @()
#Logic for matching the ESXIHost and giving the ESXIHost Group name with CPU and Memory Average

$csv_file3 = @()
foreach ($HostGroup in $HostGroupCsvArray)
{
    $allhostgroup = "" | Select vCenter,ESXIHost, Host_Group_Name, CPUAvg, MemoryAvg
    $check = $HostGroup.ESXIHost 
 
    if(($check -in $InputHostfile.Hosts) -eq $true)
    {
    $namematch = $InputHostfile | where { $_.Hosts -eq $check}
    if($namematch){
    $hgn=$namematch.Host_Group_Name
    }
    $HGName = $hgn
    $allhostgroup.vCenter = $vcenterserver
    $allhostgroup.ESXIHost = "<td>"+$check+"</td>"
    $allhostgroup.Host_Group_name = "<td>"+$HGName+"</td>"
    $allhostgroup.CPUAvg = "<td class=""Redfont""; style=""background-color:#6cc24a"">"+$HostGroup.CPUAvg+" %</td>"
    $allhostgroup.MemoryAvg = "<td class=""Redfont""; style=""background-color:#6cc24a"">"+$HostGroup.MemoryAvg+" %</td>"
    $table3 += $allhostgroup
   
    #Captures in CSV file for ESXIHost Group details
    
    $csv3 = [psCustomObject] [Ordered]@{ 
                         vCenter            = $vCen
                         ESXIHost           = $HostGroup.ESXIHost
                        "Host Group Name"   = [string]$hgn
                         CPUAvg             = $HostGroup.CPUAvg
                         MemoryAvg          = $HostGroup.MemoryAvg                 
                         }
      $csv_file3 += $csv3
    }
} 

if($csv_file3){
    $csv_file3 | Export-Csv -Path $hostgroupcsvPath -NoTypeInformation -UseCulture 
}

#################################### Disconnect from Vcenter ######################################

   write-host "------------------------------------------"
   Disconnect-VIServer $vCen -Confirm:$false
   Write-Host "vCenter $vCen server disconnected"
} 

#ESXIHost Group HTML table

$tabledata3 = '<table class="styled-table">'
    $tabledata3 += '<thead><tr>'
    foreach ($head in "vCenter","ESXIHost","Host_Group_Name","CPUAvg","MemoryAvg"){
        $tabledata3 += '<th>' + $head + '</th>'
    }
    $tabledata3 += '</tr></thead>'
    $tabledata3 += '<tbody>'
    foreach($row2 in $table3){
    if($row2.ESXIHost){
        $tabledata3 += '<tr>'
        $tabledata3 += $vcenterserver
        $tabledata3 += $row2.ESXIHost
        $tabledata3 += $row2.Host_Group_Name
        $tabledata3 += $row2.CPUAvg
        $tabledata3 += $row2.MemoryAvg
        $tabledata3 += '</tr>'
       }
       }
    $tabledata3 += '</tbody>'
    $tabledata3 += '</table>'


########################################### Define the Html ########################################
 
   $HtmlStyle = @"
<style>
TABLE {width: 100%;border-width: 1px;border-style: solid;border-color: white;border-collapse: collapse;}
TH {border-width: 1px;padding: 3px;border-style: solid;border-color: black;background-color: #5F249F;color: #ffffff;}
TD {border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
tr {border-bottom: 1px solid #dddddd;}
tr:nth-of-type(even) {background-color: #f3f3f3;}
tr:last-of-type {border-bottom: 2px solid #5F249F;}
.logo { width:110; height:50;}
</style>
"@


$html ="<html>
$HtmlStyle

<head>
<meta name='viewport' content='width=device-width, initial-scale=1'>
<title>MPC- Monthly Capacity Report</title>


<nav class='navbar sticky-top navbar-dark' style='background-color: #5F249F;'>
<center><a class='navbar-brand'><h2 style=color:white> Monthly Capacity Report for MPC Environment</h2></a></center>
<left><h4>$date</h4></left>
<img align=right src=""https://1000logos.net/wp-content/uploads/2021/10/CIBC-Logo.png"" class=logo>
</nav>

<img src=""data:image/png;base64,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"" />

<center><h3>Clusterwise Report</h3></center>
$tabledata1
<center><h3>ESXIHostwise Report</h3></center>
$tabledata2
<center><h3>ESXIHost Group Details Report</h3></center>
$tabledata3


</html>" 

$html > $reportname

############################################ Sending Email ############################################

Send-MailMessage -From $From -to $To -Subject "Monthly Capacity Report for MPC Environment" -Cc $Cc -Body "Attachment of output HTML Report and CSV files" -BodyAsHtml -SmtpServer $SMTPServer -port $SMTPPort -Attachments $reportname, $clustercsv, $hostcsv, $hostgroupcsvPath

#######################################################################################################

Write-Host "Script execution completed..!"

#######################################################################################################

Stop-Transcript

########################################## END OF SCRIPT ##############################################