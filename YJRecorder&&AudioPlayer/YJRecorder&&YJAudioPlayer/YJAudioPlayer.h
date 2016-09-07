//
//  YJAudioPlayer.h
//  YJRecorder&&AudioPlayer
//
//  Created by ddn on 16/8/31.
//  Copyright © 2016年 张永俊. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    YJAudioPlayerStatusStart,
    YJAudioPlayerStatusPause,
    YJAudioPlayerStatusStop,
    YJAudioPlayerStatusFinish,
    YJAudioPlayerStatusError,
} YJAudioPlayerStatus;

typedef void(^YJAudioPlayerStatusChanged)(YJAudioPlayerStatus);

@interface YJAudioPlayer : NSObject

/**
 *  播放指定播放器
 *
 *  @param path 路径
 *
 *  @return 是否播放成功
 */
- (BOOL)playWithPath:(NSString *)path;

/**
 *  暂停指定播放器
 *
 *  @param path 路径
 */
- (void)pauseWithPath:(NSString *)path;

/**
 *  停止指定播放器（仍保留播放器）
 *
 *  @param path 路径
 */
- (void)stopWithPath:(NSString *)path;

/**
 *  销毁已经为指定路径创建好的播放器
 *
 *  @param path 路径
 */
- (void)invalidWithPath:(NSString *)path;

/**
 *  指定路径的播放器的总时长
 *
 *  @param path 路径
 *
 *  @return 时长
 */
- (NSTimeInterval)totalTimeForPath:(NSString *)path;

/**
 *  指定路径的播放器的当前时长
 *
 *  @param path 路径
 *
 *  @return 时长
 */
- (NSTimeInterval)currentTimeForPath:(NSString *)path;

/**
 *  按百分比改变指定的播放器的播放进度
 *
 *  @param percent 百分比
 *  @param path    路径
 */
- (void)seekToPercent:(float)percent forPath:(NSString *)path;

/**
 *  判断指定路径的播放器是否正在播放
 *
 *  @param path 路径
 *
 *  @return 是否
 */
- (BOOL)isPlayingForPath:(NSString *)path;

/**
 *  为指定播放器状态改变添加监听
 *
 *  @param path          路径
 *  @param statusChanged 状态改变时的执行代码
 */
- (void)addObserverForPath:(NSString *)path whenStatusChanged:(YJAudioPlayerStatusChanged)statusChanged;

/**
 *  为指定播放器移除监听
 *
 *  @param name 路径
 */
- (void)removeObserverForPath:(NSString *)path;

@end
