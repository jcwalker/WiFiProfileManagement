function Format-BssEntry
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory)]
        [object]
        $BssEntry
    )

    $BssEntry | Select-Object -Property @(
        @{Label = 'SSID' ; Expression = {$_.dot11Ssid.ucSSID}}
        @{Label = 'PhyId'; Expression = {$_.phyId}}
        @{Label = 'APMacAddress'; Expression = {[System.BitConverter]::ToString($_.dot11Bssid)}}
        @{Label = 'Dot11BssType'; Expression = {$_.dot11BssType}}
        @{Label = 'RSSI'; Expression = {$_.rssi}}
        @{Label = 'LinkQuality'; Expression = {$_.linkQuality}}
        @{Label = 'InRegulatoryDomain'; Expression = {$_.inRegDomain}}
        @{Label = 'BeaconPeriod'; Expression = {$_.beaconPeriod}}
        @{Label = 'TimeStamp'; Expression = {$_.timestamp}}
        @{Label = 'HostTimeStamp'; Expression = {$_.hostTimestamp}}
        @{Label = 'CapabilityInformation'; Expression = {$_.capabilityInformation}}
        @{Label = 'ChannelCenterFrequency'; Expression = {$_.chCenterFrequency}}
        @{Label = 'WlanRateSet'; Expression = {$_.wlanRateSet}}
        @{Label = 'IEOffset'; Expression = {$_.ieOffset}}
        @{Label = 'IESize'; Expression = {$_.ieSize}}
    )
}
