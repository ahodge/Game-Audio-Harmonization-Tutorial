#import "Selector.h"

void _openMusicLibrary ()
{
    
    [[Selector mySelector] openMusicLibrary];
}

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