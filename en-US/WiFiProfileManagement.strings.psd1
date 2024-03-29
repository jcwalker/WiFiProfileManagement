
ConvertFrom-StringData @'
    ErrorOpeningHandle   = Error opening WiFi handle. Message {0}
    HandleClosed         = Handle successfully closed.
    ErrorClosingHandle   = Error closing handle. Message {0}
    ErrorGettingProfile  = Error getting profile info. Error code: {0}
    ProfileNotFound      = Profile {0} not found. Note ProfileName is case sensitive.
    ErrorDeletingProfile = Error deleting profile. Message {0}
    ShouldProcessDelete  = Deletion of profile {0}
    ErrorWlanConnect     = Error connecting to {0} : {1}
    SuccessWlanConnect   = Successfully connected to {0} : {1}
    ErrorReasonCode      = Failed to format reason code. Error message: {0}
    ErrorFreeMemory      = Failed to free memory. Error message: {0}
    ErrorGetAvailableNetworkList = Error invoking WlanGetAvailableNetworkList. Message {0}
    ErrorWiFiInterfaceNotFound = Wi-Fi interface not found on the system.
    ErrorNotWiFiAdapter  = Adapter with name: {0} is not a WiFi capable.
    ErrorNoWiFiAdaptersFound = No wifi interfaces found.
    ErrorMoreThanOneInterface = More than one Wi-Fi interface found. Please specify a specific interface.
    ErrorNeedSingleAdapterName = More than one Wi-Fi adapter found.  Please specify a single adapter name.
    ErrorFailedWithExitCode = Failed with exit code {0}.
'@
