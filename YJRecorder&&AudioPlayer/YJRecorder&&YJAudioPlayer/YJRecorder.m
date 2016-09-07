//
//  YJRecorder.m
//  YJRecorder&&AudioPlayer
//
//  Created by ddn on 16/8/31.
//  Copyright © 2016年 张永俊. All rights reserved.
//

#define RecordFile(name) ([self.basePath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.aac", name]])

#import "YJRecorder.h"
#import <AVFoundation/AVFoundation.h>
#import "YJAudioSessionManager.h"


@interface YJRecorder() <YJAudioSessionDelegate, AVAudioRecorderDelegate>

@property (copy, nonatomic) NSDictionary *setting;

@property (strong, nonatomic) NSMutableDictionary *recorders;

@property (strong, nonatomic) NSMutableDictionary *observers;

@property (copy, nonatomic) NSString *lastName;

@end

@implementation YJRecorder

- (instancetype)init
{
    self = [super init];
    if (self) {
        self.basePath = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0];
    }
    return self;
}

- (NSDictionary *)setting
{
    if (!_setting) {
        _setting = @{AVSampleRateKey:          @16000.0,
                     AVFormatIDKey:            @(kAudioFormatMPEG4AAC),
                     AVNumberOfChannelsKey:    @1,
                     AVEncoderAudioQualityKey: @(AVAudioQualityHigh),
                     AVLinearPCMBitDepthKey:   @8,
                     AVLinearPCMIsFloatKey:    @(YES)};
    }
    return _setting;
}

- (NSMutableDictionary *)recorders
{
    if (!_recorders) {
        _recorders = [NSMutableDictionary dictionary];
    }
    return _recorders;
}

- (NSMutableDictionary *)observers
{
    if (!_observers) {
        _observers = [NSMutableDictionary dictionary];
    }
    return _observers;
}

- (void)addObserverForName:(NSString *)name whenStatusChanged:(YJRecorderStatusChanged)statusChanged
{
    self.observers[name] = statusChanged;
}

- (void)removeObserverForName:(NSString *)name
{
    [self.observers removeObjectForKey:name];
}

- (void)sendMsgToObserverForName:(NSString *)name msg:(YJRecorderStatus)status
{
    YJRecorderStatusChanged block = self.observers[name];
    if (block) {
        block(status);
    }
}

- (BOOL)prepareWithName:(NSString *)name
{
    AVAudioRecorder *recorder = self.recorders[name];
    if (!recorder) {
        NSError *error;
        NSURL *url = [NSURL URLWithString:[self fileWithName:name]];
        recorder = [[AVAudioRecorder alloc]initWithURL:url settings:self.setting error:&error];
        recorder.delegate = self;
        if (error) {
            recorder = nil;
        }
    }
    if (!recorder) {
        return NO;
    }
    self.recorders[name] = recorder;
    return [recorder prepareToRecord];
}

- (BOOL)startWithName:(NSString *)name
{
    [self pauseWithName:_lastName];
    
    _lastName = name;
    if ([self prepareWithName:name]) {
        AVAudioRecorder *recorder = self.recorders[name];
        if (recorder.isRecording) {
            return YES;
        }
        [self openAudioSession];
        BOOL re = [recorder record];
        if (re) {
            [self sendMsgToObserverForName:name msg:YJRecorderStatusStart];
        }else {
            [self sendMsgToObserverForName:name msg:YJRecorderStatusError];
            [self invalidWithName:name];
        }
    }
    return NO;
}

- (void)stopWithName:(NSString *)name
{
    AVAudioRecorder *recorder = [self recorderForName:name];
    if (!recorder) {
        return;
    }
    [recorder stop];
    
    [self sendMsgToObserverForName:name msg:YJRecorderStatusStop];
    
    [self.recorders removeObjectForKey:name];
    
    [self closeAudioSession];
}

- (void)clearFile:(NSString *)name
{
    [self stopWithName:name];
    remove([self fileWithName:name].UTF8String);
}

- (NSTimeInterval)currentTimeForName:(NSString *)name
{
    AVAudioRecorder *recorder = [self recorderForName:name];
    return recorder.currentTime;
}

- (void)invalidWithName:(NSString *)name
{
    [self stopWithName:name];
    [self clearFile:name];
}

- (NSString *)fileWithName:(NSString *)name
{
    return RecordFile(name);
}

- (NSString *)nameForRecorder:(AVAudioRecorder *)recorder
{
    __block NSString *name;
    [self.recorders enumerateKeysAndObjectsUsingBlock:^(NSString *key, AVAudioRecorder *obj, BOOL * _Nonnull stop) {
        if ([obj isEqual:recorder]) {
            name = key;
            *stop = YES;
        }
    }];
    return name;
}

- (AVAudioRecorder *)recorderForName:(NSString *)name
{
    BOOL exist = [[NSFileManager defaultManager] fileExistsAtPath:[self fileWithName:name]];
    if (!exist) return nil;
    
    AVAudioRecorder *recorder = self.recorders[name];
    if (!recorder) return nil;
    
    return recorder;
}

- (void)pauseWithName:(NSString *)name
{
    AVAudioRecorder *recorder = [self recorderForName:name];
    if (!recorder) {
        return;
    }
    [recorder pause];
    
    [self sendMsgToObserverForName:name msg:YJRecorderStatusPause];
}

- (BOOL)isRecordingForName:(NSString *)name
{
    AVAudioRecorder *recorder = [self recorderForName:name];
    if (!recorder) {
        return NO;
    }
    return recorder.isRecording;
}

- (BOOL)openAudioSession
{
    YJAudioSessionManager *mgr = [YJAudioSessionManager sharedinstance];
    [mgr addDelegate:self];
    return [mgr active] == nil;
}

- (BOOL)closeAudioSession
{
    YJAudioSessionManager *mgr = [YJAudioSessionManager sharedinstance];
    [mgr removeDelegate:self];
    return [mgr invalid] == nil;
}

- (void)dealloc
{
    if (_lastName) {
        [self invalidWithName:_lastName];
    }
    [self.observers removeAllObjects];
    [self.recorders removeAllObjects];
}

#pragma mark - delegate
- (void)audioSessionInterrupt:(BOOL)interrupt
{
    [self pauseWithName:_lastName];
}

- (void)audioSessionEnterBackground
{
    [self pauseWithName:_lastName];
}

- (void)audioSessionReAct
{
    
}

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag
{
    NSString *name = [self nameForRecorder:recorder];
    if (!name) return;
    
    if (flag) {
        [self sendMsgToObserverForName:name msg:YJRecorderStatusFinish];
    }else {
        [self sendMsgToObserverForName:name msg:YJRecorderStatusStop];
    }
}

- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError *)error
{
    NSString *name = [self nameForRecorder:recorder];
    if (!name) return;
    
    if (error) {
        [self sendMsgToObserverForName:name msg:YJRecorderStatusError];
        [self invalidWithName:name];
    }
}

@end

