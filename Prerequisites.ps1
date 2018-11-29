if($script:Destination -eq "syslog"){
    if (Get-Module -ListAvailable -Name Posh-Syslog) {
        Import-Module -Name Posh-Syslog
    } else {
        Write-Host "Posh-Syslog is not installed"
        Install-Module -Name Posh-Syslog -Force:$true
        if (Get-Module -ListAvailable -Name Posh-Syslog) {
            Import-Module -Name Posh-Syslog
        } else {
            Write-Host "Posh-Syslog is not installed and auto installation failed"
            exit
        }
    }
}
if($script:Destination -eq "evtx"){
    if(!(Verify-CustomSourceExists)){
        Write-Host "Cannot log to LogCampaign channel as it does not exist and failed to be created"
        Exit
    }
}