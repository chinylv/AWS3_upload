//
//  BMTimer.m
//  BMUserDefault
//
//  Created by bomo on 2017/3/13.
//  Copyright © 2017年 bomo. All rights reserved.
//

#import "BMTimer.h"



@interface BMTimer ()

@property (nonatomic, strong) dispatch_source_t timer;
@property (nonatomic, copy) BMTimerBlock block;
@property (nonatomic, assign) BOOL firstTime;

@end

@implementation BMTimer


- (instancetype _Nonnull)initWithInterval:(NSTimeInterval)interval repeat:(BOOL)repeat Block:(BMTimerBlock)block
{
    return [self initWithInterval:interval immediately:NO onMainQueue:NO repeat:repeat Block:block];
}


- (instancetype _Nonnull)initWithInterval:(NSTimeInterval)interval onMainQueue:(BOOL)onMainQueue repeat:(BOOL)repeat Block:(BMTimerBlock)block
{
    return [self initWithInterval:interval immediately:NO onMainQueue:onMainQueue repeat:repeat Block:block];
}

- (instancetype _Nonnull)initWithInterval:(NSTimeInterval)interval immediately:(BOOL)immediately onMainQueue:(BOOL)onMainQueue repeat:(BOOL)repeat Block:(BMTimerBlock)block
{
    if (self = [super init]) {
        _firstTime = YES;
        self.block = block;
        
        dispatch_queue_t queue = onMainQueue ? dispatch_get_main_queue() : dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
        dispatch_source_set_timer(self.timer, DISPATCH_TIME_NOW, NSEC_PER_SEC * interval, 0.1 * NSEC_PER_SEC);
        __weak typeof(self) weakSelf = self;
        dispatch_source_set_event_handler(self.timer, ^{
            __strong typeof(self) strongSelf = weakSelf;
            
            if (!immediately && strongSelf.firstTime) {
                // ignore first time
                strongSelf.firstTime = NO;
                return;
            }
            
            strongSelf.block();
            if (!repeat) {
                // do not repeat
                [strongSelf invalidate];
            }
        });
    }
    return self;
}

- (void)fire
{
    if (!_active) {
        _active = YES;
        dispatch_resume(self.timer);
    }
}

- (void)invalidate
{
    if (_active) {
        dispatch_source_cancel(self.timer);
    }    
}

@end
