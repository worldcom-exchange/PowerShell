$vcenter = Read-host "What is the FQDN of your vCenter?"
$creds = Get-Credential

Connect-VIServer $vcenter -Credential $creds

$cluster = Read-host "What is the name of your cluster?"
$csv = Import-Csv "C:\users\mhargreaves\Downloads\portgroups.csv"
$VMhosts = Get-Cluster -Name $cluster | Get-VMHost

#Group portgroups by switch object.  Prevents errors for Switch already created
$csvSwitchName = $csv | Group-Object -Property vSwitchName


#Looping through hosts in the cluster
foreach ($VMhost in $VMhosts) {

    #create standard switches
    foreach ($csvSwitch in $csvSwitchName) {

        $vss = $csvSwitch.name

        $vSwitch = New-VirtualSwitch -VMHost $VMhost -Name $vss
        Write-Host "  [+] Created vSwitch: $vss" -ForegroundColor Green
        $vSwitchName = vSwitch0
        $pnic = vmnic1
        Get-VirtualSwitch -VMHost $VMhost -Name $vSwitchName | Add-VirtualSwitchPhysicalNetworkAdapter -PhysicalNic $pnic
            #create portgroups on standard switch
            foreach ($row in $csvSwitch.Group) {
                $pg = $row.PortGroup
                $vlan = $row.VlanID
            
                New-VirtualPortGroup -VirtualSwitch $vSwitch -Name $pg -VLanId $vlan
                Write-Host "    -> Created Port Group: $pg (VLAN $vlan)" -ForegroundColor Green
            }
    }
}
