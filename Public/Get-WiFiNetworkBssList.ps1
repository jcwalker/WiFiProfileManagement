<#
    .SYNOPSIS
        Retrieves a list of the basic service set (BSS) entries of the wireless network or networks on a given wireless LAN interface.

    .PARAMETER WiFiAdapterName
        Specifies the name of the wireless network adapter on the machine. This is used to obtain the Guid of the interface.
        The default value is 'Wi-Fi'

    .PARAMETER InvokeScan
        Switch so a scan is ran to discover additional wireless networks.

    .EXAMPLE
        Get-WifiNetworkBssList

        SSID             PhyId APMacAddress        Dot11BssType RSSI LinkQuality InRegulatoryDomain BeaconPeriod     TimeStamp      HostTimeStamp
        ----             ----- ------------        ------------ ---- ----------- ------------------ ------------     ---------      -------------
        SpectrumSetup-4A     0 0C-73-29-E0-7A-4B Infrastructure  -91          14               True            0 3244164813477 133399628005404767
        Spectrum Mobile      0 86-97-33-11-60-6D Infrastructure  -91          14               True            0 2068856218275 133399627979117712
        SpectrumSetup-4A     0 46-EB-42-E5-46-70 Infrastructure  -81          35               True            0  929857743696 133399627970981871
                             0 56-EB-42-E5-46-70 Infrastructure  -81          35               True            0  929857743335 133399627970981871
                             0 36-EB-42-E5-46-70 Infrastructure  -82          33               True            0  929857742974 133399627970981871
                             0 22-EF-BD-52-06-C5 Infrastructure  -72          62               True            0 1395138969665 133399627972633616
        VR217-F122           0 7C-8B-CA-3B-F1-22 Infrastructure  -87          22               True            0 3950632387792 133399627972078465
                             0 8E-73-29-E0-7A-4C Infrastructure  -78          43               True            0 3244161846928 133399627976111064
        SpectrumSetup-4A     0 0C-73-29-E0-7A-4C Infrastructure  -81          35               True            0 3244161843584 133399627976111064
                             0 7E-73-29-E0-7A-4C Infrastructure  -76          50               True            0 3244161844093 133399627976111064
#>
function Get-WifiNetworkBssList
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $WiFiAdapterName,

        [Parameter()]
        [switch]
        $InvokeScan
    )

    try
    {
        if ($InvokeScan.IsPresent)
        {
            Search-WiFiNetwork -WiFiAdapterName $WiFiAdapterName
            # docs says Windows certified wifi drivers should complete a scan in 4 seconds
            # probably should figure out how to do this the right way
            Start-Sleep -Seconds 4
        }

        $networkList = @()
        $interfaceInfo = Get-InterfaceInfo -WiFiAdapterName $WiFiAdapterName
        $clientHandle = New-WiFiHandle
        $ssid = [System.IntPtr]::zero
        $dot11BssType = [WiFi.ProfileManagement+DOT11_BSS_TYPE]::Any

        foreach ($interface in $interfaceInfo)
        {
            $bssListPointer = [System.IntPtr]::zero
            $result = [WiFi.ProfileManagement]::WlanGetNetworkBssList(
                $clientHandle,
                $interface.InterfaceGuid,
                $ssid,
                $dot11BssType,
                $false,
                [System.IntPtr]::zero,
                [ref] $bssListPointer
            )

            if ($result -ne 0)
            {
                $errorMessage = Format-Win32Exception -ReturnCode $result
                throw $($script:localizedData.ErrorGetNetworkBssList -f $errorMessage)
            }

            $bssEntries = [WiFi.ProfileManagement+WLAN_BSS_LIST]::new($bssListPointer)
            $pointerCollection += $bssListPointer

            foreach ($bssEntry in $bssEntries.wlanBssEntries)
            {
                $networkList += Format-BssEntry -BssEntry $bssEntry
                #$networkList += Add-DefaultProperty -InputObject $bssResult -InterfaceInfo $interface
            }
        }

        $networkList
    }
    catch
    {
        $PSItem
    }
    finally
    {
        Invoke-WlanFreeMemory -Pointer $pointerCollection

        if ($clientHandle)
        {
            Remove-WiFiHandle -ClientHandle $clientHandle
        }
    }
}
