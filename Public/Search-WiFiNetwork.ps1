<#
    .SYNOPSIS
        Requests a scan for available networks on the indicated interface.
#>
function Search-WiFiNetwork
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $WiFiAdapterName,

        [Parameter()]
        [Switch]
        $Wait
    )

    <#
        The application should first register for WLAN_NOTIFICATION_SOURCE_ACM notifications.
        The WlanScan function can then be called to initiate a scan.
        The application should then wait to receive the wlan_notification_acm_scan_complete notification or timeout after 4 seconds.
        Then the application can call the WlanGetNetworkBssList or WlanGetAvailableNetworkList function to retrieve a list of available wireless networks.
        This process can be repeated periodically with the application keeping tracking of changes to available wireless networks.
    #>
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

        # register for notification
        if ($Wait)
        {
            $context = [intptr]::zero
            $notificationData = [WiFi.ProfileManagement+WLAN_NOTIFICATION_DATA]::new()
            #$callBack = [WiFi.ProfileManagement+WLAN_NOTIFICATION_CALLBACK]::new([ref]$notificationData, $context)
            $source = [WiFi.ProfileManagement+WLAN_NOTIFICATION_SOURCE]::ACM

            $registerResultCode = [WiFi.ProfileManagement]::WlanRegisterNotification(
                $clientHandle,
                [WiFi.ProfileManagement+WLAN_NOTIFICATION_SOURCE]::ACM,
                $true,
                [WiFi.ProfileManagement+WLAN_NOTIFICATION_CALLBACK]::new([ref]$notificationData, $context),
                [intPtr]::zero,
                [intPtr]::zero,
                [ref]$source
            )
        }

        foreach ($interfaceGuid in $interfaceGuids)
        {
            $resultCode = [WiFi.ProfileManagement]::WlanScan(
                $clientHandle,
                [ref] $interfaceGuid,
                [IntPtr]::zero, #null
                [IntPtr]::zero, #null
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
