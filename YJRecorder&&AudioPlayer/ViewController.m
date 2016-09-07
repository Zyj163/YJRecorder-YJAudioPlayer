//
//  ViewController.m
//  YJRecorder&&AudioPlayer
//
//  Created by ddn on 16/8/31.
//  Copyright © 2016年 张永俊. All rights reserved.
//

#import "ViewController.h"
#import "YJRecorder.h"
#import "YJAudioPlayer.h"

@interface ViewController ()

@property (strong, nonatomic) YJRecorder *recorder;
@property (strong, nonatomic) YJAudioPlayer *player;

@property (weak, nonatomic) IBOutlet UIButton *recorderBtn;
@property (weak, nonatomic) IBOutlet UIButton *playerBtn;
@property (weak, nonatomic) IBOutlet UILabel *recordTimeLabel;
@property (weak, nonatomic) IBOutlet UISlider *playProgress;

@property (strong, nonatomic) NSTimer *timer;

@end

@implementation ViewController

NSString *name = @"myaudio";
- (void)viewDidLoad {
    [super viewDidLoad];
    
    //录音
    _recorder = [YJRecorder new];
    
    __weak typeof(self) ws = self;
    [_recorder addObserverForName:name whenStatusChanged:^(YJRecorderStatus status) {
        switch (status) {
            case YJRecorderStatusStart:
                ws.recorderBtn.selected = YES;
                ws.playerBtn.enabled = NO;
                ws.timer.fireDate = [NSDate date];
                break;
            case YJRecorderStatusPause:
                ws.recorderBtn.selected = NO;
                ws.playerBtn.enabled = YES;
                ws.timer.fireDate = [NSDate distantFuture];
                break;
            case YJRecorderStatusStop:
                ws.recorderBtn.selected = NO;
                ws.playerBtn.enabled = YES;
                ws.timer.fireDate = [NSDate distantFuture];
                break;
            case YJRecorderStatusFinish:
                ws.recorderBtn.selected = NO;
                ws.playerBtn.enabled = YES;
                ws.timer.fireDate = [NSDate distantFuture];
                break;
            case YJRecorderStatusError:
                ws.recorderBtn.selected = NO;
                ws.playerBtn.enabled = YES;
                ws.timer.fireDate = [NSDate distantFuture];
                break;
        }
    }];
    
    //播放
    _player = [YJAudioPlayer new];
    
    [_player addObserverForPath:[_recorder fileWithName:name] whenStatusChanged:^(YJAudioPlayerStatus status) {
        switch (status) {
            case YJAudioPlayerStatusStart:
                ws.playerBtn.selected = YES;
                ws.recorderBtn.enabled = NO;
                ws.timer.fireDate = [NSDate date];
                break;
            case YJAudioPlayerStatusPause:
                ws.playerBtn.selected = NO;
                ws.recorderBtn.enabled = YES;
                ws.timer.fireDate = [NSDate distantFuture];
                break;
            case YJAudioPlayerStatusStop:
                ws.playerBtn.selected = NO;
                ws.recorderBtn.enabled = YES;
                ws.timer.fireDate = [NSDate distantFuture];
                ws.playProgress.value = 0;
                break;
            case YJAudioPlayerStatusFinish:
                ws.playerBtn.selected = NO;
                ws.recorderBtn.enabled = YES;
                ws.timer.fireDate = [NSDate distantFuture];
                ws.playProgress.value = 1;
                break;
            case YJAudioPlayerStatusError:
                ws.playerBtn.selected = NO;
                ws.recorderBtn.enabled = YES;
                ws.timer.fireDate = [NSDate distantFuture];
                ws.playProgress.value = 1;
                break;
        }
    }];
    
    //计时器
    _timer = [NSTimer timerWithTimeInterval:0.1 target:self selector:@selector(updateWithTimer:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:ws.timer forMode:NSRunLoopCommonModes];
    _timer.fireDate = [NSDate distantFuture];
}

- (void)updateWithTimer:(NSTimer *)timer
{
    if ([_recorder isRecordingForName:name]) {
        NSTimeInterval time = [_recorder currentTimeForName:name];
        _recordTimeLabel.text = [NSString stringWithFormat:@"%02d:%02d",
                                 (int)time/60,
                                 (int)time%60];
    }else if ([_player isPlayingForPath:[_recorder fileWithName:name]]) {
        _playProgress.value = [_player currentTimeForPath:[_recorder fileWithName:name]] / [_player totalTimeForPath:[_recorder fileWithName:name]];
    }
}

- (IBAction)recorde:(UIButton *)sender {
    
    if (!sender.selected) {
        [_recorder startWithName:name];
    }else {
        [_recorder stopWithName:name];
    }
}
- (IBAction)play:(UIButton *)sender {
    
    if (!sender.selected) {
        [_player playWithPath:[_recorder fileWithName:name]];
    }else {
        [_player stopWithPath:[_recorder fileWithName:name]];
    }
}
- (IBAction)changeProgress:(UISlider *)sender {
    [_player seekToPercent:sender.value forPath:[_recorder fileWithName:name]];
}

- (void)dealloc
{
    [_recorder removeObserverForName:name];
    [_player removeObserverForPath:[_recorder fileWithName:name]];
}

@end
