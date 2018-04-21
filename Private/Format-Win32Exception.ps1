<#
    .SYNOPSIS
        Returns the exception message from a Win32 API call
    .PARAMETER ReturnCode
        Specifies the return code that will be resolved to an error message.
#>
function Format-Win32Exception
{
    [OutputType([System.String])]
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [System.Int32]
        $ReturnCode
    )

    return [System.ComponentModel.Win32Exception]::new($ReturnCode).Message
}
