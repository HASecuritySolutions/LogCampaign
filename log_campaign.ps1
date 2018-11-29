param(
    [switch]$AlwaysOutput=$True,
    [alias("d")][string]$Destination="evtx",
    [alias("p")][ValidateRange(1,65535)][int32]$DestinationPort=514,
    [string]$DestinationServer,
    [string]$TransportType="udp",
    [alias("e")][string]$EventID=100,
    [alias("t")][string]$LogType="json",
    [alias("f")][string]$File,
    [alias("o")][string]$OutputDirectory=$(get-location).Path,
    [alias("s")][int32]$Schedule=0,
    [string]$Header="",
    [alias("j")][switch]$JSON=$True,
    [alias("a")][switch]$AutoFormat=$True,
    [string]$Delimeter="",
    [alias("c")][string]$Campaign,
    [switch]$Diff=$False,
    [alias("l")][switch]$ListCampaigns=$False,
    [alias("h")][switch]$Help=$False,
    [switch]$Debug=$False
)
if($Help){
    Write-Host '
Log Campaign Options: Powershell Version
    
-AlwaysOutput -a                Always generate a log per campaign [default: True]
-Destination -d <destination>   The logging destination (evtx, file, or syslog) [default: evtx]
-DestinationPort -p <port>      The destination port if syslog [default: 514]
-DestinationServer <server>     The destination host or IP if syslog
-TransportType <udp or tcp>     If syslog is selected specify UDP or TCP [default: udp]
-EventID -e <id>                The destination event ID if evtx [default: 100]
-LogType -t <type>              The log format (json or text) [default: json]
-File -f <file>                 The log file to process
-OutputDirectory -o <directory> The output path for saved files [default: current directory]
-Schedule -s <time-schedule>    How often to run the script in minutes [default: 0]
-Campaign -c <1,2,3>            The log detection campaign(s) to execute, comma seperated
-ListCampaigns -l               Lists supported campaigns
-Diff                           If enabled only records differences [default: Disabled]
-Help -h                        Display this help message

If using Syslog to send logs, Posh-Syslog is required. The script will attempt to install this
or you can manually download and copy the module to machines. Also, you can run the following command
to install it:

Install-Module -Name Posh-Syslog -Force:$true

If -Schedule is set to 0 it only runs once. -Schedule only is supported for Campaigns
'
    break
}
$LogCampaignDirectory = "." # Defaults to current directory
$script:EventID = $EventID
$script:Destination = $Destination
$script:File = $File
$script:LogType = $LogType
$script:Header = $Header
$script:JSON = $JSON
$script:Delimeter = $Delimeter
$script:DestinationServer = $DestinationServer
$script:DestinationPort = $DestinationPort
$script:TransportType = $TransportType
$script:Diff = $Diff
$script:Source = "CustomLogs"
$script:OutputDirectory = $OutputDirectory
. "$LogCampaignDirectory\GlobalFunctions.ps1"
. "$LogCampaignDirectory\Prerequisites.ps1"
$script:LogCampaignDirectory = $LogCampaignDirectory
$script:Architecture = $ENV:PROCESSOR_ARCHITECTURE
$ModulePath = $(get-location).Path + "\Modules"
if($ListCampaigns){
    Write-Host "Campaign`t`t`tDescription"
    Write-Host "--------`t`t`t-----------------"
    Get-ChildItem -Path $ModulePath | ForEach-Object {
        if(($_.Name).Length -le 15){
            ($_.Name).Replace(".ps1","`t`t`t") + (Get-Content $_.FullName -First 1).Replace("# ","")
        } elseif(($_.Name).Length -ge 20) {
            ($_.Name).Replace(".ps1","`t") + (Get-Content $_.FullName -First 1).Replace("# ","")
        } elseif(($_.Name).Length -ge 16) {
            ($_.Name).Replace(".ps1","`t`t") + (Get-Content $_.FullName -First 1).Replace("# ","")
        }
    }
} else {
    if(!($script:File) -and !($Campaign)){
        Write-Host "The -File or -Campaign parameter are required. Please specify one to continue"
        break
    }
    if($script:File -and $Campaign){
        Write-Host "This script does not support using -File and -Campaign at the same time."
        Write-Host "Please choose one to continue"
    }
}

# Run campaign(s)
if($Campaign){
    if($Campaign -eq "all"){
        $Campaigns = @()
        Get-ChildItem -Path $ModulePath | ForEach-Object {
            $Campaigns += ($_.Name).Replace('.ps1',"")
        }
    } else {
        $Campaigns = $Campaign -split ","
    }
    # Invoke schedule
    $run = 1
    while($run -eq 1){
        $time = Get-Date
        foreach($Campaign in $Campaigns){
            $FunctionName = "Campaign-$Campaign"
            . $ModulePath\$Campaign
            & $FunctionName
        }
        if($Schedule -eq 0){
            $run = 0
        } else {
            do { Sleep -Seconds 60 }
            until (([datetime]::now - $time).Minutes -ge $Schedule)
        }
    }
}
# Custom log a file
if($script:File -ne "" -and $script:File){
    if($AutoFormat){
        Get-FileFormat $File
    }
    if(Test-Path $File){
        try {
            if($script:Delimeter -ne ""){
                if($script:Header -ne ""){
                    if($script:Header -eq "top"){
                        $content = import-csv -Delimiter $script:Delimeter -Path $script:File
                    } else {
                        $content = import-csv -Delimiter $script:Delimeter -Path $script:File -Header $script:Header
                    }
                } else {
                    $content = import-csv -Delimiter $script:Delimeter -Path $script:File
                }
            } elseif($script:JSON){
                $content = Get-Content -Path  $script:File | ConvertFrom-Json
            } else {
                $content = Get-Content -Path $script:File
            }
            foreach($line in $content){
                Generate-Log "CustomLog" 0 $line
            }
        }
        catch {
            Write-Host "Unable to read file contents from $script:File"
        }
    } else {
        Write-Host "File at $File is unreadable"
        break
    }
}