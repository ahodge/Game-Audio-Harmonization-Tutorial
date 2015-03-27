using UnityEngine;
using System.Collections;
using System.Runtime.InteropServices;

public class nativeManager {

	[DllImport("__Internal")]
	private static extern void _openMusicLibrary();
	
	public static void openMusic()
	{
		if(Application.platform == RuntimePlatform.IPhonePlayer )
			_openMusicLibrary();
	}


	[DllImport("__Internal")]
	private static extern void _doStartRain();
	
	public static void startRain()
	{
		if (Application.platform == RuntimePlatform.IPhonePlayer)
			_doStartRain ();
	}
	
	[DllImport("__Internal")]
	private static extern void _doStopRain();
	
	public static void stopRain()
	{
		if (Application.platform == RuntimePlatform.IPhonePlayer)
			_doStopRain ();
	}
	
	[DllImport("__Internal")]
	private static extern void _doFlyingBotFire();
	
	public static void FlyingBotFire()
	{
		if (Application.platform == RuntimePlatform.IPhonePlayer)
			_doFlyingBotFire ();
	}
	
	[DllImport("__Internal")]
	private static extern void _doTritone();
	
	public static void tritone()
	{
		if (Application.platform == RuntimePlatform.IPhonePlayer)
			_doTritone ();
	}

}
