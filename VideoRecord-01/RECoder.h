//
//  RECoder.h
//  SecretCalculator
//
//  Created by lskt on 2017/4/25.
//  Copyright © 2017年 张伟. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
@interface RECoder : NSObject

-(instancetype)initPath:(NSString *)path sampleBuffer:(CMSampleBufferRef)sampleBuffer;
///写入数据
- (BOOL)encodeFrame:(CMSampleBufferRef)sampleBuffer isVideo:(BOOL)video;
///写入完成
- (void)finishWithCompletionHandler:(void (^)(void))handler;
///随机生成一个视频存放地址
+(NSString *)getVideoPath;
@end
