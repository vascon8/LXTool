//
//  LXIvar.h
//
//  Created by xinliu on 14-10-20.
//  Copyright (c) 2014年 xinliu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <objc/message.h>

@interface LXIvar : NSObject

@property (assign,nonatomic) Ivar ivar;
@property (copy,nonatomic,readonly) NSString *ivName;
@property (copy,nonatomic,readonly) NSString *propertyName;
@property (copy,nonatomic,readonly) NSString *userDefinedType;
@property (assign,nonatomic,readonly,getter = isArray) BOOL ivarIsArray;

- (instancetype)initWithaIvar:(Ivar)aIvar;

@end


@interface LXDictModel : NSObject
@property NSArray *lxArray;
@end