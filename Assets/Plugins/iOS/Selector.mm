//
//  Selector.m
//  
//
//  Created by CCAT Vocal Booth on 2015-03-26.
//
//

#import "Selector.h"
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "KeyModeData.h"

#import "AKFoundation.h"
#import "Conductor.h"


void UnityPause( int pause );

void UnitySetAudioSessionActive( int active );

UIViewController *UnityGetGLViewController();

@interface Selector() <MPMediaPickerControllerDelegate, NSURLSessionDelegate, NSURLSessionTaskDelegate, AVAudioPlayerDelegate> {
    
    Conductor *conductor;
    
}

@property(nonatomic,retain)AVAudioPlayer *musicPlayer;

@property(nonatomic,retain)NSMutableString *currentKey;
@property(nonatomic,retain)NSMutableString *currentMode;

@property(nonatomic,retain)NSMutableArray *harmonizationInfo;

@property(nonatomic,retain)UILabel *currentInfo;

@property(nonatomic,retain)NSMutableDictionary *noteFreqDict;



@end

@implementation Selector


BOOL isPad() {
#ifdef UI_USER_INTERFACE_IDIOM
    return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
#else
    return NO;
#endif
}

+ (Selector*)mySelector


{
    static Selector *sharedSingleton;
    
    if( !sharedSingleton )
        sharedSingleton = [[Selector alloc] init];
    
    return sharedSingleton;
}

-(id)init
{
    if((self = [super init]))
    {
        NSLog(@"init");
        UnitySetAudioSessionActive(1);


        KeyModeData *myData = [KeyModeData getInstance];

        _currentInfo = [[UILabel alloc] initWithFrame:CGRectMake(UnityGetGLViewController().view.bounds.size.width-100, 0, 200, 100)];
        [_currentInfo setTextColor:[UIColor whiteColor]];
        [_currentInfo setText:@""];
        [UnityGetGLViewController().view addSubview:_currentInfo];


        NSArray *indexArray = [NSArray arrayWithObjects:@"0", @"1", @"2", @"3", @"4", @"5", @"6", @"7", @"8", @"9", @"10", @"11", nil];
        NSArray *noteArray = [NSArray arrayWithObjects:@"C", @"Db", @"D", @"Eb", @"E", @"F", @"Gb", @"G", @"Ab", @"A", @"Bb", @"B", nil];

        NSDictionary *keyInfo = [NSDictionary dictionaryWithObjects:noteArray forKeys:indexArray];

        NSArray *modeIndex = [NSArray arrayWithObjects:@"0", @"1", nil];
        NSArray *scaleArray = [NSArray arrayWithObjects:@"Minor", @"Major", nil];

        NSDictionary *modeInfo = [NSDictionary dictionaryWithObjects:scaleArray forKeys:modeIndex];

        myData.keyData = [[NSMutableDictionary alloc] initWithDictionary:keyInfo];
        myData.modeData = [[NSMutableDictionary alloc] initWithDictionary:modeInfo];

        NSMutableArray *myFrequencyArray = [[NSMutableArray alloc] init];

        for (int i = 0; i<12; i++)
        {
            int j = (9 * -1) + i;
            float k = j/12.0f;
            float frequency = 440 * (powf(2.0f, k));
            [myFrequencyArray addObject:[NSString stringWithFormat:@"%f", frequency]];
        }

        _noteFreqDict = [[NSMutableDictionary alloc] initWithObjects:myFrequencyArray forKeys:noteArray];
        
        myData.noteFreqDictionary = [[NSMutableDictionary alloc] initWithDictionary:_noteFreqDict];
        
        conductor = [[Conductor alloc] init];

        NSLog(@"end of init");
    }

    return self;
}



-(void)updateCurrentInfo
{
    NSLog(@"updateCurrentInfo");
    KeyModeData *myData = [KeyModeData getInstance];


    [_currentInfo setText:[NSString stringWithFormat:@"%@ %@", [myData.keyData objectForKey:_currentKey], [myData.modeData objectForKey:_currentMode]]];

    NSArray *noteSet = [NSArray arrayWithObjects:@"C", @"Db", @"D", @"Eb", @"E", @"F", @"Gb", @"G", @"Ab", @"A", @"Bb", @"B", @"C", @"Db", @"D", @"Eb", @"E", @"F", @"Gb", @"G", @"Ab", @"A", @"Bb", @"B", nil];

    NSMutableArray *harmonicSet = [[NSMutableArray alloc] init];

    if ([_currentMode isEqualToString:@"1"])
    {
        // Major key

        for(int i=0; i<[noteSet count]; i++)
        {
            if ([[myData.keyData objectForKey:_currentKey] isEqualToString:[NSString stringWithFormat:@"%@", [noteSet objectAtIndex:i]]])
            {


                [harmonicSet addObject:[noteSet objectAtIndex:i]]; //Tonic
                [harmonicSet addObject:[noteSet objectAtIndex:i+4]]; //Major third
                [harmonicSet addObject:[noteSet objectAtIndex:i+7]]; //Major fifth



                i = [noteSet count];
            }
        }




    } else if ([_currentMode isEqualToString:@"0"])
    {
        // Minor key

        for(int i=0; i<[noteSet count]; i++)
        {
            if ([[myData.keyData objectForKey:_currentKey] isEqualToString:[NSString stringWithFormat:@"%@", [noteSet objectAtIndex:i]]])
            {


                [harmonicSet addObject:[noteSet objectAtIndex:i]]; //Tonic
                [harmonicSet addObject:[noteSet objectAtIndex:i+3]]; //Minor third
                [harmonicSet addObject:[noteSet objectAtIndex:i+7]]; //Major fifth

                i = [noteSet count];
            }
        }

    }

    NSLog(@"Harmonic set for %@ %@ contains: %@", [NSString stringWithFormat:@"%@", [myData.keyData objectForKey:_currentKey]], [NSString stringWithFormat:@"%@", [myData.modeData objectForKey:_currentMode]], harmonicSet);

    _harmonizationInfo = [[NSMutableArray alloc] initWithArray:harmonicSet];

}

-(void)openMusicLibrary
{
    NSLog(@"openMusic");

    UnityPause(1);

    MPMediaPickerController *myPicker = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeMusic];
    myPicker.delegate = self;
    myPicker.allowsPickingMultipleItems = NO;


    if (isPad)
    {
        myPicker.modalPresentationStyle = UIModalPresentationFormSheet;
    }
    [UnityGetGLViewController() presentViewController:myPicker animated:YES completion:nil];
}


-(void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection
{
    NSLog(@"didPickMediaItems");

    NSMutableString *artistString = [[NSMutableString alloc] init];
    NSMutableString *titleString = [[NSMutableString alloc] init];

    for (int i=0; i<[mediaItemCollection.items count]; i++)
    {
        MPMediaItem *item = (MPMediaItem*)[mediaItemCollection.items objectAtIndex:i];
        artistString = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"%@", [item valueForProperty:MPMediaItemPropertyArtist]]];
        titleString = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"%@", [item valueForProperty:MPMediaItemPropertyTitle]]];
    }


    NSString *encodedArtist = [artistString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSString *encodedTitle = [titleString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];



    NSMutableString *echoString = [[NSMutableString alloc] initWithString:@"https://www.veemix.com/index.php?option=com_echonestsonginfo&format=raw&artist="];
    [echoString appendString:encodedArtist];
    [echoString appendString:@"&title="];
    [echoString appendString:encodedTitle];


    NSURLSessionConfiguration *defaultConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSURLSession *defaultSession = [NSURLSession sessionWithConfiguration:defaultConfig delegate:self delegateQueue:[NSOperationQueue mainQueue]];

    NSURLSessionDataTask *dataTask = [defaultSession dataTaskWithURL:[NSURL URLWithString:echoString] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

        id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil];


        NSDictionary *jsonDict = [NSDictionary dictionaryWithDictionary:jsonObject];




        _currentKey = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"%@", [[[[[jsonDict valueForKey:@"response"] valueForKey:@"songs"] valueForKey:@"audio_summary"] valueForKey:@"key"] objectAtIndex:0]]];
        _currentMode = [[NSMutableString alloc] initWithString:[NSString stringWithFormat:@"%@", [[[[[jsonDict valueForKey:@"response"] valueForKey:@"songs"] valueForKey:@"audio_summary"] valueForKey:@"mode"] objectAtIndex:0]]];


        [self updateCurrentInfo];

        UnityPause(0);

        [UnityGetGLViewController() dismissViewControllerAnimated:YES completion:nil];


        MPMediaItem *item = [[mediaItemCollection items] objectAtIndex:0];
        NSURL *url = [item valueForProperty:MPMediaItemPropertyAssetURL];

        self.musicPlayer = [[AVAudioPlayer alloc] initWithContentsOfURL:url error:nil];
        _musicPlayer.delegate = self;
        [_musicPlayer prepareToPlay];
        [_musicPlayer play];




    }];
    [dataTask resume];


}

-(void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker
{
    NSLog(@"mediaPickerDidCancel");

    UnityPause(0);

    [UnityGetGLViewController() dismissViewControllerAnimated:YES completion:nil];
}


-(void)flyingBotFire
{
        [conductor playTambourine:0.01 mainResonantFreq:[[_noteFreqDict objectForKey:[_harmonizationInfo objectAtIndex:0]] floatValue] firstResonantFreq:[[_noteFreqDict objectForKey:[_harmonizationInfo objectAtIndex:1]] floatValue] secondResonantFreq:[[_noteFreqDict objectForKey:[_harmonizationInfo objectAtIndex:2]] floatValue] amplitude:1.0];
}

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
                augFourth = [noteSet objectAtIndex:i+6]; //A tritone is composed of the Key note and an augmented fourth, or 3 whole tones above Key note.
                
                i = [noteSet count];
            }
        }
        NSLog(@"tritone consists of %@ and %@", commonName, augFourth);
        NSArray *tritoneArray = [[NSArray alloc] initWithObjects:[_noteFreqDict objectForKey:commonName], [_noteFreqDict objectForKey:augFourth], nil];
        for(int i=0; i<[tritoneArray count]; i++)
        {
            [conductor playTone:[tritoneArray objectAtIndex:i]];
            
        }
        
    }
    
}

-(void)startRain
{
    [self rainLoop];

}




-(void)rainLoop
{
    

    [conductor playWaterDroplet:10 dampingFactor:0.01 energyReturn:0.6 mainResonantFreq:[[_noteFreqDict objectForKey:[_harmonizationInfo objectAtIndex:0]] floatValue] firstResonantFreq:[[_noteFreqDict objectForKey:[_harmonizationInfo objectAtIndex:1]] floatValue] secondResonantFreq:[[_noteFreqDict objectForKey:[_harmonizationInfo objectAtIndex:2]] floatValue] amplitude:1.0];
    
    NSUserDefaults *myDefaults = [NSUserDefaults standardUserDefaults];
    
    if([[myDefaults objectForKey:@"isRaining"] isEqualToString:@"TRUE"])
    {
        [self performSelector:@selector(rainLoop) withObject:nil afterDelay:0.025];
    }
}

@end
