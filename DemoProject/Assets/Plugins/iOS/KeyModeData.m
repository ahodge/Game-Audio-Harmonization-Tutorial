//
//  KeyModeData.m
//  Unity-iPhone
//
//  Created by CCAT Vocal Booth on 2014-12-03.
//
//

#import "KeyModeData.h"

@implementation KeyModeData
@synthesize keyData, modeData, noteFreqDictionary;

static KeyModeData *instance = nil;

+(KeyModeData *)getInstance
{
    @synchronized(self)
    {
        if(instance==nil)
        {
            instance = [KeyModeData new];
        }
    }
    return instance;
}

@end
