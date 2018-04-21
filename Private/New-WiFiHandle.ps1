<#
    .SYNOPSIS
        Opens a WiFi handle
#>
function New-WiFiHandle
{    
    [CmdletBinding()]
    [OutputType([System.IntPtr])]
    param()

    $maxClient = 2
    [Ref]$negotiatedVersion = 0
    $clientHandle = [IntPtr]::zero

    $result = [WiFi.ProfileManagement]::WlanOpenHandle(
        $maxClient,
        [IntPtr]::Zero,
        $negotiatedVersion,
        [ref]$clientHandle
    )
    
    if ($result -eq 0)
    {
        return $clientHandle
    }
    else
    {
        $errorMessage = Format-Win32Exception -ReturnCode $result
        throw $($script:localizedData.ErrorOpeningHandle -f $errorMessage)
    }
}
