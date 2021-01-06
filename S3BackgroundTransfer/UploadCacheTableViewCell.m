//
//  UploadCacheTableViewCell.m
//  S3UtilitySample
//
//  Created by cuiys on 2019/4/25.
//  Copyright © 2019 Amazon. All rights reserved.
//

#import "UploadCacheTableViewCell.h"

@implementation UploadCacheTableViewCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];
    // Configure the view for the selected state
}

- (void)showCache:(Aws3CacheUpload *)cache{
    self.utility = [Aws3FileUtils new];
    self.cache = cache;
    self.fileLabel.text = cache.fileName;
    self.progressView.progress = cache.progress;
}

- (IBAction)clickBtn:(id)sender{
    self.actionBtn.hidden = YES;
    __weak UploadCacheTableViewCell *weakSelf = self;
    [self.utility uploadWithCacheUpload:self.cache progressBlock:^(float progress) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.progressView.progress = progress;

        });
    } success:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.fileLabel.text = @"上传成功";
        });
    } failure:^(NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.fileLabel.text = @"上传失败";
        });
    }];
}

@end
