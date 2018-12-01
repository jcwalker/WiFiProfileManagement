<#
    .SYNOPSIS
        Call the WlanConnect function to attempt to connect to a specific network
    .PARAMETER InterfaceGuid
        Specifies the Guid of the wireless network card. This is required by the native WiFi functions.
    .PARAMETER ClientHandle
        Specifies the handle used by the native WiFi functions.
    .PARAMETER ConnectionParameterList
        A WLAN_CONNECTION_PARAMETERS structure that specifies the parameters used when using the WlanConnect function.
#>
function Invoke-WlanConnect
{
    [OutputType([void])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.IntPtr]
        $ClientHandle,

        [Parameter(Mandatory = $true)]
        [System.Guid]
        $InterfaceGuid,

        [Parameter(Mandatory = $true)]
        [WiFi.ProfileManagement+WLAN_CONNECTION_PARAMETERS]
        $ConnectionParameterList
    )

    $result = [WiFi.ProfileManagement]::WlanConnect(
        $ClientHandle,
        [ref]$InterfaceGuid,
        [ref]$ConnectionParameterList,
        [IntPtr]::Zero
    )

    if ($result -ne 0)
    {
        $errorMessage = Format-Win32Exception -ReturnCode $result
        throw $($script:localizedData.ErrorWlanConnect -f $ConnectionParameterList.strProfile, $errorMessage)
    }
    else
    {
        $errorMessage = Format-Win32Exception -ReturnCode $result
        Write-Verbose -Message $($script:localizedData.SuccessWlanConnect -f $ConnectionParameterList.strProfile, $errorMessage)
    }
}
