//
//  WaterDroplet.h
//  Unity-iPhone
//
//  Created by CCAT Vocal Booth on 2015-03-27.
//
//

#import "AKInstrument.h"

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