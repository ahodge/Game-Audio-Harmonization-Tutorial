//
//  WaterDroplet.m
//  Unity-iPhone
//
//  Created by CCAT Vocal Booth on 2015-03-27.
//
//

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
        
        waterDroplet = [[AKDroplet alloc] initWithIntensity:note.intensity dampingFactor:note.dampingFactor energyReturn:note.energyReturn mainResonantFrequency:note.mainResonantFrequency firstResonantFrequency:note.firstResonantFrequency secondResonantFrequency:note.secondResonantFrequency amplitude:_amplitude];
        

        
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
