//
//  TestAAgentServerRequestCommands.m
//  TestWaAgentServer
//
//  Created by xin liu on 16/9/22.
//  Copyright © 2016年 xinliu. All rights reserved.
//

#import "TestAAgentServerRequestCommands.h"
#import "TestWaAgentGeneral.h"

#define FBRouteSessionPrefix [NSString stringWithFormat:@"/session/%@/",TestAAgentSessionIDPrefixStr]

@interface TestAAgentServerRequestCommands ()

@end

@implementation TestAAgentServerRequestCommands
#pragma mark - method
+ (instancetype)withVerb:(NSString *)verb path:(NSString *)pathPattern requiresSession:(BOOL)requiresSession action:(NSString*)action
{
    TestAAgentServerRequestCommands *requestModel = [TestAAgentServerRequestCommands new];
    requestModel.method = verb;
    requestModel.action = action;
    requestModel.path = [self pathPatternWithSession:pathPattern requiresSession:requiresSession];
    requestModel.requireSession = requiresSession;
    requestModel.parameters = @{};
    NSString *requestUUID = [NSUUID UUID].UUIDString;
    requestModel.uuid = requestUUID;
    
//    NSLog(@"==path:%@",requestModel.path);
    return requestModel;
}

+ (instancetype)GET:(NSString *)pathPattern requiresSession:(BOOL)requiresSession action:(NSString*)action
{
    return [self withVerb:@"GET" path:pathPattern requiresSession:requiresSession action:action];
}

+ (instancetype)POST:(NSString *)pathPattern requiresSession:(BOOL)requiresSession action:(NSString*)action
{
    return [self withVerb:@"POST" path:pathPattern requiresSession:requiresSession action:action];
}

+ (instancetype)PUT:(NSString *)pathPattern requiresSession:(BOOL)requiresSession action:(NSString*)action
{
    return [self withVerb:@"PUT" path:pathPattern requiresSession:requiresSession action:action];
}

+ (instancetype)DELETE:(NSString *)pathPattern requiresSession:(BOOL)requiresSession action:(NSString*)action
{
    return [self withVerb:@"DELETE" path:pathPattern requiresSession:requiresSession action:action];
}

+ (NSString *)pathPatternWithSession:(NSString *)pathPattern requiresSession:(BOOL)requiresSession
{
    NSRange range = [pathPattern rangeOfString:FBRouteSessionPrefix];
    if (requiresSession) {
        if (range.location != 0) {
            pathPattern = [FBRouteSessionPrefix stringByAppendingPathComponent:pathPattern];
        }
    } else {
        if (range.location == 0) {
            pathPattern = [pathPattern stringByReplacingCharactersInRange:range withString:@"/"];
        }
    }
    return pathPattern;
}
- (NSDictionary*)commandJsonObject
{
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    if(self.uuid) [dict setObject:self.uuid forKey:TestAAgentUuidStr];
    if(self.parameters) [dict setObject:self.parameters forKey:TestAAgentParametersStr];
    if(self.method) [dict setObject:self.method forKey:TestAAgentMethodStr];
    if(self.path) [dict setObject:self.path forKey:TestAAgentPathStr];
    if(self.action) [dict setObject:self.action forKey:TestAAgentActionStr];
    if(self.sessionID) [dict setObject:self.sessionID forKey:TestAAgentSessionIDStr];
    return dict;
}
#pragma mark - commands
+ (NSString*)decoreatePath:(NSString*)command
{
    return [NSString stringWithFormat:@"/%@",command];
}
#pragma mark screenshot
+ (instancetype)getScreenshot
{
    return [self GET:[self decoreatePath:TestAAgentCommandGetScreenshot] requiresSession:YES action:TestAAgentCommandGetScreenshot];
}
#pragma mark - source
+ (instancetype)getSource
{
    return [self GET:[self decoreatePath:TestAAgentCommandGetSource] requiresSession:YES action:TestAAgentCommandGetSource];
}
+ (instancetype)getTree
{
    return [self GET:[self decoreatePath:TestAAgentCommandGetTree] requiresSession:YES action:TestAAgentCommandGetTree];
}
+ (instancetype)getTreeWithoutSession
{
    return [self GET:[self decoreatePath:TestAAgentCommandGetTree] requiresSession:NO action:TestAAgentCommandGetTree];
}
#pragma mark - session
+ (instancetype)getStatus
{
    return [self GET:[self decoreatePath:TestAAgentCommandGetStatus] requiresSession:NO action:TestAAgentCommandGetStatus];
}
+ (instancetype)createSession
{
    return [self POST:[self decoreatePath:TestAAgentCommandCreateSession] requiresSession:NO action:TestAAgentCommandCreateSession];
}
+ (instancetype)getSessions
{
    return [self GET:[self decoreatePath:TestAAgentCommandGetSessions] requiresSession:NO action:TestAAgentCommandGetSessions];
}
+ (instancetype)deleteSession
{
    return [self DELETE:@"" requiresSession:YES action:nil];
}
+ (instancetype)getSessionInfo
{
    return [self GET:@"" requiresSession:YES action:nil];
}
@end
