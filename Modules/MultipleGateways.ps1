# Identifies if a device has more than one gateway
function Campaign-MultipleGateways {
    if((Get-Gateway).Count -ge 2){
        Generate-Log $Campaign 1 "Multiple default routes found - Possible dual-homed device found"
    } elseif ($AlwaysOutput){
        Generate-Log $Campaign 0 "Device does not have multiple default routes"
    }
}