//
//  KeyModeData.h
//  Unity-iPhone
//
//  Created by CCAT Vocal Booth on 2014-12-03.
//
//

#import <Foundation/Foundation.h>

@interface KeyModeData : NSObject {
    NSMutableDictionary *keyData;
    NSMutableDictionary *modeData;
    
    NSMutableDictionary *noteFreqDictionary;
}

@property(nonatomic,retain)NSMutableDictionary *keyData;
@property(nonatomic,retain)NSMutableDictionary *modeData;

@property(nonatomic,retain)NSMutableDictionary *noteFreqDictionary;

+(KeyModeData*)getInstance;

@end
