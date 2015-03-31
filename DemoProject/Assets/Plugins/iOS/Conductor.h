//
//  Conductor.h
//  Unity-iPhone
//
//  Created by CCAT Vocal Booth on 2015-03-27.
//
//

#import <Foundation/Foundation.h>

@interface Conductor : NSObject
{
    NSMutableDictionary *noteFreqDict;

}

-(void)playTone:(NSString*)tone;
-(void)playWaterDroplet:(float)intensity dampingFactor:(float)damping energyReturn:(float)energy mainResonantFreq:(float)mainFreq firstResonantFreq:(float)firstFreq secondResonantFreq:(float)secondFreq amplitude:(float)amp;
-(void)playTambourine:(float)damping mainResonantFreq:(float)mainFreq firstResonantFreq:(float)firstFreq secondResonantFreq:(float)secondFreq amplitude:(float)amp;

@end
