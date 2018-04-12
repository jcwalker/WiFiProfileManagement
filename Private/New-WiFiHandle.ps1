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

    $handle = [WiFi.ProfileManagement]::WlanOpenHandle($maxClient,[IntPtr]::Zero,$negotiatedVersion,[ref]$clientHandle)
    
    if ($handle -eq 0)
    {
        return $clientHandle
    }
    else
    {
        throw $($Script:localizedData.ErrorOpeningHandle)
    }        
}
