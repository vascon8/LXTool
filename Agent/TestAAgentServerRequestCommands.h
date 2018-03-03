//
//  TestAAgentServerRequestCommands.h
//  TestWaAgentServer
//
//  Created by xin liu on 16/9/22.
//  Copyright © 2016年 xinliu. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef void (^TestAAgentUSBResponseCompletion)(NSDictionary *response, NSError *requestError,uint32 type);
typedef void (^TestAAgentUSBCallback)(NSError *error);

@interface TestAAgentServerRequestCommands : NSObject
#pragma mark required
@property NSString *uuid;
@property NSString *method;
@property NSString *path;
//for usb talk
@property NSString *action;
@property NSString *sessionID;
#pragma mark optional
//sessionID
@property NSDictionary *parameters;
@property BOOL requireSession;

#pragma mark - block action
@property (copy) TestAAgentUSBCallback callbackBlock;
@property (copy) TestAAgentUSBResponseCompletion completionBlock;

- (NSDictionary*)commandJsonObject;

#pragma mark - commands
#pragma mark screenshot
+ (instancetype)getScreenshot;

#pragma mark - source
+ (instancetype)getSource;
+ (instancetype)getTree;
+ (instancetype)getTreeWithoutSession;
+ (instancetype)setFormatDes;
+ (instancetype)setFormatDefault;

#pragma mark - session
+ (instancetype)getStatus;
+ (instancetype)createSession;
+ (instancetype)getSessions;
+ (instancetype)deleteSession;
+ (instancetype)getSessionInfo;

@end
