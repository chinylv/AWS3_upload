//
//  Aws3FileUtils.h
//  S3UtilitySample
//
//  Created by cuiys on 2019/4/25.
//  Copyright © 2019 Amazon. All rights reserved.
//

#import <AWSS3/AWSS3.h>
#import "Aws3CacheUpload.h"

@interface Aws3FileUtils : NSObject

//AWS配置
+(void)configAWS;

//获取缓存池数据列表
+ (NSArray<Aws3CacheUpload *> *)getCacheUpload;
//文件本地是否有缓存
- (BOOL)hasCache:(NSString *)fileName;

//断点续传缓存数据
- (void)uploadWithCacheUpload:(Aws3CacheUpload *)cacheUpload progressBlock:(void (^)(float progress))progressBlock success:(void (^)(void))completion failure:(void (^)(NSError *error))failure;

/*
 上传接口
 文件大于某个值,分片上传(支持断点续传, 文件名为唯一标识)
 参数定义
 filePath:本地路径
 fileName:上传文件名
 progressBlock:进度
 */
- (void)uploadWithPath:(NSString *)filePath fileName:(NSString *)fileName progressBlock:(void (^)(float progress))progressBlock success:(void (^)(void))completion failure:(void (^)(NSError *error))failure;

/*
 上传接口
 文件大于某个值,分片上传(支持断点续传, 文件名为唯一标识)
 参数定义
 fileData:文件内容
 fileName:上传文件名
 progressBlock:进度
 */
- (void)uploadWithData:(NSData *)fileData fileName:(NSString *)fileName progressBlock:(void (^)(float progress))progressBlock success:(void (^)(void))completion failure:(void (^)(NSError *error))failure;


/*
 下载接口
 参数定义
 fileName:下载文件名
 progressBlock:进度
 */

- (void)downloadWithFileName:(NSString *)fileName progressBlock:(void (^)(float progress))progressBlock success:(void (^)(NSData *data))completion failure:(void (^)(NSError *error))failure;

@end

