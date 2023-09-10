<#
    .SYNOPSIS
        Adds WifiAdapterName and InterfaceGuid to all the objects that are returned.

    .PARAMETER $InputObject
        The object the two properties will be added to.

    .PARAMETER InterfaceInfo
        The interfaceInfo object that the WiFiAdapterName and InterfaceGuid come from.
#>
function Add-DefaultProperty
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [object]
        $InputObject,

        [Parameter(Mandatory)]
        [object]
        $InterfaceInfo
    )

    Add-Member -InputObject $InputObject -MemberType 'NoteProperty' -Name 'WiFiAdapterName' -Value $InterfaceInfo.Name -Force
    Add-Member -InputObject $InputObject -MemberType 'NoteProperty' -Name 'InterfaceGuid' -Value $InterfaceInfo.InterfaceGuid -Force

    return $InputObject
}
