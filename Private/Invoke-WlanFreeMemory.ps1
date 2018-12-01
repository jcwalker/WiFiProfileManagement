<#
    .SYNOPSIS
        Frees memory used by Native WiFi functions
    .PARAMETER Pointer
        Pointer to the memory to be freed.
#>
function Invoke-WlanFreeMemory
{
    [OutputType([void])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.IntPtr]
        $Pointer
    )

    try
    {
        [WiFi.ProfileManagement]::WlanFreeMemory($Pointer)
    }
    catch
    {
        throw $($script:localizedData.ErrorFreeMemory -f $errorMessage)
    }
}
