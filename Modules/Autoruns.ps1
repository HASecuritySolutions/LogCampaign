# Runs Microsoft Sysinternals Autoruns and logs results [Supports: diff]. Has prerequisite
# Prerequisite - You must have autorunsc.exe downloaded and in the binary folder
function Campaign-Autoruns {
    if($script:Architecture -eq "AMD64"){
        $path = "$script:LogCampaignDirectory\Binaries\autorunsc64.exe"
    } else {
        $path = "$script:LogCampaignDirectory\Binaries\autorunsc.exe"
    }
    if(Test-Path -Path $path){
        #Remove-Item -Force -Path "$script:OutputDirectory\autoruns.csv.old" -ErrorAction SilentlyContinue | Out-Null
        if(Test-Path -Path "$script:OutputDirectory\autoruns.csv"){
            Move-Item -Force -Path "$script:OutputDirectory\autoruns.csv" -Destination "$script:OutputDirectory\autoruns.csv.old"
            $PreviousAutoruns = Import-Csv -Path "$script:OutputDirectory\autoruns.csv.old" -Delimiter "`t"
            $PreviousAutoruns = $PreviousAutoruns
        }
        & $path "-accepteula" "-ct" "-o" "$script:OutputDirectory\autoruns.csv" "-h" "-s" "-t"
        $CurrentAutoruns = Import-Csv -Path "$script:OutputDirectory\autoruns.csv" -Delimiter "`t"
        $properties = $CurrentAutoruns[0].psobject.properties.name

        if($script:Diff){
            $content = Compare-Object -ReferenceObject $CurrentAutoruns -DifferenceObject $PreviousAutoruns -Property "Entry Location" -PassThru | Where-Object { $_.SideIndicator -eq '<=' }
            if($Debug){
                Write-Host "Debug - content difference is below:"
                $content
            }
        } else {
            $content = $CurrentAutoruns
        }
        foreach($record in $content){
            $record.PSObject.Properties.Remove('SideIndicator')
            if($script:LogType -eq "text"){
                $Log = $record | ConvertTo-Csv -Delimiter "`t"
            }
            if($script:LogType -eq "json"){
                $Log = $record | ConvertTo-Json -Compress
            }
            if($Debug){
                Write-Host "Debug - Log generated is:"
                $Log
            }    
            Generate-Log "Autoruns" 0 $Log
        }
    } else {
        Write-Host "autorunsc.exe not found in Binaries folder. Unable to run campaign"
    }
}
