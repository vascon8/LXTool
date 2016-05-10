//
//  NSObject+LXDict.h
//
//  Created by xinliu on 14-10-19.
//  Copyright (c) 2014年 xinliu. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSObject (LXDict)

/**
 *  dict -> model
 *  no array in keyedDict
 */
+ (instancetype)objectWithKeyedDict:(NSDictionary *)keyedDict;

/**
 *  dict -> model
 *  has array in keyedDict
 *  @param modelDict Key:array name,Value:model name
 */
+ (instancetype)objectWithKeyedDict:(NSDictionary *)keyedDict modelDict:(NSDictionary *)modelDict;

/**
 *  model -> dict
 */
- (NSDictionary *)keyedDictFromModel;

@end
