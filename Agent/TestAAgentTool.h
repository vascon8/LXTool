//
//  TestAAgentTool.h
//  TestWa
//
//  Created by xin liu on 16/9/29.
//  Copyright © 2016年 ___xin.liu___. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TestWaAgentGeneral.h"

typedef void(^TestAAgentRefreshBlock)(id result,NSError *error);

static const NSTimeInterval TestWaAgentReconnectDelay = 1.0;

@protocol TestAAgentDelegate <NSObject>
- (void)agentConnectedToDevice:(NSString*)deviceUdid;
- (void)agentDisconnectedFromDevice:(NSString*)deviceUdid;
- (void)agentErrorResponseFromeDevice:(NSError*)error frameOfType:(uint32_t)type tag:(uint32_t)tag;
- (void)agentSessionReady:(NSString*)sessionID;

@end

@interface TestAAgentTool : NSObject
@property (weak) id<TestAAgentDelegate> delegate;

@property (readonly) NSString *sessionID;
@property (readonly) BOOL ready;
@property BOOL sessionReady;

- (instancetype)initWithDevice:(NSString *)deviceUdid delegate:(id<TestAAgentDelegate>)delegate receiveImgBlock:(TestAAgentRefreshBlock)receiveImgBlock receivedSourceBlock:(TestAAgentRefreshBlock)receivedSourceBlock;
- (instancetype)initWithSimulatorAndDelegate:(id<TestAAgentDelegate>)delegate receiveImgBlock:(TestAAgentRefreshBlock)receiveImgBlock receivedSourceBlock:(TestAAgentRefreshBlock)receivedSourceBlock;

- (void)refresh;
//screenshot && source
@property (readonly) BOOL refreshing;

#pragma mark - refresh
@property (copy) TestAAgentRefreshBlock receivedImgBlock;
@property (copy) TestAAgentRefreshBlock receivedSourceBlock;

#pragma mark - action
- (void)deallocAgent;
@end
