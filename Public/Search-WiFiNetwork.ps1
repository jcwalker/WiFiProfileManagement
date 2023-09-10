<#
    .SYNOPSIS
        Requests a scan for available wifi networks on the indicated interface.
        The scan is requested by calling the WlanScan function in the WlanApi

    .PARAMETER WiFiAdapterName
        Specifies the name of the wireless network adapter on the machine. This is used to obtain the Guid of the interface.
        The default value is 'Wi-Fi'

    .EXAMPLE
        Search-WiFiNetwork -WiFiAdapterName WiFi

        This examples will search for WiFi networks on the WiFi adapter.
#>
function Search-WiFiNetwork
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $WiFiAdapterName
    )

    try
    {
        $interfaceInfo = Get-InterfaceInfo -WiFiAdapterName $WiFiAdapterName

        $clientHandle = New-WiFiHandle

        foreach ($interface in $interfaceInfo)
        {
            $resultCode = [WiFi.ProfileManagement]::WlanScan(
                $clientHandle,
                [ref] $interface.InterfaceGuid,
                [IntPtr]::zero,
                [IntPtr]::zero,
                [IntPtr]::zero
            )

            if ($resultCode -ne 0)
            {
                $resultCode
            }
        }
    }
    catch
    {
        $PSItem
    }
    finally
    {
        if ($clientHandle)
        {
            Remove-WiFiHandle -ClientHandle $clientHandle
        }
    }
}
