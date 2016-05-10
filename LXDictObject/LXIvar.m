//
//  LXIvar.m
//
//  Created by xinliu on 14-10-20.
//  Copyright (c) 2014年 xinliu. All rights reserved.
//

#import "LXIvar.h"

@implementation LXIvar

- (instancetype)initWithaIvar:(Ivar)aIvar
{
    if(self = [super init])
    {
        _ivar = aIvar;
        _ivName = [NSString stringWithUTF8String:ivar_getName(aIvar)];
        if ([_ivName isEqualToString:@"isa"]) return Nil;

        if ([_ivName hasPrefix:@"_"]) {
            _propertyName = [_ivName stringByReplacingCharactersInRange:NSMakeRange(0, 1) withString:@""];
        }
        else{
            _propertyName = _ivName;
        }
        
        NSString *encoding = [NSString stringWithUTF8String:ivar_getTypeEncoding(aIvar)];
        if ([encoding hasPrefix:@"@"] && encoding.length >3) {
            encoding = [encoding substringFromIndex:2];
            encoding = [encoding substringToIndex:encoding.length-1];
            if (![encoding hasPrefix:@"NS"]) {
                _userDefinedType = encoding;
            }
            if ([encoding isEqualToString:@"NSArray"] || [encoding isEqualToString:@"NSMutableArray"]) {
                _ivarIsArray = YES;
            }
        }
    }
    
    return self;
}

@end


@implementation LXDictModel


@end