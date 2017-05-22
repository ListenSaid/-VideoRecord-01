//
//  VideoRecordVC.m
//  VideoRecord-01
//
//  Created by lskt on 2017/5/22.
//  Copyright © 2017年 SEVideo. All rights reserved.
//

#import "VideoRecordVC.h"
#import <AVFoundation/AVFoundation.h>
#import "RECoder.h"
#import <Photos/Photos.h>
static BOOL initCoder;
@interface VideoRecordVC ()<AVCaptureVideoDataOutputSampleBufferDelegate,AVCaptureAudioDataOutputSampleBufferDelegate>
//视频路径
@property(nonatomic,copy)NSString *pathStr;
@property(nonatomic,strong)UIView *showView;
//开始按钮
@property(nonatomic,strong)UIButton *startBtn;
//编码
@property(nonatomic,strong)RECoder *coder;
//队列
@property(nonatomic,copy)dispatch_queue_t captureQueue;
//捕获视频的会话
@property (strong, nonatomic) AVCaptureSession *session;
///捕捉到现实的view
@property(nonatomic,strong)AVCaptureVideoPreviewLayer *previewLayer;
//后置摄像头输入
@property (strong, nonatomic) AVCaptureDeviceInput *backCameraInput;
//前置摄像头输入
@property (strong, nonatomic) AVCaptureDeviceInput *frontCameraInput;
//麦克风输入
@property (strong, nonatomic) AVCaptureDeviceInput *audioMicInput;
//音频录制连接
@property (strong, nonatomic) AVCaptureConnection *audioConnection;
//视频录制连接
@property (strong, nonatomic) AVCaptureConnection *videoConnection;
//视频输出
@property (strong, nonatomic) AVCaptureVideoDataOutput *videoOutput;
//音频输出
@property (strong, nonatomic) AVCaptureAudioDataOutput *audioOutput;

@property(nonatomic,assign)BOOL start;

@end

@implementation VideoRecordVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    

    _pathStr = [RECoder getVideoPath];
    
    [self initSession];
    [self.session startRunning];
}
-(void)startVideoRecorder{
    _start = YES;
     [_startBtn setTitle:@"写入中" forState:UIControlStateNormal];
}

-(void)recorder{
    _start = NO;
    if (_session) {
        [_session stopRunning];
    }
    [_coder finishWithCompletionHandler:^{
        NSLog(@"录制完成=====%@",_pathStr);
        [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
            
            [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:[NSURL fileURLWithPath:_pathStr]];
        } completionHandler:^(BOOL success, NSError * _Nullable error) {
            NSLog(@"保存成功");
        }];
    }];
    [self dismissViewControllerAnimated:YES completion:nil];
}

-(void)initSession{
    

    
    
    _showView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width,  self.view.frame.size.height)];
    _showView.backgroundColor = [UIColor orangeColor];
    [self.view addSubview:_showView];
    //录制队列
    _captureQueue = dispatch_queue_create("com.capture", DISPATCH_QUEUE_SERIAL);
    NSError *error;
    //默认前摄像头输入
    AVCaptureDevice *frontDevice = [self cameraWithPosition:AVCaptureDevicePositionFront];
    _frontCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:frontDevice error:&error];
    if (error) {
        NSLog(@"获取摄像头失败、、、、");
    }
    //实例化后后摄像头
    AVCaptureDevice *backDevice = [self cameraWithPosition:AVCaptureDevicePositionBack];
    _backCameraInput = [[AVCaptureDeviceInput alloc] initWithDevice:backDevice error:&error];
    if (error) {
        NSLog(@"获取后摄像头失败、、、、");
    }
    
    //麦克风输入
    NSError *micError;
    AVCaptureDevice *audioDevice =[AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeAudio];
    _audioMicInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioDevice error:&micError];
    if (micError) {
        NSLog(@"获取麦克风失败。。。。");
    }
    
    //音视频输出
    _videoOutput = [[AVCaptureVideoDataOutput alloc] init];
    [_videoOutput setSampleBufferDelegate:self queue:self.captureQueue];
    //视频输出的设置
    NSDictionary* setcapSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithInt:kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange], kCVPixelBufferPixelFormatTypeKey,
                                    nil];
    _videoOutput.videoSettings = setcapSettings;
    _audioOutput = [[AVCaptureAudioDataOutput alloc] init];
    [_audioOutput setSampleBufferDelegate:self queue:self.captureQueue];
    
    
    
    _session = [[AVCaptureSession alloc] init];
    _session.sessionPreset = AVCaptureSessionPreset1280x720;
    //添加设备
    if ([_session canAddInput:self.frontCameraInput]) {
        [_session addInput:self.frontCameraInput];
    }
    if ([_session canAddInput:self.audioMicInput]) {
        [_session addInput:self.audioMicInput];
    }
    
    //添加输出
    if ([_session canAddOutput:self.audioOutput]) {
        [_session addOutput:self.audioOutput];
    }
    if ([_session canAddOutput:self.videoOutput]) {
        [_session addOutput:self.videoOutput];
    }
    
    //捕获view
    _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [_previewLayer setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height)];
    [self.showView.layer insertSublayer:_previewLayer atIndex:0];
    
    //音视频连接
    _audioConnection = [self.audioOutput connectionWithMediaType:AVMediaTypeAudio];
    self.videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
   // _previewLayer.connection.videoOrientation =
    
    _startBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    _startBtn.backgroundColor = [UIColor redColor];
    _startBtn.frame = CGRectMake(60, self.view.frame.size.height - 120, 60, 60);
    [_startBtn addTarget:self action:@selector(startVideoRecorder) forControlEvents:UIControlEventTouchUpInside];
    [_startBtn setTitle:@"开始" forState:UIControlStateNormal];
    
    [_showView addSubview:_startBtn];
    
    
    
    UIButton *stopBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [stopBtn setTitle:@"停止" forState:UIControlStateNormal];
    stopBtn.backgroundColor = [UIColor redColor];
    stopBtn.frame = CGRectMake(145, self.view.frame.size.height - 120, 60, 60);
    [stopBtn addTarget:self action:@selector(recorder) forControlEvents:UIControlEventTouchUpInside];
    [_showView addSubview:stopBtn];
    
}
- (AVCaptureConnection *)videoConnection {
    _videoConnection = [self.videoOutput connectionWithMediaType:AVMediaTypeVideo];
    return _videoConnection;
}

//用来返回是前置摄像头还是后置摄像头
- (AVCaptureDevice *)cameraWithPosition:(AVCaptureDevicePosition) position {
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices) {
        if ([device position] == position) {
            return device;
        }
    }
    return nil;
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection{
    //captureOutput 参数，需要判断是音频采集，还是视频采集，一般情况下，音频采集要快与视频采集
    BOOL isVideo=YES;
    @synchronized (self) {
        if (captureOutput !=_videoOutput) {
            isVideo=NO;
        }
        if ( _start&&!isVideo) {
            
            if (!initCoder) {
                initCoder = YES;
                NSLog(@"编码初始化");
                 _coder = [[RECoder alloc] initPath:_pathStr sampleBuffer:sampleBuffer];
            }
        }
        CFRetain(sampleBuffer);
        if (_start) {
            [_coder encodeFrame:sampleBuffer isVideo:isVideo];
        }
        CFRelease(sampleBuffer);
    }

    
}



//以下方法为选用方法，可自行调用，包含：开关闪光灯，转换摄像头
#pragma mark ---开关闪光灯---
-(void)FlashLight:(BOOL)isFlash{
    
    AVCaptureDevice *backDevice = [self cameraWithPosition:AVCaptureDevicePositionBack];
    if (!isFlash) { //开启
        if (backDevice.torchMode == AVCaptureTorchModeOff) {
            [backDevice lockForConfiguration:nil];
            backDevice.torchMode = AVCaptureTorchModeOn;
            backDevice.flashMode = AVCaptureFlashModeOn;
            [backDevice unlockForConfiguration];
        }
    }else{  //关闭
        if (backDevice.torchMode == AVCaptureTorchModeOn) {
            [backDevice lockForConfiguration:nil];
            backDevice.torchMode = AVCaptureTorchModeOff;
            backDevice.flashMode = AVCaptureTorchModeOff;
            [backDevice unlockForConfiguration];
        }
    }
    
}

#pragma mark ---转换摄像头---
- (void)changeCameraInputDeviceisFront:(BOOL)isFront{
    if (isFront) {
        [self.session stopRunning];
        [self.session removeInput:self.frontCameraInput];
        
        if ([self.session canAddInput:self.backCameraInput]) {
          //  [self changeCameraAnimation];
            [self.session addInput:self.backCameraInput];
        }
    }else{
        [self.session stopRunning];
        [self.session removeInput:self.backCameraInput];
        if ([self.session canAddInput:self.frontCameraInput]) {
           // [self changeCameraAnimation];
            [self.session addInput:self.frontCameraInput];
        }
    }
    self.videoConnection.videoOrientation = AVCaptureVideoOrientationPortrait;
    [self.session startRunning];
}

@end
