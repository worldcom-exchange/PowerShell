# Connect to your vCenter server
$vcenter = Read-host "What is the FQDN of your vCenter?"
$creds = Get-Credential

Connect-VIServer -Server $vcenter -Credential $creds

# Get all ESXi hosts in the vCenter inventory
$allHosts = Get-VMHost

foreach ($vmhost in $allHosts) {
    Write-Host "Processing host: $($vmhost.Name)" -ForegroundColor Green
    
    $standardSwitches = Get-VMHost -Name $vmhost.Name | Get-VirtualSwitch
    
    foreach ($vss in $standardSwitches) {
        Write-Host "Checking switch: $($vss.Name) on $($vmhost.Name)"
        
        # Check for active VMkernel adapters or port groups attached to this switch
        $vmks = Get-VMHost -Name $vmhost.Name | Get-VMHostNetworkAdapter -VMKernel | Where-Object { $_.PortGroup -in $vss.PortGroupName }
        
        if ($vmks) {
            Write-Host "Skipping $($vss.Name): VMkernel adapters are still attached." -ForegroundColor Yellow
        } else {
            try {
                # Remove the standard switch safely
                Remove-VirtualSwitch -VirtualSwitch $vss -Confirm:$false -ErrorAction Stop
                Write-Host "Successfully removed standard switch: $($vss.Name)" -ForegroundColor Green
            } catch {
                Write-Host "Failed to remove $($vss.Name): $_" -ForegroundColor Red
            }
        }
    }
}

Disconnect-VIServer -Confirm:$false