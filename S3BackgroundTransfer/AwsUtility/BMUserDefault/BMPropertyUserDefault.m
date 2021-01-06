//
//  BMPropertyUserDefault.m
//  BMUserDefault
//
//  Created by bomo on 2017/3/14.
//  Copyright © 2017年 bomo. All rights reserved.
//

#import "BMPropertyUserDefault.h"
#import "BMUserDefault.h"
#import <objc/runtime.h>


@interface BMPropertyUserDefault ()

@property (strong, nonatomic) NSMutableDictionary *mapping;

@end

@implementation BMPropertyUserDefault

enum TypeEncodings {
    Char                = 'c',
    Bool                = 'B',
    Short               = 's',
    Int                 = 'i',
    Long                = 'l',
    LongLong            = 'q',
    UnsignedChar        = 'C',
    UnsignedShort       = 'S',
    UnsignedInt         = 'I',
    UnsignedLong        = 'L',
    UnsignedLongLong    = 'Q',
    Float               = 'f',
    Double              = 'd',
    Object              = '@'
};

- (NSString *)defaultsKeyForPropertyNamed:(char const *)propertyName {
    NSString *key = [NSString stringWithFormat:@"%s", propertyName];
    return [self _transformKey:key];
}

- (NSString *)defaultsKeyForSelector:(SEL)selector {
    return [self.mapping objectForKey:NSStringFromSelector(selector)];
}

static long long longLongGetter(BMPropertyUserDefault *self, SEL _cmd) {
    NSString *key = [self defaultsKeyForSelector:_cmd];
    return [[self.userDefaults objectForKey:key] longLongValue];
}

static void longLongSetter(BMPropertyUserDefault *self, SEL _cmd, long long value) {
    NSString *key = [self defaultsKeyForSelector:_cmd];
    NSNumber *object = [NSNumber numberWithLongLong:value];
    [self.userDefaults setObject:object forKey:key];
}

static bool boolGetter(BMPropertyUserDefault *self, SEL _cmd) {
    NSString *key = [self defaultsKeyForSelector:_cmd];
    return [self.userDefaults boolForKey:key];
}

static void boolSetter(BMPropertyUserDefault *self, SEL _cmd, bool value) {
    NSString *key = [self defaultsKeyForSelector:_cmd];
    [self.userDefaults setBool:value forKey:key];
}

static int integerGetter(BMPropertyUserDefault *self, SEL _cmd) {
    NSString *key = [self defaultsKeyForSelector:_cmd];
    return (int)[self.userDefaults integerForKey:key];
}

static void integerSetter(BMPropertyUserDefault *self, SEL _cmd, int value) {
    NSString *key = [self defaultsKeyForSelector:_cmd];
    [self.userDefaults setInteger:value forKey:key];
}

static float floatGetter(BMPropertyUserDefault *self, SEL _cmd) {
    NSString *key = [self defaultsKeyForSelector:_cmd];
    return [self.userDefaults floatForKey:key];
}

static void floatSetter(BMPropertyUserDefault *self, SEL _cmd, float value) {
    NSString *key = [self defaultsKeyForSelector:_cmd];
    [self.userDefaults setFloat:value forKey:key];
}

static double doubleGetter(BMPropertyUserDefault *self, SEL _cmd) {
    NSString *key = [self defaultsKeyForSelector:_cmd];
    return [self.userDefaults doubleForKey:key];
}

static void doubleSetter(BMPropertyUserDefault *self, SEL _cmd, double value) {
    NSString *key = [self defaultsKeyForSelector:_cmd];
    [self.userDefaults setDouble:value forKey:key];
}

static id objectGetter(BMPropertyUserDefault *self, SEL _cmd) {
    NSString *key = [self defaultsKeyForSelector:_cmd];
    return [self.userDefaults objectForKey:key];
}

static void objectSetter(BMPropertyUserDefault *self, SEL _cmd, id object) {
    NSString *key = [self defaultsKeyForSelector:_cmd];
    if (object) {
        [self.userDefaults setObject:object forKey:key];
    } else {
        [self.userDefaults removeObjectForKey:key];
    }
}

#pragma GCC diagnostic push
#pragma GCC diagnostic ignored "-Wundeclared-selector"
#pragma GCC diagnostic ignored "-Warc-performSelector-leaks"

- (instancetype)init {
    self = [super init];
    if (self) {
        if ([self respondsToSelector:@selector(setupDefaults)]) {
            NSDictionary *defaults = [self performSelector:@selector(setupDefaults)];
            NSMutableDictionary *mutableDefaults = [NSMutableDictionary dictionaryWithCapacity:[defaults count]];
            for (NSString *key in defaults) {
                id value = [defaults objectForKey:key];
                NSString *transformedKey = [self _transformKey:key];
                [mutableDefaults setObject:value forKey:transformedKey];
            }
            [self.userDefaults registerDefaults:mutableDefaults];
        }
        
        [self generateAccessorMethods];
    }
    
    return self;
}

- (NSString *)_transformKey:(NSString *)key {
    if ([self respondsToSelector:@selector(transformKey:)]) {
        return [self performSelector:@selector(transformKey:) withObject:key];
    }
    
    return key;
}

#pragma GCC diagnostic pop

- (void)generateAccessorMethods {
    unsigned int count = 0;
    objc_property_t *properties = class_copyPropertyList([self class], &count);
    
    self.mapping = [NSMutableDictionary dictionary];
    
    for (int i = 0; i < count; ++i) {
        objc_property_t property = properties[i];
        const char *name = property_getName(property);
        
        if (strcmp(name, "superclass") == 0) continue;
        
        const char *attributes = property_getAttributes(property);
        
        char *getter = strstr(attributes, ",G");
        if (getter) {
            getter = strdup(getter + 2);
            getter = strsep(&getter, ",");
        } else {
            getter = strdup(name);
        }
        SEL getterSel = sel_registerName(getter);
        free(getter);
        
        char *setter = strstr(attributes, ",S");
        if (setter) {
            setter = strdup(setter + 2);
            setter = strsep(&setter, ",");
        } else {
            asprintf(&setter, "set%c%s:", toupper(name[0]), name + 1);
        }
        SEL setterSel = sel_registerName(setter);
        free(setter);
        
        NSString *key = [self defaultsKeyForPropertyNamed:name];
        [self.mapping setValue:key forKey:NSStringFromSelector(getterSel)];
        [self.mapping setValue:key forKey:NSStringFromSelector(setterSel)];
        
        IMP getterImp = NULL;
        IMP setterImp = NULL;
        char type = attributes[1];
        switch (type) {
            case Short:
            case Long:
            case LongLong:
            case UnsignedChar:
            case UnsignedShort:
            case UnsignedInt:
            case UnsignedLong:
            case UnsignedLongLong:
                getterImp = (IMP)longLongGetter;
                setterImp = (IMP)longLongSetter;
                break;
                
            case Bool:
            case Char:
                getterImp = (IMP)boolGetter;
                setterImp = (IMP)boolSetter;
                break;
                
            case Int:
                getterImp = (IMP)integerGetter;
                setterImp = (IMP)integerSetter;
                break;
                
            case Float:
                getterImp = (IMP)floatGetter;
                setterImp = (IMP)floatSetter;
                break;
                
            case Double:
                getterImp = (IMP)doubleGetter;
                setterImp = (IMP)doubleSetter;
                break;
                
            case Object:
                getterImp = (IMP)objectGetter;
                setterImp = (IMP)objectSetter;
                break;
                
            default:
                free(properties);
                [NSException raise:NSInternalInconsistencyException format:@"Unsupported type of property \"%s\" in class %@", name, self];
                break;
        }
        
        char types[5];
        
        snprintf(types, 4, "%c@:", type);
        class_addMethod([self class], getterSel, getterImp, types);
        
        snprintf(types, 5, "v@:%c", type);
        class_addMethod([self class], setterSel, setterImp, types);
    }
    
    free(properties);
}

@end
