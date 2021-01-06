//
//  UploadCacheTableViewCell.h
//  S3UtilitySample
//
//  Created by cuiys on 2019/4/25.
//  Copyright © 2019 Amazon. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Aws3FileUtils.h"

NS_ASSUME_NONNULL_BEGIN

@interface UploadCacheTableViewCell : UITableViewCell

@property (weak, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UILabel *fileLabel;
@property (weak, nonatomic) IBOutlet UIButton *actionBtn;

@property (weak, nonatomic) Aws3CacheUpload *cache;

@property (nonatomic,strong) Aws3FileUtils *utility;

- (void)showCache:(Aws3CacheUpload *)cache;

@end

NS_ASSUME_NONNULL_END
