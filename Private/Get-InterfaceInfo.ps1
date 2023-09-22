#let return guid and adaptor description
function Get-InterfaceInfo
{
    [CmdletBinding()]
    param
    (
        [Parameter()]
        [System.String]
        $WiFiAdapterName
    )

    $result = @()
    $wifiAdapters = @()
    $getNetAdapterParams = @()

    $wifiInterfaces = Get-WiFiInterface

    if (!$WiFiAdapterName)
    {
        foreach ($wifiInterface in $wifiInterfaces)
        {
            $getNetAdapterParams +=@(
                 @{InterfaceDescription = $wifiInterface.Description}
            )
        }
    }
    else
    {
        $getNetAdapterParams = @(
            @{Name = $WiFiAdapterName}
        )
    }

    foreach ($getNetAdapterParam in $getNetAdapterParams)
    {
        $wifiAdapters = Get-NetAdapter @getNetAdapterParam
    }

    # ensure we are using wifi adaptors
    foreach ($wifiAdapter in $wifiAdapters)
    {
        if ($wifiAdapter.InterfaceGuid -notin $wifiInterfaces.Guid)
        {
            Write-Error -Message ($script:localizedData.ErrorNotWiFiAdapter -f $wifiAdapter.Name)
        }
        else
        {
            $result += $wifiAdapter
        }
    }

    if ($result.Count -eq 0)
    {
        throw $script:localizedData.ErrorNoWiFiAdaptersFound
    }
    return $result
}
