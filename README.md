# WiFiProfileManagement
Module used for management of wireless profiles.

This module leverages the native WiFi functions.  I wanted to learn more about interoperability and have a PowerShell way to view passwords of WiFi profiles so I decided to work
on this in my free time.  Any feedback on how this module can be improved is welcome.

## How to use 
Drop the root folder in your PSModulePath, remove the branch name (ex. -dev )from the folder, and PowerShell should find the module.

## Functions
* **Get-WiFiProfile** Retrieves the information of a WiFi profile.
* **Remove-WiFiProfile** Deletes a WiFi profile.

## Get-WiFiProfile
* **ProfileName**: The name of the WiFi profile.
* **WiFiAdapterName**: Specifies the name of the wireless network adapter on the machine. This is used to obtain the Guid of the interface. The default value is 'Wi-Fi'
* **ClearKey**: Specifies if the password of the profile is to be returned.

## Versions

### Unreleased

### 1.0.0.0
*    Initial released with the following functions
     * Get-WiFiProfile
     * Remove-WiFiProfile

### 1.0.1.0
*    Added formating

## Examples

### Get the WiFi profile information on wireless profile TestWifi
```PowerShell
PS C:\>Get-WiFiProfile -ProfileName TestWiFi

        ProfileName    : TestWiFi
        ConnectionMode : auto
        Authentication : WPA2PSK
        Encyption      : AES
        Password       : 
```

### Obtaining the password for wireless profile TestWifi
```PowerShell
        PS C:\>Get-WiFiProfile -ProfileName TestWiFi -ClearKey

        ProfileName    : TestWiFi
        ConnectionMode : auto
        Authentication : WPA2PSK
        Encyption      : AES
        Password       : password1
```

### Deleting a WiFi profile
```PowerShell
PS C:\>Remove-WiFiProfile -ProfileName FreeWifi
```
