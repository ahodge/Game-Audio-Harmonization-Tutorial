# Game Audio Harmonization Tutorial
## Building a harmonization engine for game audio using Unity 5 and AudioKit 2.0

Languages used: C#, Objective-C

## Overview

This tutorial will guide you through the process of using AudioKit within a Unity iOS project to create procedural sound effects that are harmonized with the game music. The tutorial expects a basic level of familiarity with Unity and its game development environment, as well as Apple's Xcode IDE and Objective-C. The tutorial uses Unity 5.0.0.f4, available at http://www.unity3d.com, Xcode 6.2 available at https://developer.apple.com/xcode/downloads/), and AudioKit 2.0 available at http://www.audiokit.io. AudioKit is an open source iOS library for audio synthesis, processing, and analysis. 

## The demo game: Angry Bots

Angry Bots is a third person shooter game that is available as a free asset on Unity's Asset Store. The gameplay is straightforward. The player must navigate a dark futuristic factory setting in which the automated robot workers of the future have managed to override the first Asimovian law of robotics and have started attacking humans. The game has sound effects bundled with the asset, and while they are well suited for the dark and industrial mood of the game, it can be boring to hear the same static sound effects during repeated play. Angry Bots also does not have any musical component. For this tutorial, we will let the player be the DJ by allowing them choose their own musical soundtrack from their iOS Music library and then harmonize game sound effects with the music!

## Getting Started – Setup and configuration of Unity

If you haven't already, download Unity 5, Xcode, and AudioKit from the links above. Once Unity is installed, create a new 3D project. Open the Unity Asset Store (Window > Asset Store) and download the Angry Bots asset (http://u3d.as/5CF). You will see a warning about Unity 5 compatibility, but don't worry about it for now – it is still playable and useful for rapid prototyping.

![Alt text](http://www.anor.ac/tutorial_images/AngryBots_Incompatibility_Warning.png "Unity 5 has changed a lot under the hood.")

When the asset is done downloading, Unity will present to you an Import window. Make sure all the checkboxes are selected, then go ahead and click “Import” to import the Angry Bots asset into your newly created project.

![Alt text](http://www.anor.ac/tutorial_images/AngryBots_Import.png "Fresh copy of Angry Bots, incoming!")

Once imported, Unity is going to prompt you to run the API updater. Go ahead and do that.

![Alt text](http://www.anor.ac/tutorial_images/AngryBots_API_update.png "The polite API Updater prompt.")


Double click on the AngryBots.unity scene file in the Assets folder of your Unity project. You should now see the game environment appear in Unity's Scene view. Try running the game by clicking the “Play” button at the top center of Unity's window. You should be able to try out the game by moving your character with WASD keys and the mouse. Left click to fire your weapon and blow up some bots. Click the “Play” button again to stop the game and return to the Scene editor view. 

***You'll probably notice that some areas of the environment (parts of the floor, specifically) do not appear to have a texture and appear solid black. This is due some of the aforementioned incompatibilities with Unity 5. If you care about fixing their appearances, you can do so easily by left-clicking on the relevant area in the Scene editor and assigning that game object a new shader value in Unity's Inspector panel. See the screenshot below for an example of how to do this for the circular platform beside the player character at the start of the level. This particular section of the environment is named “polySurface4886” in the Scene's Hierarchy panel, and I've assigned its new shader value of “AngryBots/SimpleSelfIllumination”***

![Alt text](http://www.anor.ac/tutorial_images/AngryBots_screenshot1.png "Certain game objects are appearing completely black. We can fix that...")
![Alt text](http://www.anor.ac/tutorial_images/AngryBots_shader_fix.png "...by tweaking their shader parameters.")

Now that you've familiarized yourself with Angry Bots, let's get down to the business of configuring the Unity project to use Objective-C, the native code of the iOS (and Mac OS X) platforms. (Bonus points will be awarded to any reader that takes it upon themselves to convert this tutorial's native code to Swift!)

## Plugging Unity into AudioKit – plugins bridge the managed-to-native code gap

AudioKit is an iOS specific library – we must find a way to use it within our game. Unity games are usually written in C# or Javascript (commonly referred to as “managed” code). AudioKit wraps the generation of Csound's Music-N style strings in an Objective-C/Swift layer (referred to as “native” code because it is native to the platform that we are going to target with our Unity build). Luckily for us, Unity provides some built in features to help achieve this using plugins.

### Plugin Setup

Unity looks for plugins in a folder called “Plugins” within the project's Assets folder. This folder does not exist in our project yet, so go ahead and create it (Right click in the Project view, then select Create > Folder). Make sure it is named “Plugins” exactly so, without any spaces or other characters. Because this is an iOS plugin, we will also need to create another folder within the newly created Plugins folder, and name the new folder “iOS”, with similar attention to form. Our directory structure should look like this now:

![Alt text](http://www.anor.ac/tutorial_images/AngryBots_Assets_folder.png "A blank canvas for plugin creation.")

You may have noticed already that Unity's current build target for Angry Bots is “PC, Mac, & Linux Standalone”. We want to switch this to target iOS, so navigate to the project's Build Settings (File > Build Settings), select iOS, and click “Switch Platform”. Unity will make the necessary changes under the hood and should display a progress bar as this occurs. This part may take a while, so use this time to add music to your iOS device via iTunes if you haven't already. 

![Alt text](http://www.anor.ac/tutorial_images/AngryBots_BuildSettings.png "We are building to iOS today.")

Unity will prompt you to run the API updater again. We are happy to comply. Once the platform has been switched and code updated, we can carry on with building the plugin.

### Picking a song from the iOS Music Library 

Before we can get into the really cool stuff – procedurally generating sound effects that are harmonized with the game music – we still need to allow the player to choose a song! We will make use of MPMediaPickerController, a native iOS class that handles user interaction and selection of media from an iOS device's library. For the sake of simplicity, we will launch an instance of this class just once, when the game first loads. Let's write code!

We are about to create a pair of scripts that are responsible for bridging the managed-to-native code gap.
 
Navigate to Assets > Plugins within your Unity project. Right-click within the Plugins folder and click Create > C# Script. Let's name it “nativeManager”. Double click the script to open it in MonoDevelop for editing. If you've developed in Unity before, the new script's contents should look familiar: it inherits from MonoBehaviour, and contains two empty functions, Start() and Update(). You can remove these two functions and the reference to MonoBehaviour.

This particular script depends on a namespace that is not included by default. Add the following line at the top of the script:

<code>using System.Runtime.InteropServices;</code>

The script should now look like this:

![Alt text](http://www.anor.ac/tutorial_images/AngryBots_nativeManager_script2.png "Looking good so far, nativeManager.")

nativeManager will be responsible for exposing native functions to managed scripts through a C interface. Let's add our first plugin function: openMusic(). Unity iOS plugins are statically linked to the executable. To accommodate this reality, we use “__Internal” as the library name. We import it by writing:

<code>[DllImport (“__Internal”)]</code>

We then define an extern method for openMusic():

<code>private static extern void _openMusicLibrary();</code>

Since Unity iOS plugins can only be called when running on an actual iOS device (not in the Xcode Simulator), Unity recommends to wrap the native functions in another C# layer which checks that the code is executing on a device. Let's do this by adding this code to the nativeManager script.

<code>

	public static void openMusic()
	{

	if(Application.platform == RuntimePlatform.IPhonePlayer)
		_openMusicLibrary()
		
	}

</code>

This code layer simply checks that the current platform is IPhonePlayer through a shorthand if-statement. If it returns TRUE, that means the code is running on an actual iOS device (IPhonePlayer covers both iPhones and iPads) and we're good to go!

That's all we're going to do in nativeManager.cs for now, so save the file. We will now temporarily leave the managed environment and move to native land, where we will write the Objective-C code that will run when openMusic() gets called from a C# script.

## Native Environment – Xcode

Get ready for a context switch, because we are going to start writing code in Objective-C rather than C#. Open up Xcode and create a new Objective-C file (File > New > File... > iOS > Source > Objective-C File). We are going to name this nativeManager.m, keeping the file type as “Empty File”. It is not a coincidence that we now have two files sharing the name nativeManager – in fact it is crucial that this pair of files (.cs and .m) be named identically!

![Alt text](http://www.anor.ac/tutorial_images/AngryBots_Xcode_file_creation.png "Continuing our work in Xcode...")

The newly created nativeManager.m file will be empty except for a line of code that imports the iOS Foundation framework. You can go ahead delete that line, as it is not necessary for this particular file. We are now going to add the _openMusicLibrary() function to this script. We will also import and make a call to the yet-to-be-created Selector class. 

<code>

	#import “Selector.h”

	void _openMusicLibrary()
	{
		NSLog(@”Reached _openMusicLibrary”);

		[[Selector mySelector] openMusicLibrary];
	}
</code>

This is where we will arrive any time nativeManager.openMusic() is called from a C# script back in Unity's managed code. But we're not done in native land just yet - we still have to add the actual code that will open the iOS Music library. Save this file on your computer (we'll add it to the Unity project later). 

## (Fast forward, Selector)

Now we will create a new Cocoa Touch Class (File > New > File... > iOS > Source > Cocoa Touch Class). This is going to subclass NSObject, and we'll name the class “Selector”. In reggae music, a selector is a person who assists the disc jockey by selecting the next record to be played. That's exactly what this script is going to do for us, the game's DJ, hence the name! 

Once you've created this class, you should see its associated header and implementation files in an Xcode window. Select the header file. We're going to add two lines after the interface declaration and before the @end line.

<code>
	+(Selector*)mySelector;
	-(void)openMusicLibrary;
	
</code>

The first is a class method which we will use to set up a singleton called mySelector. The second is an instance method in which we will open the MPMediaPickerController. Save the header file and switch to Selector's implementation file. Switch its extension from .m to .mm – this tells Xcode to treat this particular class as Objective-C++. This will make sense soon.

In Selector.mm, we are going to import two iOS frameworks: MediaPlayer and AVFoundation, and a math library:

<code>

	#import <MediaPlayer/MediaPlayer.h>
	#import <AVFoundation/AVFoundation.h>
	#include <math.h>
</code>

You can add these right below the import of “Selector.h” After adding these two import statements, we are going to add some Unity-specific code:

<code>

	void UnityPause(int pause);
	void UnitySetAudioSessionActive(int active);
	UIViewController *UnityGetGLViewController();
	
</code>

These are functions for pausing and unpausing Unity (to conserve system resources), settings Unity's audio session on iOS to be active or inactive, and creating a standard Objective-C UIViewController from Unity's GLView. If you are curious, after we build the Unity project you can Command + Left Click on UnityGetGLViewController() while in the generated Xcode project to see where it was defined. Xcode will take you to a file called UnityAppController.mm where an inquisitive reader will notice that it is declared using 'extern “C”', effectively allowing C code to run alongside C++ by including C headers in a C++ class. This is the reason why we changed the extension of the Selector class implementation file to .mm – it tells Xcode to compile as Objective-C++, a special file type that contains a mixture of Objective-C and C++ classes. 

We will now add an interface declaration to Selector's implementation file. 

<code>
	@interface Selector() <MPMediaPickerControllerDelegate, NSURLSessionDelegate, NSURLSessionTaskDelegate, 			AVAudioPlayerDelegate> {

	}

	@property(nonatomic,retain)AVAudioPlayer *musicPlayer;


	@end
</code>

We've assigned this class to be the delegate for a couple of native classes – MPMediaPickerControllerDelegate for handling interaction with MPMediaPickerController, and AVAudioPlayerDelegate for interaction with the AVAudioPlayer class that handles playback of the music we are about to select from the iOS device. We've also created an instance of AVAudioPlayer called musicPlayer.

Let's carry on making the singleton for the Selector class and add the code for choosing songs. 

<code>

	+(Selector*)mySelector
	{
		static Selector *sharedSingleton;
		if(!sharedSingleton)
			sharedSingleton = [[Selector alloc] init];
	
		return sharedSingleton;
	}

This simply checks if an instance of Selector already exists. If it doesn't, it creates one for us.

<code>
	-(id)init
	{
		if((self = [super init]))
		{

		}

		return self;
	}
</code>

Since Selector is a subclass of NSObject, we need to handle its initialization. The full source code includes set up of some arrays and dictionaries needed to do the harmonization, but we won't worry about that part for now.

Finally, let's write the openMusicLibrary function:

<code>

	-(void)openMusicLibrary
	{
		UnityPause (1); //Pause Unity

		MPMediaPickerController *myPicker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeMusic];
		myPicker.delegate = self;
		myPicker.allowsPickingMultipleItems = NO;

		[UnityGetGLViewController() presentViewController:myPicker animated:YES completion:nil];

	}
</code>
This code creates our MPMediaPickerController, fills it with all of the media of type “Music”, assigns its delegate to Selector, limits song selection to one at a time, and finally presents the MPMediaPickerController on top of the UIViewController containing the game view.

That's fine, but we still need to write two delegate methods to determine what should happen once a song is selected. Let's do that now...

<code>
	-(void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
	{
		MPMediaItem *item = [[mediaItemCollection items] objectAtIndex:0];
        	NSURL *url = [item valueForProperty:MPMediaItemPropertyAssetURL];
        	self.musicPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
        	_musicPlayer.delegate = self;
        	[_musicPlayer prepareToPlay];
        	[_musicPlayer play];
        	UnityPause(0);
        	[UnityGetGLViewController() dismissViewControllerAnimated:YES completion:nil];
	}


	-(void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker
	{
    		UnityPause(0);
    		[UnityGetGLViewController() dismissViewControllerAnimated:YES completion:nil];
		}

</code>

The first delegate function creates a new MPMediaItem from the selection, then loads and plays it with musicPlayer.

The second delegate method handles the behaviour of MPMediaPickerController if the player taps “Cancel” without selecting a song – it simply unpauses Unity and dismisses the MPMediaPickerController.

## A Note on Harmony

The plugin we are building requires an internet connection to query the EchoNest API. The full source code includes the ability to extract metadata associated with the chosen song to determine the Artist and Title. This is passed to a PHP web service provided by Veemix (https://www.veemix.com), which queries EchoNest's API to determine the Key and Mode for the chosen song and returns this result to the plugin. Key refers to the tonic note and chord which resolves tension in piece of music. Mode in this case refers to either major (happier sounding) or minor (sad). We will use this information to determine how we should synthesize the sound effects we will create with AudioKit. If you read through all of the code in this delegate function, you probably noticed a call to another function within the Selector class – updateCurrentInfo{} – this is where we create a harmonic set of notes based on the mode. The tonic note (determined by the key) is found within an array of note names and is added to the new harmonic set. If the mode is determined to be Major, the major third (an increase of 4 semitones from the octave) and a fifth (an increase of 7 semitones from the tonic) are included in the harmonic set. If the mode is determined to be Minor, the harmonic set will contain a minor third (an increase of 3 semitones from the tonic) and a fifth. 

EchoNest uses integers ranging from 0-11 to denote Key (corresponding to the 12 semitones of the chromatic scale starting at C) and either 0 or 1 to denote Mode (corresponding to major and minor, respectively). We can account for this in our code which enables us to use their common names going forward:

<code>

        NSArray *indexArray = [NSArray arrayWithObjects:@"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10", @"11", nil];
        NSArray *noteArray = [NSArray arrayWithObjects:@"C", @"Db", @"D", @"Eb", @"E", @"F", @"Gb", @"G", @"Ab", @"A", @"Bb", @"B", nil];
        
        NSDictionary *keyInfo = [NSDictionary dictionaryWithObjects:noteArray forKeys:indexArray];
        
        NSArray *modeIndex = [NSArray arrayWithObjects:@"0", @"1", nil];
        NSArray *scaleArray = [NSArray arrayWithObjects:@"Minor", @"Major", nil];
        
        NSDictionary *modeInfo = [NSDictionary dictionaryWithObjects:scaleArray forKeys:modeIndex];
        
</code>

We also need to define how frequency relates to pitch. For the purposes of this tutorial, let's stick to one octave containing A440, and wrap any extraneous values. We can calculate the frequency values for each semitone in the chromatic scale using the formula:

frequency = 440 x (2^(n/12))

where n is a signed integer representing the distance in semitones above (positive) or below (negative) from our reference value of A440. Rather than calculating these values ourselves and hardcoding them into the plugin, let's offload this work to the device to calculate at runtime. If we start our octave on C and count the distance in semitones to A, we find that A is 9 semitones above C. Let's use this knowledge in a for loop to fill an array with the frequency values for our octave:

<code>
        NSMutableArray *myFrequencyArray = [[NSMutableArray alloc] init];
        for (int i = 0; i<12; i++)
        {
            int j = (9 * -1) + i;
            float k = j/12.0f;
            float frequency = 440 * (powf(2.0f, k));
            [myFrequencyArray addObject:[NSString stringWithFormat:@"%f", frequency]];
        }
</code>

We'll store these arrays and dictionaries and use them later when specifying note parameters with AudioKit. Go ahead and add nativeManager.m, Selector.h, and Selector.mm to your Unity project's Assets > Plugins > iOS folder.

## Back to Managed Land – one more thing in Unity

At this point we have nearly finished bridging the managed-to-native code gap. We just need to add one more thing: a line of managed code that calls nativeManager.openMusic(). Let's add that now. Save everything in Xcode and go back to Unity. Select the “Player” game object in Unity's Hierarchy panel. With it selected, scroll to the bottom of the Inspector panel and click Add Component > New Script, name it anything you like (I chose to use Selector again because it will be responsible for calling the native function that launches the MPMediaPickerController). Set the language to be C Sharp. Click “Create and Add”. 

![Alt text](http://www.anor.ac/tutorial_images/AngryBots_Inspector_panel.png "Adding the call to nativeManager.openMusic from Selector.cs")

Double click the script in the Inspector panel to open it in MonoDevelop. In this script's Start() function, add this line:

<code>
	nativeManager.openMusic();
</code>

Save the file. We now have bridged the managed-to-native code gap. Let's build this Unity project and try it on an actual device. Click on File > Build Settings > Build. A prompt will appear asking you to save the build. Give it a name and click Save. Unity now generates a new Xcode project for us, and automatically adds our plugin code (from Assets > Plugins> iOS in Unity) to it in the “Libraries” folder. Great! Connect your device and build the Xcode project using the device as the target. You should now see the device's music library pop up as the game starts. Pick a song and it will start playing automatically.

### Attenuating the original sound effects

![Alt text](http://www.anor.ac/tutorial_images/AngryBots_AttenuateForWhat.png "Attenuate for what, Lil Jon? In this case, to make our own procedural sound effects!")

For this tutorial, we'll focus on replacing three specific sound effects in Angry Bots:

* The sound of the rainfall outside of the factory at the start of the level
* The attack sound of the flying bot
* The alert sound that plays when a crawling bot spots the player

To do this we are going to add an Audio Mixer object to our Unity project, route these specific sound effects through its main Group, and fully attenuate their volume. Navigate to the Unity project's Assets folder and click Assets > Create > Audio Mixer. Let's name the new mixer “myMixer”. 

![Alt text](http://www.anor.ac/tutorial_images/AngryBots_AudioMixer.png "Every game DJ should have their own mixer. Let's add one to our Unity project!")

Double click the new Audio Mixer and fully attenuate the volume on the Master group to -80.0 dB. Now we have to route the sound effects to the Master group. Navigate to Assets > Sounds > Ambience and select the file named “ambience_rain_outside”. This the sound of the rainfall that loops continously. Right-click on it and select “Find References in Scene”. You'll notice that the Scene view turns grey and reveals 8 game objects, all called “Rain” in the Hierarchy panel. These are the areas that trigger the rain loop to play when the Player encounters them. Select all 8 and look at the Inspector panel where you should see an Audio Source component. We can route the Audio Source's output to the Master group of the Audio Mixer by clicking the small circle to the immediate right of the empty Output field, and selecting the Master group from the popup list. 

![Alt text](http://www.anor.ac/tutorial_images/AngryBots_Mixer_Group.png "Making room for the new procedural audio goodness by routing the old stale sound effects to a mixer group that will be attenuated.")

We can repeat the same steps for the other two sound effects. The enemy attack sounds are located in Assets > Sounds > Enemy. Find the file named “enemy_Spider_AlertSound” and find all of its references in the scene. This reveals many game objects in the Hierarchy, but we are only interested in the ones named “AI”, so select all of those. Once you've selected them, route their Audio Source's output to the Master group like we did before. The last sound effect is called “enemy_FlyingBuzzer_ZapElectric”. Find all of its references in the scene (in this case all of the relevant game objects are called “KamikazeBuzzer”), and route their Audio Source's outputs to the Master group on the Audio Mixer. 

We're going to return to our trusty nativeManager script for a moment. We need to be able to call a native function each time these 3 sound effects are triggered during gameplay. So, let's add some functions to nativeManager to achieve this. Copy the following code into nativeManager.cs:

<code>

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

</code>

We will use startRain() and stopRain() to trigger the start and stop of our synthesized rain loop. FlyingBotFire() will get called each time the flying bot fires its weapon. We will call the tritone() function each time the crawling bot spots us. Let's finish completing the managed-to-native bridge for these functions. Open up nativeManager.m and add this code:

<code> 
	void _doTritone()
	{
    		[[Selector mySelector] tritone];
    
	}

	void _doStartRain()
	{
    
    		NSUserDefaults *myDefaults = [NSUserDefaults standardUserDefaults];
    		[myDefaults setObject:@"TRUE" forKey:@"isRaining"];
    		[myDefaults synchronize];
    		[[Selector mySelector] startRain];
    
	}

	void _doStopRain()
	{
    
    		NSUserDefaults *myDefaults = [NSUserDefaults standardUserDefaults];
    		[myDefaults setObject:@"FALSE" forKey:@"isRaining"];
    		[myDefaults synchronize];
    
	}

	void _doFlyingBotFire()
	{
    		[[Selector mySelector] flyingBotFire];
	}
	
</code>
We'll need to declare these new functions in our Selector class as well, so open up both Selector.h and Selector.mm. In Selector.h, add these lines:
<code>
	-(void)flyingBotFire;
	-(void)tritone;
	-(void)startRain;
	-(void)stopRain;
</code>

In Selector.mm, add these four functions but just leave them empty for now. 

Now we have to locate the places in Angry Bot's code where these sound effects get triggered. The rain loop is triggered from a script called PlaySoundOnTrigger.js – locate it in Assets > Scripts > Misc and open it up. It contains just one function, OnTriggerEnter(), where we will make the call to nativeManager.startRain(). We will also need to add a second function, OnTriggerExit() where we will call nativeManager.stopRain(). Once finished, the script should look like this:
<code>
	#pragma strict

	@script RequireComponent (AudioSource)
	
	var onlyPlayOnce : boolean = true;

	private var playedOnce : boolean = false;

	function OnTriggerEnter (unusedArg) {

		nativeManager.startRain();

		if (playedOnce && onlyPlayOnce)
			return;
	
		GetComponent.<AudioSource>().Play ();
		playedOnce = true;
	}

	function OnTriggerExit (unusedArg) {
		nativeManager.stopRain();

	}
</code>
When the flying bot fires its weapon, DoElectricArc() is called in the script named BuzzerKamikazeControllerAndAI.js. Let's add a call to nativeManager.FlyingBotFire() inside DoElectricArc(). 

Finally, when a crawling bot spots the player, OnSpotted() in AI.js is called. Let's add our call to nativeManager.tritone() inside the third if-statement contained within OnSpotted().

Now we are ready to make our own sounds to replace the 3 that we've attenuated. 

## Unity iOS + AudioKit = A soundhead's playground

We've covered a lot so far, but we haven't created any new sounds yet. Let's rectify that by introducing AudioKit, currently on version 2.0. It supports iOS and Mac OS X, and also includes some shell scripts for its new feature called Playgrounds. We are only interested in the iOS related stuff (for now!) 

Locate the folder called “AudioKit” within AudioKit-master and drag and drop it into Assets > Plugins > iOS in Unity. Then navigate to the “Platforms” subfolder and delete the folders for Mac and Swift – we don't need them.

Let's explain quickly how we are going to make sounds with AudioKit (for a complete description and documentation of AudioKit, refer to its website). AudioKit inherits certain terminology from Csound, a programming language designed specifically for audio and which has roots in the 1950s during the first experiments with digital audio synthesis. With AudioKit, a sound is represented as a Note for which mutable parameters like duration, which controls the duration of the synthesized sound on a granular level. The type of sound the Note will make is determined by its Instrument type, and each type has its own parameters – this can range from the resonant frequencies of a physical model of a water droplet to the cutoff frequency of a low-pass filter (effects, as well as analyzers, are also considered Instruments in AudioKit). The Instruments have to be added to an Orchestra, a collection of all the Instruments in an AudioKit application, before they can be played by a Conductor class. Let's see how this works in code by synthesizing our first sound effects.

## Making it Rain

You may have noticed that in Angry Bots, the player actually starts the level outside the factory floor, where a steady rain is falling. This is a good opportunity to use the Instrument representing a physical model of a water droplet that I mentioned earlier. In AudioKit, this Instrument is called AKDroplet, which exposes three resonant frequencies as parameters that we can use to harmonize the sound of each droplet to the game music. We'll have to synthesize many of these individual droplet Notes per second to make it sound like continuous rainfall. Let's make it rain!

We are about to create our first AudioKit Instrument based on AKDroplet. Create a new Cocoa Touch class in Xcode, subclassing from AKInstrument, and name it WaterDroplet. In WaterDroplet.h, add this code:

<code>
	@interface WaterDroplet : AKInstrument

	@property(nonatomic,strong)AKInstrumentProperty *amplitude;

	@property(readonly)AKAudio *auxOutput;

	@end


	@interface WaterDropletNote : AKNote
	@property(nonatomic,strong)AKNoteProperty *frequency;
	@property(nonatomic,strong)AKNoteProperty *amplitude;

	@property(nonatomic,strong)AKNoteProperty *dampingFactor;
	@property(nonatomic,strong)AKNoteProperty *energyReturn;
	@property(nonatomic,strong)AKNoteProperty *mainResonantFrequency;
	@property(nonatomic,strong)AKNoteProperty *firstResonantFrequency;
	@property(nonatomic,strong)AKNoteProperty *secondResonantFrequency;
	@property(nonatomic,strong)AKNoteProperty *intensity;

	-(instancetype)initWithFrequency:(float)frequency;
	@end

</code>

Notice how we've created an interface declaration for the WaterDroplet Instrument, and for WaterDropletNote, which subclasses from AKNote. In WaterDroplet.m, add the following code:
<code>
	#import "WaterDroplet.h"
	#import "AKFoundation.h"

	@implementation WaterDroplet

	-(instancetype)init
	{
    	self = [super init];
    	if(self)
    	{
	 	WaterDropletNote *note = [[WaterDropletNote alloc] init];
 
	 	_amplitude = [self createPropertyWithValue:1.0 minimum:1.0 maximum:1.0];

        
        	AKDroplet *waterDroplet;
        
        
        	waterDroplet = [[AKDroplet alloc] initWithIntensity:note.intensity dampingFactor:note.dampingFactor 		energyReturn:note.energyReturn mainResonantFrequency:note.mainResonantFrequency 					firstResonantFrequency:note.firstResonantFrequency 									secondResonantFrequency:note.secondResonantFrequency amplitude:_amplitude];
        

        
        	[self connect:waterDroplet];
        

        
        	[self setAudioOutput:[waterDroplet scaledBy:_amplitude]];
        
        
    	}
    	return self;
	}

	@end


	@implementation WaterDropletNote

	-(instancetype)init
	{
    		self = [super init];
    		if(self)
    		{
        
        		_dampingFactor = [self createPropertyWithValue:0.2 minimum:0 maximum:1.0];
        		_energyReturn = [self createPropertyWithValue:0.5 minimum:0 maximum:1.0];
        		_mainResonantFrequency = [self createPropertyWithValue:450 minimum:200 maximum:600];
        		_firstResonantFrequency = [self createPropertyWithValue:600 minimum:450 maximum:750];
        		_secondResonantFrequency = [self createPropertyWithValue:750 minimum:600 maximum:900];
        		_intensity = [self createPropertyWithValue:10 minimum:5 maximum:20];
        
        		_amplitude = [self createPropertyWithValue:1.0 minimum:1.0 maximum:1.0];
        
        
    	}
    	return self;
	}

	-(instancetype)initWithFrequency:(float)frequency
	{
    		self = [self init];
		if(self)
		{
			 _frequency.value = frequency;
        		_amplitude.value = 1.0;

    		}
    
    	return self;
	}


	@end
</code>
AudioKit 2.0 also includes a range of pre-built instruments. We'll use Tambourine for the flying bot attack sound, and FMOscillatorInstrument for the tritone that plays when we are spotted by a crawling bot.

## Introducing the Conductor

The Conductor class is responsible for playing the Instruments contained within the Orchestra. Let's create the Conductor class now. Open Xcode and create a new Cocoa Touch Class subclassing from NSObject. Name it “Conductor”. We are going to add three functions that will be called each time one of our three sound effects needs to be synthesized:
<code>
	-(void)playTone:(NSString*)tone;
	-(void)playWaterDroplet:(float)intensity dampingFactor:(float)damping energyReturn:(float)energy mainResonantFreq:(float)mainFreq firstResonantFreq:(float)firstFreq secondResonantFreq:(float)secondFreq amplitude:(float)amp;
	-(void)playTambourine:(float)damping mainResonantFreq:(float)mainFreq firstResonantFreq:(float)firstFreq secondResonantFreq:(float)secondFreq amplitude:(float)amp;
</code>
Then in Conductor.m, we'll create instances of Notes for each instrument that hook into our harmonic set that we constructed based on the EchoNest information. The Conductor.m should look like this when we're all done:

<code>
	#import "Conductor.h"
	#import "AKFoundation.h"
	#import "WaterDroplet.h"
	#import "Tambourine.h"
	#import "FMOscillatorInstrument.h"
	#import "KeyModeData.h"

	@implementation Conductor
	{
	 	FMOscillatorInstrument *toneGenerator;
    		WaterDroplet *rain;
    		Tambourine *tambourine;
    
    		NSArray *frequencies;
    		NSMutableDictionary *currentNotes;
	}

	-(void)playTone:(NSString*)tone
	{
    		float frequency = [tone floatValue];
    
    		FMOscillatorNote *note = [[FMOscillatorNote alloc] initWithFrequency:frequency amplitude:1.0f];
    		[toneGenerator playNote:note];
    		[currentNotes setObject:note forKey:tone];

    		[self performSelector:@selector(stopTone:) withObject:note afterDelay:0.5];
	}	

	-(void)stopTone:(FMOscillatorNote*)noteTone
	{
		 AKSequence *releaseSequence = [AKSequence sequence];
    
		 AKEvent *decreaseVolume = [[AKEvent alloc] initWithBlock:^{
		 noteTone.amplitude.value *= 0.95;
    	}];
    
    	for(int i=0; i<100; i++)
    	{
        	[releaseSequence addEvent:decreaseVolume afterDuration:0.001];
	 }
    
    	AKEvent *stop = [[AKEvent alloc] initWithBlock:^{
        [noteTone stop];
    	}];
    	[releaseSequence addEvent:stop afterDuration:0.01];
    	[releaseSequence play];
	}

	-(void)playWaterDroplet:(float)intensity dampingFactor:(float)damping energyReturn:(float)energy mainResonantFreq:(float)mainFreq firstResonantFreq:(float)firstFreq secondResonantFreq:(float)secondFreq amplitude:(float)amp
	{
    	rain.amplitude = [[AKInstrumentProperty alloc] initWithValue:amp];
    	WaterDropletNote *note = [[WaterDropletNote alloc] initWithFrequency:mainFreq];
    	note.intensity.value = intensity;
    	note.dampingFactor.value = damping;
    	note.energyReturn.value = energy;
    	note.mainResonantFrequency.value = mainFreq;
    	note.firstResonantFrequency.value = firstFreq;
    	note.secondResonantFrequency.value = secondFreq;
    	note.duration.value = 1.0;

    	[rain playNote:note];
	}
	
	-(void)playTambourine:(float)damping mainResonantFreq:(float)mainFreq firstResonantFreq:(float)firstFreq secondResonantFreq:(float)secondFreq amplitude:(float)amp
	{
    		tambourine.amplitude.value = 1.0;
    
    		TambourineNote *note = [[TambourineNote alloc] init];
    		note.dampingFactor.value = damping;
    		note.mainResonantFrequency.value = mainFreq;
    		note.firstResonantFrequency.value = firstFreq;
    		note.secondResonantFrequency.value = secondFreq;
    		note.duration.value = 1.0;

    		[tambourine playNote:note];
    
	}

	-(instancetype)init
	{
		self = [super init];
    		if(self)
    		{
        
        
        	KeyModeData *myData = [KeyModeData getInstance];
        
        	currentNotes = [[NSMutableDictionary alloc] init];
        	
        	noteFreqDict = [[NSMutableDictionary alloc] initWithDictionary:myData.noteFreqDictionary];
        
        	toneGenerator = [[FMOscillatorInstrument alloc] init];
        
        	[AKOrchestra addInstrument:toneGenerator];

        	rain = [[WaterDroplet alloc] init];
        	[AKOrchestra addInstrument:rain];

        	tambourine = [[Tambourine alloc] init];
        	[AKOrchestra addInstrument:tambourine];
  
        	[[AKManager sharedManager] setIsLogging:YES];
        	[AKOrchestra start];
    

    	}
    
	 return self;
	}

	@end

</code>
## The Final Steps

At this point, we've plugged Unity into AudioKit by creating a managed-to-native code bridge. We've presented the player an interface for choosing a song to play, and we are able to determine the key and mode for a chosen song by using the EchoNest API. We've programatically created a harmonic set of notes to use in the synthesis of our new sound effects, and we've added the three new Instrument types to the AudioKit Orchestra. All that's left to do is call on the Conductor to play these sound effects. We're going to do this from our Selector class. In Selector.mm, import our newly created Conductor class with this line:
<code>
	#import “Conductor.h”
</code>
We will then create a new instance of the Conductor within the interface declaration:
<code>
	@interface Selector() <MPMediaPickerControllerDelegate, NSURLSessionDelegate, NSURLSessionTaskDelegate, AVAudioPlayerDelegate> {
    
    	Conductor *conductor;
    
    
	}
</code>
Next, we allocate and initialize the Conductor in Selector's init() function:
<code>
        conductor = [[Conductor alloc] init];
</code>

Now we can start playing notes. Let's fill in the empty functions startRain(), tritone(), and flyingBotFire() that we created in Selector.mm earlier:

<code>
	-(void)startRain
	{
    		[conductor playWaterDroplet:10 dampingFactor:0.01 energyReturn:0.6 mainResonantFreq:[[_noteFreqDict objectForKey:[_harmonizationInfo objectAtIndex:0]] floatValue] firstResonantFreq:[[_noteFreqDict objectForKey:[_harmonizationInfo objectAtIndex:1]] floatValue] secondResonantFreq:[[_noteFreqDict objectForKey:[_harmonizationInfo objectAtIndex:2]] floatValue] amplitude:1.0];
    
    	NSUserDefaults *myDefaults = [NSUserDefaults standardUserDefaults];
    
    	if([[myDefaults objectForKey:@"isRaining"] isEqualToString:@"TRUE"])
    	{
        	[self performSelector:@selector(rainLoop) withObject:nil afterDelay:0.025];
    	}

	}
</code>
Here we call playWaterDroplet with the Conductor. Then we enter an if-statement to check if we are still in an area of the level where it is raining. If we are, we call startRain again after a delay of 0.025 seconds. This means that as long as it is raining, we should synthesize a new water droplet 40 times per second.
<code>
	-(void)tritone
	{
    		KeyModeData *myData = [KeyModeData getInstance];
    
    		if(_currentKey)
    		{
        
		 NSString *commonName = [[NSString alloc] initWithString:[myData.keyData objectForKey:_currentKey]];
		 NSArray *noteSet = [NSArray arrayWithObjects:@"C", @"Db", @"D", @"Eb", @"E", @"F", @"Gb", @"G", @"Ab", @"A", @"Bb", @"B", @"C", @"Db", @"D", @"Eb", @"E", @"F", @"Gb", @"G", @"Ab", @"A", @"Bb", @"B", nil];
        
        	NSLog(@"keyData: %@", myData.keyData);
        
        	NSMutableString *augFourth = [[NSMutableString alloc] initWithString:@""];
        
        	for (int i=0; i<[noteSet count]; i++)
        	{
            		if([[noteSet objectAtIndex:i] isEqualToString:commonName])
            		{
                		augFourth = [noteSet objectAtIndex:i+6]; //A tritone is composed of the Key (tonic) note and an augmented fourth, or 6 semitones above the tonic note.
                
                	i = [noteSet count];
            		}
        	}
        	NSLog(@"tritone consists of %@ and %@", commonName, augFourth);
        	NSArray *tritoneArray = [[NSArray alloc] initWithObjects:[_noteFreqDict objectForKey:commonName], 			[_noteFreqDict objectForKey:augFourth], nil];
        	for(int i=0; i<[tritoneArray count]; i++)
        	{
            		[conductor playTone:[tritoneArray objectAtIndex:i]];
            
        	}
        
    		}
	}
</code>
Here we construct a new harmonic set – a tritone. A tritone is a very dissonant musical interval, and serves to create tension when the player is spotted by a crawling bot. We play the tritone with the FMOscillatorInstrument.
<code>
	-(void)flyingBotFire
{
        [conductor playTambourine:0.01 mainResonantFreq:[[_noteFreqDict objectForKey:[_harmonizationInfo objectAtIndex:0]] floatValue] firstResonantFreq:[[_noteFreqDict objectForKey:[_harmonizationInfo objectAtIndex:1]] floatValue] secondResonantFreq:[[_noteFreqDict objectForKey:[_harmonizationInfo objectAtIndex:2]] floatValue] amplitude:1.0];
}
</code>
Finally, we play the tambourine instrument each time the flying bot fires its weapon. We've tuned the tambourine Instrument's resonant frequencies to the harmonic set we constructed based on the key and mode.


That's it, you can now build the Xcode project, choose a song, and hear the three sound effects harmonize with the music. Enjoy!
