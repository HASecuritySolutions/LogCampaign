function Get-Gateway {
    Get-WmiObject -Class Win32_IP4RouteTable | Where-Object { $_.destination -eq '0.0.0.0' -and $_.mask -eq '0.0.0.0'} | Sort-Object metric1 | Select-Object -ExpandProperty nexthop
}
function Verify-CustomSourceExists {
    try {
        $output = Get-EventLog -LogName "LogCampaign" -Source $script:Source
        return $True
    }
    catch {
        Write-Host "Creating custom channel and log source"
        New-EventLog -LogName LogCampaign -Source $script:Source
        Write-EventLog -LogName LogCampaign -Source $script:Source -EventId 100 -EntryType Information -Message "LogCampaign channel successfully created"
    }
    try {
        $output = Get-EventLog -LogName "LogCampaign" -Source $script:Source
        return $True
    }
    catch {
        $Error = $_
        $($Error.Exception.Message)
        return $False
    }
}

function Generate-Log($Campaign, $Status, $Message){
    switch($script:LogType){
        "text" {
            $Log = "$Campaign|$Status|$Message"
        }
        "json" {
            $Body = @{ 
                campaign = $Campaign
                status = $Status
                log = $Message
            }
            $Log = $Body | ConvertTo-Json -Compress -Depth 2
        }
    }
    if($Debug){ $Log }
    if($script:Destination -eq "evtx"){
        Write-EventLog -LogName LogCampaign -Source $source -EventId $EventID -EntryType Information -Message $Log
    }
    if($script:Destination -eq "syslog"){
        Send-SyslogMessage -Server $script:DestinationServer -Port $script:DestinationPort -Message $Log -Severity Informational -Facility local7 -Transport $script:TransportType
    }
}
function Get-FileFormat {
    if($script:File -match "\.json$"){
        $script:JSON = $True
        $script:LogType = "json"
        Write-Host 'JSON format found and selected. If you do not want this use -AutoFormat:$false'
    } else {
        $content = Get-Content -Head 1 $script:File
        $PossibleDelimeters = @(",","|","`t")
        $match = 0
        foreach($possibility in $PossibleDelimeters){
           if($content -match ".*\$possibility.*\$possibility.*\$possibility"){
               $script:JSON = $False
               $script:Delimeter = $possibility
               $match = 1
               Write-Host "Delimited file found with $possibility as the delimeter. If you do not want this use " '-AutoFormat:$false'
           } 
        }
        if($match -eq 0){
            $script:JSON = $False
            $script:LogType = "text"
            Write-Host 'Text format found and selected. If you do not want this use -AutoFormat:$false'
        }
    }
}