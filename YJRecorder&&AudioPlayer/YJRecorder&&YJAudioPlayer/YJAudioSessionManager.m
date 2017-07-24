//
//  YJAudioSessionManager.m
//  YJRecorder&&AudioPlayer
//
//  Created by ddn on 16/8/31.
//  Copyright © 2016年 张永俊. All rights reserved.
//

#import "YJAudioSessionManager.h"

#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/AudioToolbox.h>
#import <UIKit/UIKit.h>

@interface YJAudioSessionManager ()

@property (nonatomic, assign, getter=isAct) BOOL act;

@property (strong, nonatomic) NSMutableSet *delegates;

@end

@implementation YJAudioSessionManager

YJSingleton_m(instance)

- (NSError *)active
{
    if (_act) {
        return nil;
    }
    NSError *error = nil;
    _act = [[AVAudioSession sharedInstance] setActive:YES error:&error];
    if (_act) {
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
        [self addObserver];
        [self changeRoute:nil];
    }
    if (error) {
        _act = NO;
    }
    return error;
}

- (NSError *)invalid
{
    if (!_act) {
        return nil;
    }
    NSError *error = nil;
    _act = ![[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    if (!_act) {
        [self removeObserver];
    }
    return error;
}

- (void)addDelegate:(id<YJAudioSessionDelegate>)delegate
{
    if (![self.delegates containsObject:delegate]) {
        [self.delegates addObject:delegate];
    }
}

- (void)removeDelegate:(id<YJAudioSessionDelegate>)delegate
{
    if ([self.delegates containsObject:delegate]) {
        [self.delegates removeObject:delegate];
    }
}

- (NSMutableSet *)delegates
{
    if (!_delegates) {
        _delegates = [NSMutableSet set];
    }
    return _delegates;
}

- (void)sendMsgToDelegate:(SEL)sel with:(id)parm
{
    [self.delegates enumerateObjectsUsingBlock:^(id<YJAudioSessionDelegate> obj, BOOL * _Nonnull stop) {
        if ([obj respondsToSelector:sel]) {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"
            [obj performSelector:sel withObject:parm];
#pragma clang diagnostic pop
        }
    }];
}

- (void)addObserver
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appBackground:) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(backForground:) name:UIApplicationWillEnterForegroundNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(interrupted:) name:AVAudioSessionInterruptionNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeRoute:) name:AVAudioSessionRouteChangeNotification object:nil];
}

- (void)backForground:(NSNotification *)noti
{
    NSError *error;
    _act = [[AVAudioSession sharedInstance] setActive:YES error:&error];
    if (_act) {
        [self sendMsgToDelegate:@selector(audioSessionReAct) with:nil];
    }
}

- (void)appBackground:(NSNotification *)noti
{
    NSError *error = nil;
    _act = ![[AVAudioSession sharedInstance] setActive:NO withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    
    if (!_act) {
        [self sendMsgToDelegate:@selector(audioSessionEnterBackground) with:nil];
    }
}

- (void)interrupted:(NSNotification *)noti
{
    [self sendMsgToDelegate:@selector(audioSessionInterrupt:) with:@([noti.userInfo[AVAudioSessionInterruptionTypeKey] boolValue])];
}

- (void)changeRoute:(NSNotification *)noti
{
    AVAudioSession *session = [AVAudioSession sharedInstance];
    BOOL success;
    NSError *error;
    BOOL headset = [self.class usingHeadset];
    if (!headset)
    {
        success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideSpeaker error:&error];
        if (!success)  NSLog(@"AVAudioSession error overrideOutputAudioPort:%@",error);
    }else
    {
        success = [session overrideOutputAudioPort:AVAudioSessionPortOverrideNone error:&error];
        if (!success)  NSLog(@"AVAudioSession error overrideOutputAudioPort:%@",error);
    }
    [self sendMsgToDelegate:@selector(audioSessionRouteChanged:) with:@(headset)];
}

+ (BOOL)usingHeadset
{
#if TARGET_IPHONE_SIMULATOR
    return NO;
#endif
    
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunreachable-code"
    AVAudioSessionPortDescription *output = [[AVAudioSession sharedInstance] currentRoute].outputs.lastObject;
#pragma clang diagnostic pop
    
    BOOL hasHeadset = NO;
    if(!output)
    {
        // Silent Mode
    }
    else
    {
        /* Known values of route:
         * "Headset"
         * "Headphone"
         * "Speaker"
         * "SpeakerAndMicrophone"
         * "HeadphonesAndMicrophone"
         * "HeadsetInOut"
         * "ReceiverAndMicrophone"
         * "Lineout"
         */
        NSString *routeStr = output.portType;
        
        NSRange headphoneRange = [routeStr rangeOfString : @"Headphone"];
        NSRange headsetRange = [routeStr rangeOfString : @"Headset"];
        
        if (headphoneRange.location != NSNotFound)
        {
            hasHeadset = YES;
        }
        else if(headsetRange.location != NSNotFound)
        {
            hasHeadset = YES;
        }
    }
    
    return hasHeadset;
}

- (void)removeObserver
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)dealloc
{
    [self invalid];
}

@end

