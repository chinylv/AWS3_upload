//
//  BMUserDefault.m
//  BMUserDefault
//
//  Created by bomo on 2017/3/13.
//  Copyright © 2017年 bomo. All rights reserved.
//

#import "BMUserDefault.h"
#import "NSDictionary+NullReplacement.h"
#import "BMTimer.h"
#import <UIKit/UIKit.h>

/** store to storage when go to background or time trigger */
@interface BMUserDefault ()

@property (nonatomic, copy) NSString *storePath;
@property (nonatomic, strong) NSMutableDictionary *userDefault;
@property (nonatomic, strong) BMTimer *timer;
@property (nonatomic, assign) BOOL isChanged;

#if OS_OBJECT_USE_OBJC
@property (strong, nonatomic) dispatch_queue_t queue;
#else
@property (assign, nonatomic) dispatch_queue_t queue;
#endif

@end

@implementation BMUserDefault

/** check store every 0.1 seconds */
const NSTimeInterval kStoreInterval = 0.1;

+ (instancetype _Nonnull)userDefaultWithPath:(NSString * _Nonnull)path
{
    NSAssert(path.length > 0, @"path cannot be empty");
    id instance = [[self cacheUserDefaults] objectForKey:path];
    if (instance == nil) {
        instance = [[self alloc] initWithPath:path];
        [[self cacheUserDefaults] setObject:instance forKey:path];
    }
    return instance;    
}

- (instancetype _Nonnull)initWithPath:(NSString * _Nonnull)path
{
    if (self = [super init]) {
        self.storePath = path;
        self.queue = dispatch_queue_create(path.UTF8String, DISPATCH_QUEUE_SERIAL);
        self.userDefault = [NSMutableDictionary dictionaryWithContentsOfFile:path];
        if (self.userDefault == nil) {
            self.userDefault = [NSMutableDictionary dictionary];
        }
        
        __weak typeof(self) weakSelf = self;
        self.timer = [[BMTimer alloc] initWithInterval:kStoreInterval repeat:YES Block:^{
            __strong typeof(self) strongSelf = weakSelf;
            [strongSelf synchronize];
        }];
        [self.timer fire];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(synchronize) name:UIApplicationWillResignActiveNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [self.timer invalidate];
    [self synchronize];
    [[self.class cacheUserDefaults] removeObjectForKey:self.storePath];
}

- (nullable id)objectForKey:(NSString * _Nonnull)defaultName
{
    return [self syncObjectForKey:defaultName];
}

- (void)setObject:(nullable id)value forKey:(NSString * _Nonnull)defaultName
{
    [self syncSetObject:value forKey:defaultName];
}

- (void)removeObjectForKey:(NSString * _Nonnull)defaultName
{
    dispatch_sync(_queue, ^{
        self.isChanged = YES;
        [self.userDefault removeObjectForKey:defaultName];
    });
}

- (nullable NSString *)stringForKey:(NSString * _Nonnull)defaultName
{
    return [self syncObjectForKey:defaultName];
}

- (nullable NSArray *)arrayForKey:(NSString * _Nonnull)defaultName
{
    return [self syncObjectForKey:defaultName];
}

- (nullable NSDictionary<NSString *, id> *)dictionaryForKey:(NSString * _Nonnull)defaultName
{
    return [self syncObjectForKey:defaultName];
}

- (nullable NSData *)dataForKey:(NSString * _Nonnull)defaultName
{
    return [self syncObjectForKey:defaultName];
}

- (nullable NSArray<NSString *> *)stringArrayForKey:(NSString * _Nonnull)defaultName
{
    return [self syncObjectForKey:defaultName];
}

- (NSInteger)integerForKey:(NSString * _Nonnull)defaultName
{
    return [[self syncObjectForKey:defaultName] integerValue];
}

- (float)floatForKey:(NSString * _Nonnull)defaultName
{
    return [[self syncObjectForKey:defaultName] floatValue];
}

- (double)doubleForKey:(NSString * _Nonnull)defaultName
{
    return [[self syncObjectForKey:defaultName] doubleValue];
}

- (BOOL)boolForKey:(NSString * _Nonnull)defaultName
{
    return [[self syncObjectForKey:defaultName] boolValue];
}

- (nullable NSURL *)URLForKey:(NSString * _Nonnull)defaultName
{
    NSString *url = [self syncObjectForKey:defaultName];
    return [NSURL URLWithString:url];
}

- (void)setInteger:(NSInteger)value forKey:(NSString * _Nonnull)defaultName
{
    [self syncSetObject:@(value) forKey:defaultName];
}

- (void)setFloat:(float)value forKey:(NSString * _Nonnull)defaultName
{
    [self syncSetObject:@(value) forKey:defaultName];
}

- (void)setDouble:(double)value forKey:(NSString * _Nonnull)defaultName
{
    [self syncSetObject:@(value) forKey:defaultName];
}

- (void)setBool:(BOOL)value forKey:(NSString * _Nonnull)defaultName
{
    [self syncSetObject:@(value) forKey:defaultName];
}

- (void)setURL:(nullable NSURL *)url forKey:(NSString * _Nonnull)defaultName
{
    [self syncSetObject:url.absoluteString forKey:defaultName];
}

- (void)registerDefaults:(NSDictionary<NSString *, id> * _Nonnull)registrationDictionary
{
    [registrationDictionary enumerateKeysAndObjectsUsingBlock:^(NSString * _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
        if (![self.userDefault.allKeys containsObject:key]) {
            //no exists
            self.userDefault[key] = obj;
        }
    }];
}

- (void)clear
{
    dispatch_sync(_queue, ^{
        self.isChanged = YES;
        [self.userDefault removeAllObjects];
    });
}

- (BOOL)synchronize
{
    if (self.isChanged) {
        __block BOOL result = NO;
        dispatch_sync(_queue, ^{
            //retry
            NSDictionary *dict = [self.userDefault dictionaryByReplacingNullsWithBlanks];
            NSInteger retryTime = 2;
            while (!result && retryTime > 0) {
                result = [dict writeToFile:self.storePath atomically:YES];
                retryTime--;
            }
            NSAssert(result, @"sync to local storage fail");
        });
        return NO;
    } else {
        return YES;
    }
}

#pragma mark - Thread Safe Wrapper
- (id)syncObjectForKey:(NSString * _Nonnull)defaultName
{
    __block id object = nil;
    dispatch_sync(_queue, ^{
        self.isChanged = YES;
        object = [self.userDefault objectForKey:defaultName];
    });
    return object;
}

- (void)syncSetObject:(id)object forKey:(NSString * _Nonnull)defaultName
{
    dispatch_sync(_queue, ^{
        self.isChanged = YES;
        [self.userDefault setObject:object forKey:defaultName];
    });
}

#pragma mark - Cache for instances
+ (NSMapTable *)cacheUserDefaults
{
    static NSMapTable *userDefaults = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        userDefaults = [NSMapTable strongToWeakObjectsMapTable];
    });
    return userDefaults;
}


+ (BOOL)synchronizeAll
{
    NSEnumerator<BMUserDefault *> *enumerator = [BMUserDefault cacheUserDefaults].objectEnumerator;
    BMUserDefault *defaults = enumerator.nextObject;
    BOOL result = YES;
    while (defaults != nil) {
        result = result && [defaults synchronize];
    }
    return result;
}


@end
