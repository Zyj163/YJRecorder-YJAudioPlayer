//
//  YJTool.h
//  YJRecorder&&AudioPlayer
//
//  Created by 张永俊 on 2017/7/24.
//  Copyright © 2017年 张永俊. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface YJTool : NSObject

+ (void)addAudioFile:(NSString *)fromPath toAudioFile:(NSString *)toPath savePath:(NSString *)savePath completion:(void(^)())handler;

+ (void)subAudioWithPath:(NSString *)sourcePath fromTimeSec:(NSTimeInterval)fromSec toTimeSec:(NSTimeInterval)toSec savePath:(NSString *)savePath completion:(void(^)())handler;

+ (NSString *)audioToMP3: (NSString *)sourcePath;

@end
