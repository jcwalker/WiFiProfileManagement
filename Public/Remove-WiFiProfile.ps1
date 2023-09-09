<#
    .SYNOPSIS
        Deletes a WiFi profile.
    .PARAMETER ProfileName
        The name of the profile to be deleted. Profile names are case-sensitive.
    .PARAMETER WiFiAdapterName
        Specifies the name of the wireless network adapter on the machine. This is used to obtain the Guid of the interface.
        The default value is 'Wi-Fi'
    .EXAMPLE
    PS C:\>Remove-WiFiProfile -ProfileName FreeWiFi

    This examples deletes the FreeWiFi profile.
#>
function Remove-WiFiProfile
{
    [CmdletBinding(SupportsShouldProcess = $true, ConfirmImpact = 'High')]
    Param
    (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
        [System.String[]]
        $ProfileName,

        [Parameter(Position = 1)]
        [System.String]
        $WiFiAdapterName
    )

    begin
    {
        if (!$WiFiAdapterName)
        {
            $interfaceGuid = (Get-WiFiInterface).Guid
        }
        else
        {
            $interfaceGuid = Get-WiFiInterfaceGuid -WiFiAdapterName $WiFiAdapterName
        }
    }
    process
    {
        try
        {
            $clientHandle = New-WiFiHandle

            foreach ($wiFiProfile in $ProfileName)
            {
                if ($PSCmdlet.ShouldProcess("$($script:localizedData.ShouldProcessDelete -f $WiFiProfile)"))
                {
                    $deleteProfileResult = [WiFi.ProfileManagement]::WlanDeleteProfile(
                        $clientHandle,
                        $interfaceGUID,
                        $wiFiProfile,
                        [IntPtr]::Zero
                    )

                    $deleteProfileResultMessage = Format-Win32Exception -ReturnCode $deleteProfileResult

                    if ($deleteProfileResult -ne 0)
                    {
                        Write-Error -Message ($script:localizedData.ErrorDeletingProfile -f $deleteProfileResultMessage)
                    }
                    else
                    {
                        Write-Verbose -Message $deleteProfileResultMessage
                    }

                }
            }
        }
        catch
        {
            Write-Error $PSItem
        }
        finally
        {
            if ($clientHandle)
            {
                Remove-WiFiHandle -ClientHandle $clientHandle
            }
        }
    }
}
