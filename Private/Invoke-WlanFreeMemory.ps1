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
        [System.IntPtr[]]
        $Pointer
    )

    foreach ($ptr in $Pointer)
    {
        if ($ptr -ne 0)
        {
            try
            {
                [WiFi.ProfileManagement]::WlanFreeMemory($ptr)
            }
            catch
            {
                throw $($script:localizedData.ErrorFreeMemory -f $errorMessage)
            }
        }
    }
}
