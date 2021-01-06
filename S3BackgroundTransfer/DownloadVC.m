/*
 * Copyright 2010-2018 Amazon.com, Inc. or its affiliates. All Rights Reserved.
 *
 * Licensed under the Apache License, Version 2.0 (the "License").
 * You may not use this file except in compliance with the License.
 * A copy of the License is located at
 *
 * http://aws.amazon.com/apache2.0
 *
 * or in the "license" file accompanying this file. This file is distributed
 * on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either
 * express or implied. See the License for the specific language governing
 * permissions and limitations under the License.
 */

#import "DownloadVC.h"
#import "AppDelegate.h"
#import <AWSS3/AWSS3.h>
#import "Aws3FileUtils.h"

@interface DownloadVC ()

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (nonatomic,strong) Aws3FileUtils *utility;

@end

@implementation DownloadVC

- (void)viewDidLoad {
    [super viewDidLoad];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressView.progress = 0;
        self.statusLabel.text = @"";
    });
}

- (void)download{
    self.utility = [Aws3FileUtils new];
    
    self.progressView.progress = 0;
    self.statusLabel.text = @"开始下载";
    
    __weak DownloadVC *weakSelf = self;

    [self.utility downloadWithFileName:@"sss.jpg" progressBlock:^(float progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.statusLabel.text = @"下载中";
            weakSelf.progressView.progress = progress;
        });
    } success:^(NSData *data) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.statusLabel.text = @"下载成功";
            weakSelf.imageView.image = [UIImage imageWithData:data];
        });
    } failure:^(NSError *error) {
        NSLog(@"下载失败--chiny--%@", error);
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.statusLabel.text = @"下载失败";
        });
    }];
}

- (IBAction)start:(id)sender {
    [self download];
}

@end
