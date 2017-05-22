//
//  RECoder.m
//  SecretCalculator
//
//  Created by lskt on 2017/4/25.
//  Copyright © 2017年 张伟. All rights reserved.
//

#import "RECoder.h"
#define Video_PATH [NSString stringWithFormat:@"%@/tmp/videos",NSHomeDirectory()] //视频存储路径
@interface RECoder ()
//媒体写入对象
@property(nonatomic,strong)AVAssetWriter *writer;
//视频写入
@property (nonatomic, strong) AVAssetWriterInput *videoInput;
//音频写入
@property (nonatomic, strong) AVAssetWriterInput *audioInput;
//写入路径
@property (nonatomic, strong) NSString *path;

@end

@implementation RECoder

-(instancetype)initPath:(NSString *)path sampleBuffer:(CMSampleBufferRef)sampleBuffer{
    
    if (self=[super init]) {
        self.path = path;
        //先把路径下的文件给删除掉，保证录制的文件是最新的
        [[NSFileManager defaultManager] removeItemAtPath:self.path error:nil];
        NSURL* url = [NSURL fileURLWithPath:self.path];
        //初始化写入媒体类型为MP4类型
        _writer = [AVAssetWriter assetWriterWithURL:url fileType:AVFileTypeMPEG4 error:nil];
        //使其更适合在网络上播放
        _writer.shouldOptimizeForNetworkUse = YES;
        
        //初始化视频输入
        NSDictionary* settings = [NSDictionary dictionaryWithObjectsAndKeys:
                                  AVVideoCodecH264, AVVideoCodecKey,
                                  [NSNumber numberWithInteger: 720], AVVideoWidthKey,
                                  [NSNumber numberWithInteger: 1280], AVVideoHeightKey,
                                  nil];
        //初始化视频写入类
        _videoInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo outputSettings:settings];
        //表明输入是否应该调整其处理为实时数据源的数据
        _videoInput.expectsMediaDataInRealTime = YES;
        //将视频输入源加入
        [_writer addInput:_videoInput];
        
        //初始化音频输入
         CMFormatDescriptionRef fmt = CMSampleBufferGetFormatDescription(sampleBuffer);
        const AudioStreamBasicDescription *asbd = CMAudioFormatDescriptionGetStreamBasicDescription(fmt);
        
        int channels = asbd->mSampleRate;
        Float64 samplerate = asbd->mChannelsPerFrame;
        if (channels != 0 &&sampleBuffer !=0) {
            //音频的一些配置包括音频各种这里为AAC,音频通道、采样率和音频的比特率
            NSDictionary *setting = [NSDictionary dictionaryWithObjectsAndKeys:
                                     [ NSNumber numberWithInt: kAudioFormatMPEG4AAC], AVFormatIDKey,
                                     [ NSNumber numberWithInt: samplerate], AVNumberOfChannelsKey,
                                     [ NSNumber numberWithFloat: channels], AVSampleRateKey,
                                     [ NSNumber numberWithInt: 128000], AVEncoderBitRateKey,
                                     nil];
            //初始化音频写入类
            _audioInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeAudio outputSettings:setting];
            //表明输入是否应该调整其处理为实时数据源的数据
            _audioInput.expectsMediaDataInRealTime = YES;
            //将音频输入源加入
            [_writer addInput:_audioInput];
        }
        
    }
    return self;
}

- (BOOL)encodeFrame:(CMSampleBufferRef)sampleBuffer isVideo:(BOOL)video{
    if (CMSampleBufferDataIsReady(sampleBuffer)) {
        if (_writer.status == AVAssetWriterStatusUnknown) {
            NSLog(@"开始写入文件");
            CMTime startTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer);
            [_writer startWriting];
            [_writer startSessionAtSourceTime:startTime];
            if (_writer.status == AVAssetWriterStatusFailed) {
             //   NSLog(@"视频写入失败writer error %@", _writer.error.localizedDescription);
                return NO;
            }
        }
        if (video) {
         //   NSLog(@"写入视频文件");
            [_videoInput appendSampleBuffer:sampleBuffer];
            return YES;
        }else{
            [_audioInput appendSampleBuffer:sampleBuffer];
         //   NSLog(@"写入音频文件");
            return YES;
        }
    }
    return NO;
}
- (void)finishWithCompletionHandler:(void (^)(void))handler {
    [_writer finishWritingWithCompletionHandler: handler];
}
+(NSString *)getVideoPath{
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    BOOL isExist = [fileManager fileExistsAtPath:Video_PATH];
    if (isExist) {
    }else {
        // 如果不存在就创建文件夹
        [fileManager createDirectoryAtPath:Video_PATH withIntermediateDirectories:NO attributes:nil error:nil];
    }
    
    NSTimeInterval now = [[NSDate date] timeIntervalSince1970];
    NSDateFormatter * formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"HHmmss"];
    NSDate * NowDate = [NSDate dateWithTimeIntervalSince1970:now];
    ;
    NSString * timeStr = [formatter stringFromDate:NowDate];
    NSString *fileName = [NSString stringWithFormat:@"%@.%@",timeStr,@"mp4"];
    
    return [NSString stringWithFormat:@"%@/%@",Video_PATH,fileName];
}
    

@end
