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

    Add-Member -InputObject $InputObject -MemberType 'NoteProperty' -Name 'WiFiAdapter' -Value $InterfaceInfo.Name -Force
    Add-Member -InputObject $InputObject -MemberType 'NoteProperty' -Name 'InterfaceGuid' -Value $InterfaceInfo.InterfaceGuid -Force

    return $InputObject
}
