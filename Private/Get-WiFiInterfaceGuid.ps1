<#
    .SYNOPSIS
        Retrieves the guid of the network interface.
    .PARAMETER WiFiAdapterName
        The name of the wireless network adapter.
#>
function Get-WiFiInterfaceGuid
{
    [CmdletBinding()]
    [OutputType([System.Guid])]
    param 
    (
        [Parameter()]
        [System.String]
        $WiFiAdapterName = 'Wi-Fi'
    )
    
    $osVersion = [Environment]::OSVersion.Version

    if ($osVersion -ge ([Version] 6.2))
    {
        [Guid]$interfaceGuid = (Get-NetAdapter -Name $WiFiAdapterName).interfaceguid
    }
    else
    {
        $wifiAdapterInfo = Get-WmiObject -Query "select Name, NetConnectionID from Win32_NetworkAdapter where NetConnectionID = '$WiFiAdapterName'"
        [Guid]$interfaceGuid = (Get-WmiObject -Query "select SettingID from Win32_NetworkAdapterConfiguration where Description = '$($wifiAdapterInfo.Name)'").SettingID
    }

    return $interfaceGuid
}
