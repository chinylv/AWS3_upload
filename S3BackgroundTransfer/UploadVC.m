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

#import "UploadVC.h"
#import <AWSS3/AWSS3.h>
#import "Aws3FileUtils.h"
#import "BMUserDefault.h"
#import "UploadCacheTableViewCell.h"

@interface UploadVC ()

@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;

@property (weak, nonatomic) IBOutlet UITableView *tableView;


@property (nonatomic,strong) Aws3FileUtils *utility;

@property (nonatomic,strong) NSArray *cacheArray;



@end

@implementation UploadVC

- (void)viewDidLoad {
    [super viewDidLoad];
    dispatch_async(dispatch_get_main_queue(), ^{
        self.statusLabel.text = @"";
        self.progressView.progress = 0;
    });
    self.cacheArray = [Aws3FileUtils getCacheUpload];
    [self.tableView reloadData];
}

- (IBAction)start:(id)sender {
    [self uploadUtility];
}

- (void)uploadUtility{
    self.utility = [Aws3FileUtils new];
//    NSString *fileName = @"test.mp4";
    NSString *fileName = @"sss.jpg";
    NSString *path = [[NSBundle mainBundle] pathForResource:fileName ofType:nil];
    __weak UploadVC *weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        weakSelf.progressView.progress = 0;
    });
    [self.utility uploadWithPath:path fileName:fileName progressBlock:^(float progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.statusLabel.text = @"上传中";
            weakSelf.progressView.progress = progress;
        });
    } success:^{
        NSLog(@"上传成功");
        NSString *plistPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist",fileName]];
        [[BMUserDefault userDefaultWithPath:plistPath] setBool:YES forKey:@"isUploaded"];
        dispatch_async(dispatch_get_main_queue(), ^{ // 在主线程中控制view
            weakSelf.statusLabel.text = @"上传成功";
            weakSelf.progressView.progress = 1;
        });
    } failure:^(NSError *error) {
        NSString *plistPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist",fileName]];
        // 避免断点续传success后，多次调用failure （比如分为5块，最后成功后，它会调用4次failure...）
        if (![[BMUserDefault userDefaultWithPath:plistPath] boolForKey:@"isUploaded"]) {
            NSLog(@"上传失败");
            dispatch_async(dispatch_get_main_queue(), ^{ // 在主线程中控制view
                weakSelf.statusLabel.text = @"上传失败";
            });
        }
    }];
}


#pragma mark - UITableView
#pragma mark - UITableViewDelegate
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return FLT_MIN;
}
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return FLT_MIN;
}


- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.cacheArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UploadCacheTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"UploadCacheTableViewCell" forIndexPath:indexPath];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    [cell showCache:self.cacheArray[indexPath.section]];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{

}




@end
