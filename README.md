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

## Set-WiFiProfile
* **ProfileName**: The name of the WiFi profile to modify.
* **ConnectionMode**: Indicates whether connection to the wireless LAN should be automatic ("auto") or initiated ("manual") by user.
* **Authentication**: Specifies the authentication method to be used to connect to the wireless LAN.
* **Encryption**: Sets the data encryption to use to connect to the wireless LAN.
* **Password**: The network key or passpharse of the wireless profile in the form of a secure string.
* **XmlProfile**: The XML representation of the profile. 

## New-WiFiProfile
* **ProfileName**: The name of the new WiFi profile.
* **ConnectionMode**: Indicates whether connection to the wireless LAN should be automatic ("auto") or initiated ("manual") by user.
* **Authentication**: Specifies the authentication method to be used to connect to the wireless LAN.
* **Encryption**: Sets the data encryption to use to connect to the wireless LAN.
* **Password**: The network key or passpharse of the wireless profile in the form of a secure string.
* **XmlProfile**: The XML representation of the profile. 

## Versions

### Unreleased

### 0.1.0.0
*    Initial released with the following functions
     * Get-WiFiProfile
     * Remove-WiFiProfile

### 0.1.1.0
*    Added formating

### 0.2.1.0
*    Added Set-WiFiProfile

### 0.3.0.0
*    Added New-WiFiProfile

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

### Updating a wireless profile
```PowerShell
        PS C:\>$password = Read-Host -AsSecureString
        **********

        PS C:\>Set-WiFiProfile -ProfileName MyNetwork -ConnectionMode auto -Authentication WPA2PSK -Encryption AES -Password $password
```

### Updating a wireless profile using the XmlProfile parameter.
```PowerShell
        PS C:\>$templateProfileXML = @"
        <?xml version="1.0"?>
        <WLANProfile xmlns="http://www.microsoft.com/networking/WLAN/profile/v1">
            <name>MyNetwork</name>
            <SSIDConfig>
                <SSID>            
                    <name>MyNetwork</name>
                </SSID>
            </SSIDConfig>
            <connectionType>ESS</connectionType>
            <connectionMode>manual</connectionMode>
            <MSM>
                <security>
                    <authEncryption>
                        <authentication>WPA2PSK</authentication>
                        <encryption>AES</encryption>
                        <useOneX>false</useOneX>
                    </authEncryption>
                    <sharedKey>
                        <keyType>passPhrase</keyType>
                        <protected>false</protected>
                        <keyMaterial>password1</keyMaterial>
                    </sharedKey>
                </security>
            </MSM>
        </WLANProfile>
        "@

        PS C:\>Set-WiFiProfile -XmlProfile $templateProfileXML
```

### Creating a wireless profile
```PowerShell
        PS C:\>$password = Read-Host -AsSecureString
        **********

        PS C:\>New-WiFiProfile -ProfileName MyNetwork -ConnectionMode auto -Authentication WPA2PSK -Encryption AES -Password $password
```
