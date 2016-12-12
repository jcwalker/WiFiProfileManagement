
$WlanGetProfileListSig = @'   

	[DllImport("wlanapi.dll")]
	public static extern uint WlanOpenHandle(
	    [In] UInt32 clientVersion,
	    [In, Out] IntPtr pReserved,
	    [Out] out UInt32 negotiatedVersion,
	    [Out] out IntPtr clientHandle
    );

    [DllImport("Wlanapi.dll")]
    public static extern uint WlanCloseHandle(
        [In] IntPtr ClientHandle,	    
        IntPtr pReserved        
    );

	[DllImport("wlanapi.dll", SetLastError = true, CallingConvention=CallingConvention.Winapi)]
	public static extern uint WlanGetProfileList(
	    [In] IntPtr clientHandle,
	    [In, MarshalAs(UnmanagedType.LPStruct)] Guid interfaceGuid,
	    [In] IntPtr pReserved,
	    [Out] out IntPtr profileList
	);
    
    [DllImport("wlanapi.dll")]
    public static extern uint WlanGetProfile(
        [In]IntPtr clientHanle,
 	    [In, MarshalAs(UnmanagedType.LPStruct)] Guid interfaceGuid,
        [In, MarshalAs(UnmanagedType.LPWStr)] string profileName,
	    [In, Out] IntPtr pReserved,
        [Out, MarshalAs(UnmanagedType.LPWStr)] out string pstrProfileXml,
        [In, Out, Optional] ref uint flags,
        [Out, Optional] out uint grantedAccess
    );
    
    [DllImport("wlanapi.dll")]
    public static extern uint WlanDeleteProfile(
        [In]IntPtr clientHanle,
        [In, MarshalAs(UnmanagedType.LPStruct)] Guid interfaceGuid,
        [In, MarshalAs(UnmanagedType.LPWStr)] string profileName,
        [In, Out] IntPtr pReserved
    );

    [DllImport("wlanapi.dll", EntryPoint = "WlanFreeMemory")]
    public static extern void WlanFreeMemory(
        [In] IntPtr pMemory
    );

    [DllImport("Wlanapi.dll", SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern uint WlanSetProfile(
        [In] IntPtr clientHanle,
        [In] ref Guid interfaceGuid,
        [In] uint flags,
        [In] IntPtr ProfileXml,
        [In, Optional] IntPtr AllUserProfileSecurity,
        [In] bool Overwrite,
        [In, Out] IntPtr pReserved,
        [In, Out]ref IntPtr pdwReasonCode
    );

    [DllImport("wlanapi.dll",SetLastError = true, CharSet = CharSet.Unicode)]
    public static extern uint WlanReasonCodeToString(
        [In] uint reasonCode,
        [In] uint bufferSize,
        [In, Out] StringBuilder builder,
        [In, Out] IntPtr Reserved
    );

    public struct WLAN_PROFILE_INFO_LIST
    {
        public uint dwNumberOfItems;
        public uint dwIndex;
        public WLAN_PROFILE_INFO[] ProfileInfo;

        public WLAN_PROFILE_INFO_LIST(IntPtr ppProfileList)
        {
            dwNumberOfItems = (uint)Marshal.ReadInt32(ppProfileList);
            dwIndex = (uint)Marshal.ReadInt32(ppProfileList, 4);
            ProfileInfo = new WLAN_PROFILE_INFO[dwNumberOfItems];
            IntPtr ppProfileListTemp = new IntPtr(ppProfileList.ToInt64() + 8);

            for (int i = 0; i < dwNumberOfItems; i++)
            {
                ppProfileList = new IntPtr(ppProfileListTemp.ToInt64() + i * Marshal.SizeOf(typeof(WLAN_PROFILE_INFO)));
                ProfileInfo[i] = (WLAN_PROFILE_INFO)Marshal.PtrToStructure(ppProfileList, typeof(WLAN_PROFILE_INFO));
            }
        }
    }

    [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
    public struct WLAN_PROFILE_INFO
    {
        [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 256)]
        public string strProfileName;
        public WlanProfileFlags ProfileFLags;
    }

    [Flags]
	public enum WlanProfileFlags
	{
	    AllUser = 0,
	    GroupPolicy = 1,
        User = 2
	}

    public class ProfileInfo{
        public string ProfileName;
        public string ConnectionMode;
        public string Authentication;
        public string Encyption;
        public string Password;
        public string Xml;
    }
'@

Add-Type -MemberDefinition $WlanGetProfileListSig -Name ProfileManagement -Namespace WiFi -Using System.Text -PassThru
