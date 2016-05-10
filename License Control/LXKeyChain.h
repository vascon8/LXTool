//
//  LXKeyChain.h
//  TestWA
//
//  Created by xinliu on 15-11-6.
//  Copyright (c) 2015年 ___xin.liu___. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LXKeyChain : NSObject
+ (void) setGenericPassword:(NSString *) password forService:(NSString *) service account:(NSString *) account ;
+ (void) removeGenericPasswordForService:(NSString *) service account:(NSString *) account ;
+ (NSString *) genericPasswordForService:(NSString *) service account:(NSString *) account;
@end
