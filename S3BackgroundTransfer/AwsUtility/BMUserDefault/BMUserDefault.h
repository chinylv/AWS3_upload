//
//  BMUserDefault.h
//  BMUserDefault
//
//  Created by bomo on 2017/3/13.
//  Copyright © 2017年 bomo. All rights reserved.
//

#import <Foundation/Foundation.h>

/** custom userDefault like NSUserDefault, thread safe */
@interface BMUserDefault : NSObject

+ (instancetype _Nonnull)userDefaultWithPath:(NSString * _Nonnull)path;

/*!
 -objectForKey: will search the receiver's search list for a default with the key 'defaultName' and return it. If another process has changed defaults in the search list, NSUserDefaults will automatically update to the latest values. If the key in question has been marked as ubiquitous via a Defaults Configuration File, the latest value may not be immediately available, and the registered value will be returned instead.
 */
- (nullable id)objectForKey:(NSString * _Nonnull)defaultName;

/*!
 -setObject:forKey: immediately stores a value (or removes the value if nil is passed as the value) for the provided key in the search list entry for the receiver's suite name in the current user and any host, then asynchronously stores the value persistently, where it is made available to other processes.
 */
- (void)setObject:(nullable id)value forKey:(NSString * _Nonnull)defaultName;

/// -removeObjectForKey: is equivalent to -[... setObject:nil forKey:defaultName]
- (void)removeObjectForKey:(NSString * _Nonnull)defaultName;

/// -stringForKey: is equivalent to -objectForKey:, except that it will convert NSNumber values to their NSString representation. If a non-string non-number value is found, nil will be returned.
- (nullable NSString *)stringForKey:(NSString * _Nonnull)defaultName;

/// -arrayForKey: is equivalent to -objectForKey:, except that it will return nil if the value is not an NSArray.
- (nullable NSArray *)arrayForKey:(NSString * _Nonnull)defaultName;
/// -dictionaryForKey: is equivalent to -objectForKey:, except that it will return nil if the value is not an NSDictionary.
- (nullable NSDictionary<NSString *, id> *)dictionaryForKey:(NSString * _Nonnull)defaultName;
/// -dataForKey: is equivalent to -objectForKey:, except that it will return nil if the value is not an NSData.
- (nullable NSData *)dataForKey:(NSString * _Nonnull)defaultName;
/// -stringForKey: is equivalent to -objectForKey:, except that it will return nil if the value is not an NSArray<NSString *>. Note that unlike -stringForKey:, NSNumbers are not converted to NSStrings.
- (nullable NSArray<NSString *> *)stringArrayForKey:(NSString * _Nonnull)defaultName;
/*!
 -integerForKey: is equivalent to -objectForKey:, except that it converts the returned value to an NSInteger. If the value is an NSNumber, the result of -integerValue will be returned. If the value is an NSString, it will be converted to NSInteger if possible. If the value is a boolean, it will be converted to either 1 for YES or 0 for NO. If the value is absent or can't be converted to an integer, 0 will be returned.
 */
- (NSInteger)integerForKey:(NSString * _Nonnull)defaultName;
/// -floatForKey: is similar to -integerForKey:, except that it returns a float, and boolean values will not be converted.
- (float)floatForKey:(NSString * _Nonnull)defaultName;
/// -doubleForKey: is similar to -doubleForKey:, except that it returns a double, and boolean values will not be converted.
- (double)doubleForKey:(NSString * _Nonnull)defaultName;
/*!
 -boolForKey: is equivalent to -objectForKey:, except that it converts the returned value to a BOOL. If the value is an NSNumber, NO will be returned if the value is 0, YES otherwise. If the value is an NSString, values of "YES" or "1" will return YES, and values of "NO", "0", or any other string will return NO. If the value is absent or can't be converted to a BOOL, NO will be returned.
 
 */
- (BOOL)boolForKey:(NSString * _Nonnull)defaultName;
/*!
 -URLForKey: is equivalent to -objectForKey: except that it converts the returned value to an NSURL. If the value is an NSString path, then it will construct a file URL to that path. If the value is an archived URL from -setURL:forKey: it will be unarchived. If the value is absent or can't be converted to an NSURL, nil will be returned.
 */
- (nullable NSURL *)URLForKey:(NSString * _Nonnull)defaultName ;

/// -setInteger:forKey: is equivalent to -setObject:forKey: except that the value is converted from an NSInteger to an NSNumber.
- (void)setInteger:(NSInteger)value forKey:(NSString * _Nonnull)defaultName;
/// -setFloat:forKey: is equivalent to -setObject:forKey: except that the value is converted from a float to an NSNumber.
- (void)setFloat:(float)value forKey:(NSString * _Nonnull)defaultName;
/// -setDouble:forKey: is equivalent to -setObject:forKey: except that the value is converted from a double to an NSNumber.
- (void)setDouble:(double)value forKey:(NSString * _Nonnull)defaultName;
/// -setBool:forKey: is equivalent to -setObject:forKey: except that the value is converted from a BOOL to an NSNumber.
- (void)setBool:(BOOL)value forKey:(NSString * _Nonnull)defaultName;
/// -setURL:forKey is equivalent to -setObject:forKey: except that the value is archived to an NSData. Use -URLForKey: to retrieve values set this way.
- (void)setURL:(nullable NSURL *)url forKey:(NSString * _Nonnull)defaultName ;


/*!
 -registerDefaults: adds the registrationDictionary to the last item in every search list. This means that after BMUserDefaults has looked for a value in every other valid location, it will look in registered defaults, making them useful as a "fallback" value. Registered defaults are never stored between runs of an application, and are visible only to the application that registers them.
 
 Default values from Defaults Configuration Files will automatically be registered.
 */
- (void)registerDefaults:(NSDictionary<NSString *, id> * _Nonnull)registrationDictionary;

/*!
 -synchronize is deprecated and will be marked with the NS_DEPRECATED macro in a future release.
 
 -synchronize blocks the calling thread until all in-progress set operations have completed. This is no longer necessary. Replacements for previous uses of -synchronize depend on what the intent of calling synchronize was. If you synchronized...
 - ...before reading in order to fetch updated values: remove the synchronize call
 - ...after writing in order to notify another program to read: the other program can use KVO to observe the default without needing to notify
 - ...before exiting in a non-app (command line tool, agent, or daemon) process: call CFPreferencesAppSynchronize(kCFPreferencesCurrentApplication)
 - ...for any other reason: remove the synchronize call
 */

/** remove all value */
- (void)clear;

- (BOOL)synchronize;

/** sync all default file (may call when app crash) */
+ (BOOL)synchronizeAll;

@end
