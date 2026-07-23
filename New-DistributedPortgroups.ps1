$vcenter = Read-host "What is the FQDN of your vCenter?"
$creds = Get-Credential

Connect-VIServer $vcenter -Credential $creds

$csv = Import-Csv "C:\users\mhargreaves\Downloads\vdsportgroups.csv"


# Loop through and deploy directly to VDS
$csv | ForEach-Object {
    $vds = Get-VDSwitch -Name $_.vdsName -ErrorAction SilentlyContinue
    if (-not $vds) { Write-Warning "Switch $($_.vdsName) not found"; return }

    # Inline check and port group creation
    if (Get-VDPortgroup -VDSwitch $vds -Name $_.PortGroup -ErrorAction SilentlyContinue) {
        Write-Host "Skipped: Portgroup $($_.PortGroup) already exists." -ForegroundColor Yellow
    } else {
        New-VDPortgroup -Name $_.PortGroup -VDSwitch $vds -VlanId ($_.VlanID) | Out-Null
        Write-Host "Created: $($_.PortGroup) on $($_.vdsName)" -ForegroundColor Green
    }
}

Disconnect-VIServer -Confirm:$false