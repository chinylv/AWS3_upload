//
//  Aws3FileUtils.m
//  S3UtilitySample
//
//  Created by cuiys on 2019/4/25.
//  Copyright © 2019 Amazon. All rights reserved.
//

#import "Aws3FileUtils.h"
#import "BMUserDefault.h"

#define AccessKey           @"Your AccessKey"
#define SecretKey           @"Your SecretKey"
#define HOST                @"Your HOST"
#define S3BucketName        @"Your S3BucketName"
// http头一定不能少，否则会遇到NSURLErrorDomain Code=-1002

// 在达到100MB的文件，才进行断点续传
#define transferManagerMinimumPartSize (10 * 1024 * 1024)
#define resumableUploadFileLimit (100 * 1024 * 1024)


@interface Aws3FileUtils()

@property (nonatomic, strong) BMUserDefault *userDefault;
@property (nonatomic, strong) NSString *uploadId;
@property (nonatomic, strong) NSMutableArray *mutArray;
@property (nonatomic, strong) NSMutableArray *cacheArray;

@end


@implementation Aws3FileUtils
//获取缓存池数据列表
+ (NSArray<Aws3CacheUpload *> *)getCacheUpload{
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *tempPath = NSTemporaryDirectory();
    NSDirectoryEnumerator *direnum = [manager enumeratorAtPath:tempPath];
    NSMutableArray *files = [NSMutableArray arrayWithCapacity:42];
    for (NSString *filename in direnum) {
        if ([[filename pathExtension] isEqualToString:@"plist"]) {
            [files addObject:filename];
        }
    }
    NSMutableArray *cacheArray = [NSMutableArray array];
    //快速枚举，输出结果
    for (NSString *filename in files) {
        NSString *plistPath =[NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@",filename]];
        NSDictionary *dic = [NSDictionary dictionaryWithContentsOfFile:plistPath];
        if (dic[@"uploadId"]) {
            Aws3CacheUpload *cache = [Aws3CacheUpload new];
            cache.fileName = dic[@"fileName"];
            NSArray *partArray = dic[@"partArray"];
            NSData *fileData = dic[@"fileData"];
            if (fileData) {
                long long size = 0;
                for (int j = 0; j < partArray.count; j++) {
                    NSDictionary *cacheObj = partArray[j];
                    NSNumber *sizeNum = cacheObj[@"size"];
                    size += [sizeNum longLongValue];
                }
                cache.progress = (size/ceil((double)[fileData length]));
                [cacheArray addObject:cache];
            }else{
                NSFileManager *fileManager = [NSFileManager defaultManager];
                [fileManager removeItemAtPath:plistPath error:nil];
            }

        }
    }
    return cacheArray;
}
//断点续传缓存数据
- (void)uploadWithCacheUpload:(Aws3CacheUpload *)cacheUpload progressBlock:(void (^)(float progress))progressBlock success:(void (^)(void))completion failure:(void (^)(NSError *error))failure{
    NSString *plistPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist",cacheUpload.fileName]];
    self.userDefault = [BMUserDefault userDefaultWithPath:plistPath];
    if ([self.userDefault objectForKey:@"uploadId"]) {
        [self uploadWithData:[self.userDefault objectForKey:@"fileData"] fileName:cacheUpload.fileName progressBlock:progressBlock success:completion failure:failure];
    }else{
        NSString *domain = @"com.CTYun.SDK.ErrorDomain";
        NSString *desc = @"无缓存数据";
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : desc };
        
        NSError *error = [NSError errorWithDomain:domain
                                             code:-101
                                         userInfo:userInfo];
        failure(error);
    }
}

//文件本地是否有缓存
- (BOOL)hasCache:(NSString *)fileName{
    NSString *plistPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist",fileName]];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    return [fileManager fileExistsAtPath:plistPath];
}

- (id)init{
    if (self = [super init]) {
        self.mutArray = [NSMutableArray array];
        self.cacheArray = [NSMutableArray array];
    }
    return self;
}


+(void)configAWS{
    AWSStaticCredentialsProvider *credentialsProvider = [[AWSStaticCredentialsProvider alloc]
                                                         initWithAccessKey:AccessKey
                                                         secretKey:SecretKey];
    // 默认使用Beijing为节点Region
    AWSEndpoint *endPoint = [[AWSEndpoint alloc] initWithRegion:AWSRegionCNNorth1
                                                        service:AWSServiceS3
                                                            URL:[NSURL URLWithString:HOST]];
    
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionCNNorth1
                                                                                    endpoint:endPoint
                                                                         credentialsProvider:credentialsProvider];
    [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
}


/*
 上传接口
 文件大于某个值,分片上传(支持断点续传, 文件名为唯一标识)
 参数定义
 filePath:本地路径
 fileName:上传文件名
 progressBlock:进度
 */
- (void)uploadWithPath:(NSString *)filePath fileName:(NSString *)fileName progressBlock:(void (^)(float progress))progressBlock success:(void (^)(void))completion failure:(void (^)(NSError *))failure{
    NSData *fileData = [NSData dataWithContentsOfFile:filePath options:0 error:NULL];
    NSString *plistPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist",fileName]];
    // 目前设置同一文件多次上传，重新从0开始
    [[NSFileManager defaultManager] removeItemAtPath:plistPath error:NULL];
    
    // 文件总大小达到100MB的文件，才进行断点续传
    if (ceil((double)[fileData length]) <= resumableUploadFileLimit) {
        [self upload:fileData fileName:fileName progressBlock:progressBlock success:completion failure:failure];
    } else {
        [self uploadWithData:fileData fileName:fileName progressBlock:progressBlock success:completion failure:failure];
    }
}

/*
 上传接口
 文件大于某个值,分片上传(支持断点续传, 文件名为唯一标识)
 这个函数会被用于断点续传，所以不能直接传filePath进来，得从数据中取
 参数定义
 fileData:文件内容
 fileName:上传文件名
 progressBlock:进度
 */
- (void)uploadWithData:(NSData *)fileData fileName:(NSString *)fileName progressBlock:(void (^)(float progress))progressBlock success:(void (^)(void))completion failure:(void (^)(NSError *))failure{
    if (ceil((double)[fileData length]) > transferManagerMinimumPartSize) {
        NSString *plistPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist",fileName]];
        self.userDefault = [BMUserDefault userDefaultWithPath:plistPath];
        [self.userDefault setObject:fileName forKey:@"fileName"];
        [self.userDefault setObject:fileData forKey:@"fileData"];

        if ([self.userDefault stringForKey:@"uploadId"]) {
            self.uploadId = [self.userDefault stringForKey:@"uploadId"];
            self.mutArray = [NSMutableArray array];
            self.cacheArray = [NSMutableArray arrayWithArray:[self.userDefault objectForKey:@"partArray"]];
            for (int i = 0; i < self.cacheArray.count; i++) {
                NSDictionary *partDic = self.cacheArray[i];
                AWSS3CompletedPart *partObj = [AWSS3CompletedPart new];
                partObj.partNumber = partDic[@"part"];
                partObj.ETag = partDic[@"ETag"];
                [self.mutArray addObject:partObj];
            }
            [self uploadPartData:fileData fileName:fileName progressBlock:progressBlock success:completion failure:failure];
        }else{
            AWSS3 *transferManager = [AWSS3 defaultS3];
            AWSS3CreateMultipartUploadRequest *createReq = [AWSS3CreateMultipartUploadRequest new];
            createReq.key = [NSString stringWithFormat:@"%@", fileName]; // 远程url，不需要前缀'/'，同时bucket默认会添加到远程url前面
            createReq.bucket = S3BucketName;
            __weak Aws3FileUtils *weakSelf = self;

            [[transferManager createMultipartUpload:createReq] continueWithBlock:^id _Nullable(AWSTask<AWSS3CreateMultipartUploadOutput *> * _Nonnull t) {
                AWSS3CreateMultipartUploadOutput *outPut = t.result;
                weakSelf.uploadId = outPut.uploadId;
                [weakSelf.userDefault setObject:weakSelf.uploadId forKey:@"uploadId"];
                [weakSelf uploadPartData:fileData fileName:fileName progressBlock:progressBlock success:completion failure:failure];
                return nil;
            }];
        }
    }else{
        [self upload:fileData fileName:fileName progressBlock:progressBlock success:completion failure:failure];
    }
}

- (void)uploadPartData:(NSData *)fileData fileName:(NSString *)fileName progressBlock:(void (^)(float progress))progressBlock success:(void (^)(void))completion failure:(void (^)(NSError *))failure{
    NSUInteger partCount = ceil((double)[fileData length] / transferManagerMinimumPartSize);
    if (self.mutArray.count == partCount) {
        [self uploadComplete:fileName progressBlock:progressBlock success:completion failure:failure];
        return;
    }
    dispatch_group_t group = dispatch_group_create();
    AWSS3 *transferManager = [AWSS3 defaultS3];
    for (int32_t i = 1; i < partCount + 1; i++) {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"part = %@",@(i)];
        NSArray *cArray = [self.cacheArray filteredArrayUsingPredicate:predicate];
        if (cArray.count) {
            continue;
        }
        NSUInteger dataLength = i == partCount ? [fileData length] - ((i - 1) * transferManagerMinimumPartSize) : transferManagerMinimumPartSize;
        NSData *partData = [fileData subdataWithRange:NSMakeRange((i - 1) * transferManagerMinimumPartSize, dataLength)];
        AWSS3UploadPartRequest *uploadPartRequest = [AWSS3UploadPartRequest new];
        uploadPartRequest.key = [NSString stringWithFormat:@"%@", fileName]; // 远程url，不需要前缀'/'，同时bucket默认会添加到远程url前面
        uploadPartRequest.partNumber = @(i);
        uploadPartRequest.body = partData;
        uploadPartRequest.contentLength = @(dataLength);
        uploadPartRequest.uploadId = self.uploadId;
        uploadPartRequest.bucket = S3BucketName;
        dispatch_group_enter(group);
        __weak Aws3FileUtils *weakSelf = self;

        [[transferManager uploadPart:uploadPartRequest] continueWithBlock:^id _Nullable(AWSTask<AWSS3UploadPartOutput *> * _Nonnull t) {
            if (t.error) {
                failure(t.error);
            }else{
                AWSS3UploadPartOutput *outputPart = t.result;
                if (outputPart) {
                    AWSS3CompletedPart *partObj = [AWSS3CompletedPart new];
                    partObj.partNumber = @(i);
                    partObj.ETag = outputPart.ETag;
                    long long size = dataLength;
                    for (int j = 0; j < weakSelf.cacheArray.count; j++) {
                        NSDictionary *cacheObj = weakSelf.cacheArray[j];
                        NSNumber *sizeNum = cacheObj[@"size"];
                        size += [sizeNum longLongValue];
                    }
                    progressBlock(size/ceil((double)[fileData length]));
                    
                    NSDictionary *cacheDic = @{@"part":@(i),@"ETag":outputPart.ETag,@"size":@(dataLength)};
                    [weakSelf.cacheArray addObject:cacheDic];
                    [weakSelf.mutArray addObject:partObj];
                    [weakSelf.userDefault setObject:weakSelf.cacheArray forKey:@"partArray"];
                    [weakSelf.userDefault synchronize];
                }else{
                    
                }
            }
            dispatch_group_leave(group);
            return nil;
        }];

        dispatch_group_notify(group, dispatch_get_main_queue(), ^{
            [weakSelf uploadComplete:fileName progressBlock:progressBlock success:completion failure:failure];
        });
        
    }
}

- (void)uploadComplete:(NSString *)fileName progressBlock:(void (^)(float progress))progressBlock success:(void (^)(void))completion failure:(void (^)(NSError *))failure{
    AWSS3 *transferManager = [AWSS3 defaultS3];
    AWSS3CompleteMultipartUploadRequest *completeUpload = [AWSS3CompleteMultipartUploadRequest new];
    completeUpload.key = [NSString stringWithFormat:@"%@", fileName]; // 远程url，不需要前缀'/'，同时bucket默认会添加到远程url前面
    completeUpload.uploadId = self.uploadId;
    completeUpload.bucket = S3BucketName;
    completeUpload.multipartUpload = [AWSS3CompletedMultipartUpload new];
    completeUpload.multipartUpload.parts = [NSArray arrayWithArray:self.mutArray] ;
    [[transferManager completeMultipartUpload:completeUpload] continueWithBlock:^id _Nullable(AWSTask<AWSS3CompleteMultipartUploadOutput *> * _Nonnull t) {
        if (t.error) {
            failure(t.error);
        }else{
            NSString *plistPath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.plist",fileName]];
            
            NSFileManager *fileManager = [NSFileManager defaultManager];
            [fileManager removeItemAtPath:plistPath error:nil];
            progressBlock(1);
            completion();
        }
        return nil;
    }];
}

//文件小于某个值
- (void)upload:(id)body fileName:(NSString *)fileName progressBlock:(void (^)(float progress))progressBlock success:(void (^)(void))completion failure:(void (^)(NSError *))failure{
    AWSS3 *transferManager = [AWSS3 defaultS3];
    AWSS3PutObjectRequest *putReq = [[AWSS3PutObjectRequest alloc] init];
    putReq.bucket = S3BucketName;
    putReq.key = [NSString stringWithFormat:@"%@", fileName]; // 远程url，不需要前缀'/'，同时bucket默认会添加到远程url前面
    putReq.uploadProgress = ^(int64_t bytesSent, int64_t totalBytesSent, int64_t totalBytesExpectedToSend) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( totalBytesSent < totalBytesExpectedToSend) {
                progressBlock(totalBytesSent/(totalBytesExpectedToSend*1.0));
            }else{
                progressBlock(1);
            }
        });
    };
    long long fileSize = 0;
    if ([body isKindOfClass:[NSData class]]) {
        fileSize = ceil((double)[(NSData *)body length]);
        putReq.body = body; // req.body是在本地的文件NSURL

    }else{
        fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath:(NSString *)body error:nil][NSFileSize] longLongValue];
        putReq.body = [NSURL fileURLWithPath:(NSString *)body]; // req.body是在本地的文件NSURL
    }
    
    putReq.contentLength = [NSNumber numberWithUnsignedLongLong:fileSize];
    [[transferManager putObject:putReq] continueWithBlock:^id _Nullable(AWSTask<AWSS3PutObjectOutput *> * _Nonnull task) {
        if(task.error)
        {
            failure(task.error);
        }
        else
        {
            completion();
        }
        return nil;
    }];
}

- (void)downloadWithFileName:(NSString *)fileName progressBlock:(void (^)(float progress))progressBlock success:(void (^)(NSData *data))completion failure:(void (^)(NSError *error))failure{
    AWSS3 *transferManager = [AWSS3 defaultS3];
    AWSS3GetObjectRequest *getReq = [[AWSS3GetObjectRequest alloc] init];
    getReq.bucket = S3BucketName;
    getReq.key = [NSString stringWithFormat:@"%@", fileName]; // 远程url，不需要前缀'/'，同时bucket默认会添加到远程url前面
    getReq.downloadProgress = ^(int64_t bytesWritten, int64_t totalBytesWritten, int64_t totalBytesExpectedToWrite) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ( totalBytesWritten < totalBytesExpectedToWrite) {
                progressBlock((totalBytesWritten/(totalBytesExpectedToWrite*1.0)));

            }else{
                progressBlock(1);
            }
        });
        
    };
    [[transferManager getObject:getReq] continueWithBlock:^id _Nullable(AWSTask<AWSS3GetObjectOutput *> * _Nonnull task) {
        if(task.error)
        {
            failure(task.error);
            NSLog(@"Error: %@",task.error);
        }
        else
        {
            completion(task.result.body);
        }
        return nil;
    }];
}


@end
