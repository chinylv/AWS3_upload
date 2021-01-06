//
//  BMTimer.h
//  BMUserDefault
//
//  Created by bomo on 2017/3/13.
//  Copyright © 2017年 bomo. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^_Nonnull BMTimerBlock)();

@interface BMTimer : NSObject

- (instancetype _Nonnull)initWithInterval:(NSTimeInterval)interval repeat:(BOOL)repeat Block:(BMTimerBlock)block;

- (instancetype _Nonnull)initWithInterval:(NSTimeInterval)interval onMainQueue:(BOOL)onMainQueue repeat:(BOOL)repeat Block:(BMTimerBlock)block;

- (instancetype _Nonnull)initWithInterval:(NSTimeInterval)interval immediately:(BOOL)immediately onMainQueue:(BOOL)onMainQueue repeat:(BOOL)repeat Block:(BMTimerBlock)block;

/** start timer */
- (void)fire;

/** close timer, cannot be used after invalidate */
- (void)invalidate;

/** is fired and not invalidate */
@property (nonatomic, assign, readonly, getter=isActive) BOOL active;

@end
