//
//  NSDictionary+NullReplacement.h
//  BMUserDefault
//
//  Created by bomo on 2017/3/29.
//  Copyright © 2017年 bomo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDictionary (NullReplacement)

- (NSDictionary *)dictionaryByReplacingNullsWithBlanks;

@end
