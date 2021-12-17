<#
    .SYNOPSIS
        Requests a scan for available wifi networks on the indicated interface.
        The scan is requested by calling the WlanScan function in the WlanApi

    .PARAMETER WiFiAdapterName
        Specifies the name of the wireless network adapter on the machine. This is used to obtain the Guid of the interface.
        The default value is 'Wi-Fi'

    .EXAMPLE
        PS C:\>Search-WiFiNetwork WiFiAdapterName WiFi

        This examples will search for WiFi netowrks on the WiFi adapter.
#>
function Search-WiFiNetwork
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $WiFiAdapterName = 'Wi-Fi'
    )

    try
    {
        if (!$WiFiAdapterName)
        {
            $interfaceGuids = (Get-WiFiInterface).Guid
        }
        else
        { 
            $interfaceGuids = Get-WiFiInterfaceGuid -WiFiAdapterName $WiFiAdapterName
        }

        $clientHandle = New-WiFiHandle

        foreach ($interfaceGuid in $interfaceGuids)
        {
            $resultCode = [WiFi.ProfileManagement]::WlanScan(
                $clientHandle,
                [ref] $interfaceGuid,
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
        Write-Error $PSItem
    }
    finally
    {
        if ($clientHandle)
        {
            Remove-WiFiHandle -ClientHandle $clientHandle
        }
    }
}
