//
//  Aws3CacheUpload.h
//  S3UtilitySample
//
//  Created by cuiys on 2019/4/25.
//  Copyright © 2019 Amazon. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Aws3CacheUpload : NSObject

@property (nonatomic,strong) NSString *fileName;
@property (nonatomic,assign) float progress;

@end

NS_ASSUME_NONNULL_END
