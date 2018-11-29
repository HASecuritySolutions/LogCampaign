# Identifies changes to the default gateway's ARP cache [Forces: diff]
function Campaign-ARPCache {
    if(Test-Path -Path "$OutputDirectory\arpcache.txt"){
        $previous_mac = Get-Content -Path "$OutputDirectory\arpcache.txt"
        $previous_mac = [regex]::match($previous_mac,'([0-9a-fA-F]{2}[:-]){5}([0-9a-fA-F]{2})').Groups[0].Value
    } else {
        $previous_mac = ""
    }
    $gateway = Get-Gateway
    $output = (arp -a | findstr $gateway) | Out-String
    $mac = [regex]::match($output,'([0-9a-fA-F]{2}[:-]){5}([0-9a-fA-F]{2})').Groups[0].Value
    if($previous_mac -eq ""){
        $mac | Out-File "$OutputDirectory\arpcache.txt"
    } else {
        if($mac -ne $previous_mac){
            Generate-Log $Campaign 1 "MAC address of default gateway has changed - Possible ARP Cache Poisoning attack"
        } elseif ($AlwaysOutput){
            Generate-Log $Campaign 0 "Gateway MAC address has not changed"
        }
    }
}