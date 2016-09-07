//
//  YJRecorder.h
//  YJRecorder&&AudioPlayer
//
//  Created by ddn on 16/8/31.
//  Copyright © 2016年 张永俊. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum : NSUInteger {
    YJRecorderStatusStart,
    YJRecorderStatusPause,
    YJRecorderStatusStop,
    YJRecorderStatusFinish,
    YJRecorderStatusError,
} YJRecorderStatus;

typedef void(^YJRecorderStatusChanged)(YJRecorderStatus);

@interface YJRecorder : NSObject

/**
 *  根路径，默认是NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES)[0]
 */
@property (copy, nonatomic) NSString *basePath;

/**
 *  获取某个录音当前录制的时长
 *
 *  @param name 录音名
 *
 *  @return 时长
 */
- (NSTimeInterval)currentTimeForName:(NSString *)name;

/**
 *  开始一个录音
 *
 *  @param name 录音名
 *
 *  @return 是否成功
 */
- (BOOL)startWithName:(NSString *)name;

/**
 *  暂停一个正在录制的录音
 *
 *  @param name 录音名
 */
- (void)pauseWithName:(NSString *)name;

/**
 *  停止一个正在录制的录音（保留录音文件）
 *
 *  @param name 录音名
 */
- (void)stopWithName:(NSString *)name;

/**
 *  销毁录音并删除文件
 *
 *  @param name 录音名
 */
- (void)invalidWithName:(NSString *)name;

/**
 *  清除指定录音名的本地文件
 *
 *  @param name 录音名
 */
- (void)clearFile:(NSString *)name;

/**
 *  获取指定录音的本地路径
 *
 *  @param name 录音名
 *
 *  @return 本地路径
 */
- (NSString *)fileWithName:(NSString *)name;

/**
 *  判断指定的录音是否正在进行
 *
 *  @param name 录音名
 *
 *  @return 是否
 */
- (BOOL)isRecordingForName:(NSString *)name;

/**
 *  为指定录音状态改变添加监听
 *
 *  @param name          录音名
 *  @param statusChanged 状态改变时的执行代码
 */
- (void)addObserverForName:(NSString *)name whenStatusChanged:(YJRecorderStatusChanged)statusChanged;

/**
 *  为指定录音移除监听
 *
 *  @param name 录音名
 */
- (void)removeObserverForName:(NSString *)name;

@end
