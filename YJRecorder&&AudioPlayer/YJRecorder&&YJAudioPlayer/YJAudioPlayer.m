//
//  YJAudioPlayer.m
//  YJRecorder&&AudioPlayer
//
//  Created by ddn on 16/8/31.
//  Copyright © 2016年 张永俊. All rights reserved.
//

#import "YJAudioPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import "YJAudioSessionManager.h"

@interface YJAudioPlayer() <YJAudioSessionDelegate, AVAudioPlayerDelegate>

@property (strong, nonatomic) NSMutableDictionary *players;

@property (copy, nonatomic) NSString *lastPath;

@property (strong, nonatomic) NSMutableDictionary *observers;

@property (assign, nonatomic) BOOL autoBackPlay;

@end

@implementation YJAudioPlayer

- (NSMutableDictionary *)players
{
    if (!_players) {
        _players = [NSMutableDictionary dictionary];
    }
    return _players;
}

- (NSMutableDictionary *)observers
{
    if (!_observers) {
        _observers = [NSMutableDictionary dictionary];
    }
    return _observers;
}

- (void)addObserverForPath:(NSString *)path whenStatusChanged:(void (^)(YJAudioPlayerStatus))statusChanged
{
    [self removeObserverForPath:path];
    self.observers[path] = statusChanged;
}

- (void)removeObserverForPath:(NSString *)path
{
    [self.observers removeObjectForKey:path];
}

- (void)sendMsgToObserverForPath:(NSString *)path msg:(YJAudioPlayerStatus)status
{
    YJAudioPlayerStatusChanged block = self.observers[path];
    if (block) {
        block(status);
    }
}

- (BOOL)playWithPath:(NSString *)path
{
    BOOL re = [self playWithPath:path retry:NO];
    if (!re) {
        [self playWithPath:path retry:YES];
    }
    return re;
}

- (BOOL)playWithPath:(NSString *)path retry:(BOOL)retry
{
    [self pauseWithPath:_lastPath];
    
    _lastPath = path;
    
    AVAudioPlayer *player = [self playerForPath:path];
    
    if (!player) {
        NSError *error;
        player = [[AVAudioPlayer alloc]initWithContentsOfURL:[NSURL URLWithString:path] error:&error];
        if (error) return NO;
        self.players[path] = player;
        
        player.delegate = self;
    }
    [self openAudioSession];
    BOOL re = [player play];
    if (re) {
        [self sendMsgToObserverForPath:path msg:YJAudioPlayerStatusStart];
    }else {
        if (retry == NO) {
            [self.players removeObjectForKey:path];
        }else {
            [self sendMsgToObserverForPath:path msg:YJAudioPlayerStatusError];
            [self invalidWithPath:path];
        }
    }
    return re;
}

- (void)pauseWithPath:(NSString *)path
{
    AVAudioPlayer *player = [self playerForPath:path];
    if (!player || !player.isPlaying) return;
    
    [player pause];
    [self sendMsgToObserverForPath:path msg:YJAudioPlayerStatusPause];
}

- (void)stopWithPath:(NSString *)path
{
    AVAudioPlayer *player = [self playerForPath:path];
    if (!player) return;
    
    [player stop];
    player.currentTime = 0;
    [self sendMsgToObserverForPath:path msg:YJAudioPlayerStatusStop];
}

- (void)invalidWithPath:(NSString *)path
{
    [self stopWithPath:path];
    [self closeAudioSession];
    [self.players removeObjectForKey:path];
}

- (BOOL)openAudioSession {
    YJAudioSessionManager *mgr = [YJAudioSessionManager sharedinstance];
    [mgr addDelegate:self];
    return [mgr active] == nil;
}

- (BOOL)closeAudioSession {
    YJAudioSessionManager *mgr = [YJAudioSessionManager sharedinstance];
    [mgr removeDelegate:self];
    return [mgr invalid] == nil;
}

- (void)dealloc
{
    [self invalidWithPath:_lastPath];
    
    [self.observers removeAllObjects];
    [self.players removeAllObjects];
}

- (NSString *)pathForPlayer:(AVAudioPlayer *)player
{
    __block NSString *path;
    [self.players enumerateKeysAndObjectsUsingBlock:^(NSString *key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if ([obj isEqual:player]) {
            path = key;
            *stop = YES;
        }
    }];
    return path;
}

- (AVAudioPlayer *)playerForPath:(NSString *)path
{
    BOOL exsit = [[NSFileManager defaultManager] fileExistsAtPath:path];
    if (!exsit) return nil;
    
    AVAudioPlayer *player = self.players[path];
    if (!player) return nil;
    
    return player;
}

- (BOOL)isPlayingForPath:(NSString *)path
{
    AVAudioPlayer *player = [self playerForPath:path];
    if (!player) return NO;
    
    return player.isPlaying;
}

- (NSTimeInterval)totalTimeForPath:(NSString *)path
{
    AVAudioPlayer *player = [self playerForPath:path];
    if (!player) return 0;
    
    return player.duration;
}

- (NSTimeInterval)currentTimeForPath:(NSString *)path
{
    AVAudioPlayer *player = [self playerForPath:path];
    if (!player) return 0;
    
    return player.currentTime;
}

- (void)seekToPercent:(float)percent forPath:(NSString *)path
{
    AVAudioPlayer *player = [self playerForPath:path];
    if (!player) return;
    
    if (percent < 0) {
        percent = 0;
    }else if (percent > 1) {
        percent = 1;
    }
    
    player.currentTime = player.duration * percent;
}

#pragma mark - delegate
- (void)audioSessionInterrupt:(BOOL)interrupt
{
    if ([self isPlayingForPath:_lastPath]) {
        [self pauseWithPath:_lastPath];
        _autoBackPlay = YES;
    }else {
        _autoBackPlay = NO;
    }
}

- (void)audioSessionEnterBackground
{
    if ([self isPlayingForPath:_lastPath]) {
        [self pauseWithPath:_lastPath];
        _autoBackPlay = YES;
    }else {
        _autoBackPlay = NO;
    }
}

- (void)audioSessionReAct
{
    if (_autoBackPlay) {
        [self playWithPath:_lastPath];
        _autoBackPlay = NO;
    }
}

- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag
{
    NSString *path = [self pathForPlayer:player];
    if (!path) return;
    if (flag) {
        [self sendMsgToObserverForPath:path msg:YJAudioPlayerStatusFinish];
    }else {
        [self sendMsgToObserverForPath:path msg:YJAudioPlayerStatusStop];
    }
}

- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError *)error
{
    NSString *path = [self pathForPlayer:player];
    if (!path) return;
    
    if (error) {
        [self sendMsgToObserverForPath:path msg:YJAudioPlayerStatusError];
        [self invalidWithPath:path];
    }
}

@end








