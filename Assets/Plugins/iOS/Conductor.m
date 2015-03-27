//
//  Conductor.m
//  Unity-iPhone
//
//  Created by CCAT Vocal Booth on 2015-03-27.
//
//

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

    [self performSelector:@selector(stopTone:) withObject:note afterDelay:1.0];
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
    
    rain.amplitude.value = 1.0f;
    
    WaterDropletNote *note = [[WaterDropletNote alloc] initWithFrequency:mainFreq];
    note.intensity.value = intensity;
    note.dampingFactor.value = damping;
    note.energyReturn.value = energy;
    note.mainResonantFrequency.value = mainFreq;
    note.firstResonantFrequency.value = firstFreq;
    note.secondResonantFrequency.value = secondFreq;
    note.duration.value = 1.0;
    note.amplitude.value = 1.0;
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
