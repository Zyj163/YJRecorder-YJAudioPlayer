//
//  YJAudioSessionManager.h
//  YJRecorder&&AudioPlayer
//
//  Created by ddn on 16/8/31.
//  Copyright © 2016年 张永俊. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "YJSingleton.h"

@protocol YJAudioSessionDelegate <NSObject>

@optional
/**
 *  插拔耳机的回调
 *
 *  @param headset 当前是否是耳机
 */
- (void)audioSessionRouteChanged:(BOOL)headset;
/**
 *  被打断或者从打断中恢复
 *
 *  @param interrupt 当前是否被打断
 */
- (void)audioSessionInterrupt:(BOOL)interrupt;
/**
 *  从后台进入前台
 */
- (void)audioSessionReAct;
/**
 *  进入后台
 */
- (void)audioSessionEnterBackground;

@end

@interface YJAudioSessionManager : NSObject

YJSingleton_h(instance)

/**
 *  主动激活
 *
 *  @return 如果失败会返回失败原因
 */
- (NSError *)active;
/**
 *  主动失效
 *
 *  @return 如果失败会返回失败原因
 */
- (NSError *)invalid;

/**
 *  添加代理
 *
 *  @param delegate 代理对象
 */
- (void)addDelegate:(id<YJAudioSessionDelegate>)delegate;

/**
 *  移除代理
 *
 *  @param delegate 代理对象
 */
- (void)removeDelegate:(id<YJAudioSessionDelegate>)delegate;

@end

