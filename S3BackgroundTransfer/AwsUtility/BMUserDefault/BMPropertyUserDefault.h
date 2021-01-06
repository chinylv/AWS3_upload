//
//  BMPropertyUserDefault.h
//  BMUserDefault
//
//  Created by bomo on 2017/3/14.
//  Copyright © 2017年 bomo. All rights reserved.
//

#import "BMUserDefault.h"

@interface BMPropertyUserDefault : NSObject

/** You must init userDefault before use */
@property (strong, nonatomic) BMUserDefault * _Nullable userDefaults;

@end
