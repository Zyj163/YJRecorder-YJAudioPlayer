//
//  YJTool.m
//  YJRecorder&&AudioPlayer
//
//  Created by 张永俊 on 2017/7/24.
//  Copyright © 2017年 张永俊. All rights reserved.
//

#import "YJTool.h"
#import <AVFoundation/AVFoundation.h>
#import "lame.h"

@implementation YJTool

+ (void)addAudioFile:(NSString *)fromPath toAudioFile:(NSString *)toPath savePath:(NSString *)savePath completion:(void(^)())handler
{
    //获取音频资源
    AVURLAsset *asset1 = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:toPath]];
    AVURLAsset *asset2 = [AVURLAsset assetWithURL:[NSURL fileURLWithPath:fromPath]];
    
    //获取素材轨道
    AVAssetTrack *track1 = [asset1 tracksWithMediaType:AVMediaTypeAudio].firstObject;
    AVAssetTrack *track2 = [asset2 tracksWithMediaType:AVMediaTypeAudio].firstObject;
    
    //结合了媒体数据，可以看成是track(音频轨道)的集合，用来合成音视频
    AVMutableComposition *composition = [AVMutableComposition composition];
    
    //用来表示一个track，包含了媒体类型、音轨标识符等信息，可以插入、删除、缩放track片段
    AVMutableCompositionTrack *track = [composition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:0];
    
    //音频合并／插入音轨文件
    [track insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset1.duration) ofTrack:track1 atTime:kCMTimeZero error:nil];
    [track insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset2.duration) ofTrack:track2 atTime:asset1.duration error:nil];
    
    //转码并导出为指定格式
    AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:composition presetName:AVAssetExportPresetAppleM4A];
    session.outputURL = [NSURL fileURLWithPath:savePath];
    session.outputFileType = AVFileTypeAppleM4A;
    
    [session exportAsynchronouslyWithCompletionHandler:^{
        if (handler) {
            handler();
        }
    }];
    
}

+ (void)subAudioWithPath:(NSString *)sourcePath fromTimeSec:(NSTimeInterval)fromSec toTimeSec:(NSTimeInterval)toSec savePath:(NSString *)savePath completion:(void(^)())handler
{
    NSURL *sourceUrl = [NSURL fileURLWithPath:sourcePath];
    AVURLAsset *sourceAsset = [AVURLAsset URLAssetWithURL:sourceUrl options:nil];
    
    //创建音频输出会话
    AVAssetExportSession *session = [AVAssetExportSession exportSessionWithAsset:sourceAsset presetName:AVAssetExportPresetAppleM4A];
    CMTime _startTime = CMTimeMake(fromSec, 1);
    CMTime _stopTime = CMTimeMake(toSec, 1);
    CMTimeRange range = CMTimeRangeMake(_startTime, _stopTime);
    
    //设置音频输出会话并执行
    session.outputURL = [NSURL fileURLWithPath:savePath];
    session.outputFileType = AVFileTypeAppleM4A;
    session.timeRange = range;
    
    [session exportAsynchronouslyWithCompletionHandler:^{
        if (handler) {
            handler();
        }
    }];
}

+ (NSString *)audioToMP3:(NSString *)sourcePath
{
    // 输入路径
    NSString *inPath = sourcePath;
    
    // 判断输入路径是否存在
    NSFileManager *fm = [NSFileManager defaultManager];
    if (![fm fileExistsAtPath:sourcePath])
    {
        NSLog(@"文件不存在");
    }
    
    // 输出路径
    NSString *outPath = [[sourcePath stringByDeletingPathExtension] stringByAppendingString:@".mp3"];
    
    
    @try {
        size_t read;
        int write;
        
        FILE *pcm = fopen([inPath cStringUsingEncoding:1], "rb");  //source 被转换的音频文件位置
        fseek(pcm, 4*1024, SEEK_CUR);                                   //skip file header
        FILE *mp3 = fopen([outPath cStringUsingEncoding:1], "wb");  //output 输出生成的Mp3文件位置
        
        size_t PCM_SIZE = 8192;
        const int MP3_SIZE = 8192;
        short int pcm_buffer[PCM_SIZE*2];
        unsigned char mp3_buffer[MP3_SIZE];
        
        //        lame_t lame = lame_init();
        //        lame_set_in_samplerate(lame, 11025.0);
        //        lame_set_VBR(lame, vbr_default);
        //        lame_init_params(lame);
        
        lame_t lame = lame_init();
        lame_set_num_channels(lame, 1);
        lame_set_in_samplerate(lame, 11025.0);
        lame_set_brate(lame, 88);
        lame_set_mode(lame, 1);
        lame_set_quality(lame, 2);
        lame_init_params(lame);
        
        
        do {
            size_t size = (size_t)(2 * sizeof(short int));
            read = fread(pcm_buffer, size, PCM_SIZE, pcm);
            if (read == 0)
                write = lame_encode_flush(lame, mp3_buffer, MP3_SIZE);
            else
                write = lame_encode_buffer_interleaved(lame, pcm_buffer, (int)read, mp3_buffer, MP3_SIZE);
            
            fwrite(mp3_buffer, write, 1, mp3);
            
        } while (read != 0);
        
        lame_close(lame);
        fclose(mp3);
        fclose(pcm);
    }
    @catch (NSException *exception) {
        NSLog(@"%@",[exception description]);
    }
    @finally {
        NSLog(@"MP3生成成功:");
        return outPath;
    }
}

@end
















