//
//  ViewController.m
//  VideoRecord-01
//
//  Created by lskt on 2017/5/22.
//  Copyright © 2017年 SEVideo. All rights reserved.
//

#import "ViewController.h"
#import "VideoRecordVC.h"
@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    
    
    
    
    
    
}

- (IBAction)sender:(id)sender {
    VideoRecordVC *v = [VideoRecordVC new];
    [self presentViewController:v animated:YES completion:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
