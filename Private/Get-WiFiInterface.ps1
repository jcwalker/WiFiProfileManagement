<#
    .SYNOPSIS
        Lists the wireless interfaces and their state.
#>
function Get-WiFiInterface
{
    [CmdletBinding()]
    [OutputType([WiFi.ProfileManagement+WLAN_INTERFACE_INFO])]
    param ()

    $interfaceListPtr = 0
    $clientHandle = New-WiFiHandle

    try
    {
        [void] [WiFi.ProfileManagement]::WlanEnumInterfaces($clientHandle, [IntPtr]::zero, [ref] $interfaceListPtr)
        $wiFiInterfaceList = [WiFi.ProfileManagement+WLAN_INTERFACE_INFO_LIST]::new($interfaceListPtr)

        foreach ($wlanInterfaceInfo in $wiFiInterfaceList.wlanInterfaceInfo)
        {
            [WiFi.ProfileManagement+WLAN_INTERFACE_INFO] $wlanInterfaceInfo
        }
    }
    catch
    {
        Write-Error $PSItem
    }
    finally
    {
        Remove-WiFiHandle -ClientHandle $clientHandle
    }
}
