<#
    .SYNOPSIS
        Requests a scan for available networks on the indicated interface.
        The scan is requested by calling the WlanScan function in the WlanApi

    .PARAMETER WiFiAdapterName
        Specifies the name of the WiFi adapter that will be used to search for WiFi networks.

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
        $WiFiAdapterName
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
