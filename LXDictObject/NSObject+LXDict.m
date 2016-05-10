//
//  NSObject+LXDict.m
//
//  Created by xinliu on 14-10-19.
//  Copyright (c) 2014年 xinliu. All rights reserved.
//

#import "NSObject+LXDict.h"
#import "LXIvar.h"

typedef void(^LXIvarBlock)(LXIvar *aIvar,BOOL *stop);

@implementation NSObject (LXDict)

+ (instancetype)objectWithKeyedDict:(NSDictionary *)keyedDict
{
    return [self objectWithKeyedDict:keyedDict modelDict:Nil];
}
+ (instancetype)objectWithKeyedDict:(NSDictionary *)keyedDict modelDict:(NSDictionary *)modelDict
{
    if (![keyedDict isKindOfClass:[NSDictionary class]]) {
        [NSException raise:@"keyedDict is not a Dictionary" format:Nil];
    }
    
    id object = [[self alloc]init];
    [object setValuesFromDict:keyedDict modelDict:modelDict];
    
    return object;
}
- (NSDictionary *)keyedDictFromModel
{
    NSDictionary *keyedDict = [NSMutableDictionary dictionary];
    [self enumerateIvarsWithIvarBlock:^(LXIvar *aIvar, BOOL *stop) {
        id value = [self valueForKey:aIvar.propertyName];
        
        if (aIvar.userDefinedType) {
            value = [value keyedDictFromModel];
        }
        
        if (aIvar.isArray && [value isKindOfClass:[NSArray class]]) {
            NSMutableArray *arr = [NSMutableArray arrayWithCapacity:[value count]];
            for (id obj in value) {
                NSDictionary *dict = nil;
                if ([obj isKindOfClass:[NSArray class]]) {
                    LXDictModel *model = [LXDictModel new];
                    model.lxArray = obj;
                    dict = [model keyedDictFromModel];
                }
                else{
                    dict = [obj keyedDictFromModel];
                }
                if(dict) [arr addObject:dict];
            }
            value = arr;
        }
        
        if (value) [keyedDict setValue:value forKey:aIvar.propertyName];
    }];
    
    return keyedDict;
}
#pragma mark - private
- (void)setValuesFromDict:(NSDictionary *)keyedDict modelDict:(NSDictionary *)modelDict
{
    [self enumerateIvarsWithIvarBlock:^(LXIvar *aIvar, BOOL *stop) {
        id value = keyedDict[aIvar.propertyName];
        
        if (aIvar.userDefinedType && [value isKindOfClass:[NSDictionary class]]) {
            Class userDefinedClass = NSClassFromString(aIvar.userDefinedType);
            value = [userDefinedClass objectWithKeyedDict:value modelDict:modelDict];
        }
        
        NSString *modelName = modelDict[aIvar.propertyName];
        if (modelName && value && aIvar.isArray && [value isKindOfClass:[NSArray class]]) {
            value = [self modelObjectsWithModelName:modelName modelDict:modelDict value:value];
        }
        
        if (value) [self setValue:value forKey:aIvar.propertyName];
    }];
}
- (NSArray *)modelObjectsWithModelName:(NSString *)modelName modelDict:(NSDictionary*)modelDict value:(NSArray *)value
{
    Class modelClass = NSClassFromString(modelName);
    NSMutableArray *arr = [NSMutableArray arrayWithCapacity:[value count]];
    for (id obj in value) {
        if ([obj isKindOfClass:[NSDictionary class]]) {
            id model = [modelClass objectWithKeyedDict:obj modelDict:modelDict];
            if (!model) continue;
            [arr addObject:model];
        }
    }
    return arr;
}
- (void)enumerateIvarsWithIvarBlock:(LXIvarBlock)block
{
    if (!block) return;
    
    Class c = [self class];
    while (c) {
        unsigned int output;
        Ivar *ivars = class_copyIvarList(c, &output);
        
        for (int i=0; i<output; i++) {
            LXIvar *lxIvar = [[LXIvar alloc]initWithaIvar:ivars[i]];
             if(lxIvar) block(lxIvar,NO);
        }
        
        free(ivars);
        
        c = class_getSuperclass(c);
    }

}
@end
