//
//  TestAAgentTool.m
//  TestWa
//
//  Created by xin liu on 16/9/29.
//  Copyright © 2016年 ___xin.liu___. All rights reserved.
//

#import "TestAAgentTool.h"

#import "PTChannel.h"
#import "TestAAgentServerRequestCommands.h"
#import "FBErrorBuilder.h"

#define FBValidateObjectWithClass(object, aClass) \
if (object && ![object isKindOfClass:aClass]) { \
[self respondWithErrorMessage:[NSString stringWithFormat:@"Invalid object class %@ for %@", [object class], @#object]]; \
return; \
}

static TestAAgentTool *sharedInstance=nil;

@interface TestAAgentTool ()<PTChannelDelegate>{
    // If the remote connection is over USB transport...
    NSNumber *connectingToDeviceID_;
    NSNumber *connectedDeviceID_;
    NSString *_deviceUdid;
    
    NSDictionary *connectedDeviceProperties_;
    NSDictionary *remoteDeviceInfo_;
    dispatch_queue_t notConnectedQueue_;
    BOOL notConnectedQueueSuspended_;
    PTChannel *connectedChannel_;
    NSMutableDictionary *pings_;
    
    id observer;
    id detachObserver;
}
@property (readonly) NSNumber *connectedDeviceID;
@property PTChannel *connectedChannel;

@property TestAAgentUSBResponseCompletion autoRefreshImgCompletionBlock;
@property TestAAgentUSBResponseCompletion autoRefreshSourceCompletionBlock;

@property (nonatomic, copy, readonly) NSMutableDictionary<NSString *, TestAAgentUSBResponseCompletion> *uuidToCallbackMap;
@property (nonatomic, copy, readonly) NSMutableDictionary<NSString *, NSDictionary*> *udidToDeviceidMap;

- (void)startListeningForDevices;
- (void)didDisconnectFromDevice:(NSNumber*)deviceID;
- (void)disconnectFromCurrentChannel;
- (void)enqueueConnectToLocalIPv4Port;
- (void)connectToLocalIPv4Port;
- (void)connectToUSBDevice;

- (void)ping;

@property BOOL refreshScreenshot;
@property BOOL refreshSource;

@end

@implementation TestAAgentTool
//- (instancetype)initdelegate:(id<TestAAgentDelegate>)delegate receiveImgBlock:(TestAAgentRefreshBlock)receiveImgBlock receivedSourceBlock:(TestAAgentRefreshBlock)receivedSourceBlock
//{
//    if ([self init]) {
//        self.receivedImgBlock = receiveImgBlock;
//        self.receivedSourceBlock = receivedSourceBlock;
//        self.delegate = delegate;
//    }
//    return self;
//}
//- (instancetype)initWithDevice:(NSString *)deviceUdid delegate:(id<TestAAgentDelegate>)delegate receiveImgBlock:(TestAAgentRefreshBlock)receiveImgBlock receivedSourceBlock:(TestAAgentRefreshBlock)receivedSourceBlock
//{
//    if ([self initdelegate:delegate receiveImgBlock:receiveImgBlock receivedSourceBlock:receivedSourceBlock]) {
//        _deviceUdid = deviceUdid;
//        [self startListeningForDevices];
//    }
//    return self;
//}
- (instancetype)connectToDevice:(NSString *)deviceUdid delegate:(id<TestAAgentDelegate>)delegate receiveImgBlock:(TestAAgentRefreshBlock)receiveImgBlock receivedSourceBlock:(TestAAgentRefreshBlock)receivedSourceBlock
{
    _deviceUdid = deviceUdid;
    [self attachDelegate:delegate receiveImgBlock:receiveImgBlock receivedSourceBlock:receivedSourceBlock];
    if (self.udidToDeviceidMap && [self.udidToDeviceidMap.allKeys containsObject:deviceUdid]) {
        [self connectToDeviceWithUserinfo:self.udidToDeviceidMap[deviceUdid]];
    }
    
    return sharedInstance;
}
- (instancetype)connectToSimulatorWithDelegate:(id<TestAAgentDelegate>)delegate receiveImgBlock:(TestAAgentRefreshBlock)receiveImgBlock receivedSourceBlock:(TestAAgentRefreshBlock)receivedSourceBlock
{
    [self attachDelegate:delegate receiveImgBlock:receiveImgBlock receivedSourceBlock:receivedSourceBlock];
    _deviceUdid = @"simulator";
    [self enqueueConnectToLocalIPv4Port];
    
    return sharedInstance;
}
- (void)attachDelegate:(id<TestAAgentDelegate>)delegate receiveImgBlock:(TestAAgentRefreshBlock)receiveImgBlock receivedSourceBlock:(TestAAgentRefreshBlock)receivedSourceBlock
{
    self.receivedSourceBlock = receivedSourceBlock;
    self.receivedImgBlock = receiveImgBlock;
    self.delegate = delegate;
}
//- (instancetype)initWithSimulatorAndDelegate:(id<TestAAgentDelegate>)delegate receiveImgBlock:(TestAAgentRefreshBlock)receiveImgBlock receivedSourceBlock:(TestAAgentRefreshBlock)receivedSourceBlock
//{
//    if ([self initdelegate:delegate receiveImgBlock:receiveImgBlock receivedSourceBlock:receivedSourceBlock]) {
//        _deviceUdid = @"simulator";
//        [self enqueueConnectToLocalIPv4Port];
//    }
//    return self;
//}
//- (instancetype)init
//{
//    if (self = [super init]) {
//        _uuidToCallbackMap = [NSMutableDictionary dictionary];
//
//        // We use a serial queue that we toggle depending on if we are connected or
//        // not. When we are not connected to a peer, the queue is running to handle
//        // "connect" tries. When we are connected to a peer, the queue is suspended
//        // thus no longer trying to connect.
//        notConnectedQueue_ = dispatch_queue_create("TestWaAgent.notConnectedQueue", DISPATCH_QUEUE_SERIAL);
//    }
//
//    return self;
//}

- (PTChannel*)connectedChannel {
    return connectedChannel_;
}

- (void)setConnectedChannel:(PTChannel*)connectedChannel {
    connectedChannel_ = connectedChannel;
    
    // Toggle the notConnectedQueue_ depending on if we are connected or not
    //    if (!connectedChannel_ && notConnectedQueueSuspended_) {
    //        dispatch_resume(notConnectedQueue_);
    //        notConnectedQueueSuspended_ = NO;
    //    } else if (connectedChannel_ && !notConnectedQueueSuspended_) {
    //        dispatch_suspend(notConnectedQueue_);
    //        notConnectedQueueSuspended_ = YES;
    //    }
    
    //    if (!connectedChannel_ && connectingToDeviceID_) {
    //        [self enqueueConnectToUSBDevice];
    //    }
    
    if (!self.sessionID && connectedChannel) {
        [self getSession:nil];
    }
}
- (BOOL)ready{return connectedChannel_!=nil && self.sessionID!=nil;}
#pragma mark - Wired device connections
- (void)disconnectAgent
{
    [self disconnectFromCurrentChannel];
    connectedChannel_ = nil;
    
    connectedDeviceID_ = nil;
    connectingToDeviceID_ = nil;
    connectedDeviceProperties_ = nil;
    
    _deviceUdid = nil;
    self.receivedImgBlock = nil;
    self.receivedSourceBlock = nil;
    
    self.refreshSource = NO;
    self.refreshScreenshot = NO;
    _sessionID = nil;
    
    self.delegate = nil;
}
- (void)deallocAgent
{
    [[NSNotificationCenter defaultCenter] removeObserver:observer];
    [[NSNotificationCenter defaultCenter] removeObserver:detachObserver];
    observer = nil;
    detachObserver = nil;
    
//    NSLog(@"==dealloc agent");
}
- (void)startListeningForDevices {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    observer = [nc addObserverForName:PTUSBDeviceDidAttachNotification object:PTUSBHub.sharedHub queue:nil usingBlock:^(NSNotification *note) {
//        NSLog(@"PTUSBDeviceDidAttachNotification: %@", note.userInfo);
        [self connectToDeviceWithUserinfo:note.userInfo];
    }];
    
    detachObserver = [nc addObserverForName:PTUSBDeviceDidDetachNotification object:PTUSBHub.sharedHub queue:nil usingBlock:^(NSNotification *note) {
        NSNumber *deviceID = [note.userInfo objectForKey:@"DeviceID"];
        //NSLog(@"PTUSBDeviceDidDetachNotification: %@", note.userInfo);
//        NSLog(@"PTUSBDeviceDidDetachNotification: %@", deviceID);
        
        if ([connectingToDeviceID_ isEqualToNumber:deviceID]) {
            connectedDeviceProperties_ = nil;
            connectingToDeviceID_ = nil;
            if (connectedChannel_) {
                [connectedChannel_ close];
            }
        }
        
        NSString *serialNumber;
        if (note.userInfo  && [note.userInfo.allKeys containsObject:@"Properties"]) {
            NSDictionary *properDict = [note.userInfo objectForKey:@"Properties"];
            if (properDict && [properDict isKindOfClass:[NSDictionary class]] && [properDict.allKeys containsObject:@"SerialNumber"]) {
                serialNumber = properDict[@"SerialNumber"];
            }
        }
        
        if(serialNumber && _udidToDeviceidMap && [_udidToDeviceidMap.allKeys containsObject:serialNumber]) [_udidToDeviceidMap removeObjectForKey:serialNumber];
    }];
}
- (void)connectToDeviceWithUserinfo:(NSDictionary*)userinfo
{
    NSNumber *deviceID = [userinfo objectForKey:@"DeviceID"];
    NSString *serialNumber;
    if (userinfo  && [userinfo.allKeys containsObject:@"Properties"]) {
        NSDictionary *properDict = [userinfo objectForKey:@"Properties"];
        if (properDict && [properDict isKindOfClass:[NSDictionary class]] && [properDict.allKeys containsObject:@"SerialNumber"]) {
            serialNumber = properDict[@"SerialNumber"];
        }
    }
    
    if(serialNumber && _udidToDeviceidMap && ![_udidToDeviceidMap.allKeys containsObject:serialNumber]) [_udidToDeviceidMap setObject:userinfo forKey:serialNumber];
    
    dispatch_async(notConnectedQueue_, ^{
        if (_deviceUdid && serialNumber && [serialNumber isEqualToString:_deviceUdid] && connectedDeviceID_ != deviceID && connectingToDeviceID_ != deviceID) {
            [self disconnectFromCurrentChannel];
            connectingToDeviceID_ = deviceID;
            connectedDeviceProperties_ = [userinfo objectForKey:@"Properties"];
            [self enqueueConnectToUSBDevice];
        }
        
        //            if (!connectingToDeviceID_ || ![deviceID isEqualToNumber:connectingToDeviceID_]) {
        //                [self disconnectFromCurrentChannel];
        //                connectingToDeviceID_ = deviceID;
        //                connectedDeviceProperties_ = [note.userInfo objectForKey:@"Properties"];
        //                [self enqueueConnectToUSBDevice];
        //            }
    });
}
- (void)didDisconnectFromDevice:(NSNumber*)deviceID {
    NSLog(@"Disconnected from device");
    if ([connectedDeviceID_ isEqualToNumber:deviceID]) {
        [self willChangeValueForKey:@"connectedDeviceID"];
        connectedDeviceID_ = nil;
        [self didChangeValueForKey:@"connectedDeviceID"];
    }
}


- (void)disconnectFromCurrentChannel {
    if (connectedDeviceID_ && connectedChannel_) {
        [connectedChannel_ close];
        self.connectedChannel = nil;
    }
}
#pragma mark - usb connect
- (void)enqueueConnectToUSBDevice {
    dispatch_async(notConnectedQueue_, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self connectToUSBDevice];
        });
    });
}

- (void)connectToUSBDevice {
    PTChannel *channel = [PTChannel channelWithDelegate:self];
    channel.userInfo = connectingToDeviceID_;
    channel.delegate = self;
    
    [channel connectToPort:TestWaAgentIPv4PortNumber overUSBHub:PTUSBHub.sharedHub deviceID:connectingToDeviceID_ callback:^(NSError *error) {
        if (error) {
            if (error.domain == PTUSBHubErrorDomain && error.code == PTUSBHubErrorConnectionRefused) {
                NSLog(@"Failed to connect to device #%@: %@", channel.userInfo, error);
            } else {
                NSLog(@"Failed to connect to device #%@: %@", channel.userInfo, error);
            }
            if (channel.userInfo == connectingToDeviceID_) {
                [self performSelector:@selector(enqueueConnectToUSBDevice) withObject:nil afterDelay:TestWaAgentReconnectDelay];
            }
            
        } else {
            connectedDeviceID_ = connectingToDeviceID_;
            self.connectedChannel = channel;
            
        }
    }];
}
#pragma mark - ipv4 connect
- (void)enqueueConnectToLocalIPv4Port {
    dispatch_async(notConnectedQueue_, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            [self connectToLocalIPv4Port];
        });
    });
}
- (void)connectToLocalIPv4Port {
    PTChannel *channel = [PTChannel channelWithDelegate:self];
    
    channel.userInfo = [NSString stringWithFormat:@"127.0.0.1:%d", TestWaAgentIPv4PortNumber];
    [channel connectToPort:TestWaAgentIPv4PortNumber IPv4Address:INADDR_LOOPBACK callback:^(NSError *error, PTAddress *address) {
        if (error) {
            if (error.domain == NSPOSIXErrorDomain && (error.code == ECONNREFUSED || error.code == ETIMEDOUT)) {
                // this is an expected state
            } else {
                NSLog(@"Failed to connect to 127.0.0.1:%d: %@", TestWaAgentIPv4PortNumber, error);
            }
        } else {
            [self disconnectFromCurrentChannel];
            self.connectedChannel = channel;
            channel.userInfo = address;
            
//            NSLog(@"Connected to %@", address);
        }
        //        if(self && _deviceUdid) [self performSelector:@selector(enqueueConnectToLocalIPv4Port) withObject:nil afterDelay:TestWaAgentReconnectDelay];
    }];
}
#pragma mark - ping test
//- (void)pongWithTag:(uint32_t)tagno error:(NSError*)error {
//    NSNumber *tag = [NSNumber numberWithUnsignedInt:tagno];
//    NSMutableDictionary *pingInfo = [pings_ objectForKey:tag];
//    if (pingInfo) {
//        NSDate *now = [NSDate date];
//        [pingInfo setObject:now forKey:@"date ended"];
//        [pings_ removeObjectForKey:tag];
//        NSLog(@"Ping total roundtrip time: %.3f ms", [now timeIntervalSinceDate:[pingInfo objectForKey:@"date created"]]*1000.0);
//    }
//}
//- (void)ping {
//    if (connectedChannel_) {
//        if (!pings_) {
//            pings_ = [NSMutableDictionary dictionary];
//        }
//        uint32_t tagno = [connectedChannel_.protocol newTag];
//        NSNumber *tag = [NSNumber numberWithUnsignedInt:tagno];
//        NSMutableDictionary *pingInfo = [NSMutableDictionary dictionaryWithObjectsAndKeys:[NSDate date], @"date created", nil];
//        [pings_ setObject:pingInfo forKey:tag];
//        [connectedChannel_ sendFrameOfType:TestWaAgentFrameTypePing tag:tagno withPayload:nil callback:^(NSError *error) {
//            [self performSelector:@selector(ping) withObject:nil afterDelay:1.0];
//            [pingInfo setObject:[NSDate date] forKey:@"date sent"];
//            if (error) {
//                [pings_ removeObjectForKey:tag];
//            }
//        }];
//    } else {
//        [self performSelector:@selector(ping) withObject:nil afterDelay:1.0];
//    }
//}
#pragma mark - PTChannelDelegate
- (BOOL)ioFrameChannel:(PTChannel*)channel shouldAcceptFrameOfType:(uint32_t)type tag:(uint32_t)tag payloadSize:(uint32_t)payloadSize {
    if ( type != TestWaAgentFrameTypeDeviceInfo
        && type != TestWaAgentFrameTypeHttpTalk
        && type != TestWaAgentFrameTypePong
        && type != TestWaAgentFrameTypeUsbTalk
        && type != TestWaAgentFrameTypeUsbSourceTalk
        && type != TestWaAgentFrameTypeUsbScreenshotTalk
        && type != PTFrameTypeEndOfStream) {
        NSLog(@"Unexpected frame of type %u", type);
        [channel close];
        return NO;
    } else {
        return YES;
    }
}
- (void)ioFrameChannel:(PTChannel*)channel didReceiveFrameOfType:(uint32_t)type tag:(uint32_t)tag payload:(PTData*)payload {
    //    dispatch_async(dispatch_get_main_queue(), ^{
    [self dispatchioFrameChannel:channel didReceiveFrameOfType:type tag:tag payload:payload];
    //    });
    
}
- (void)dispatchioFrameChannel:(PTChannel*)channel didReceiveFrameOfType:(uint32_t)type tag:(uint32_t)tag payload:(PTData*)payload
{
    //    NSLog(@"received %@, %u, %u, %@ thread:%@", channel, type, tag, payload,[NSThread currentThread]);
    NSData *resData = [NSData dataWithContentsOfDispatchData:payload.dispatchData];
    BOOL success = YES;
    NSError *innerError;
    NSString *resErrStr;
    
    if (type == TestWaAgentFrameTypeDeviceInfo) {
        
    }else if (type == TestWaAgentFrameTypePong) {
        //        [self pongWithTag:tag error:nil];
    }
    else if (type == TestWaAgentFrameTypeHttpTalk){
        
        NSDictionary *response = [NSJSONSerialization JSONObjectWithData:resData options:NSJSONReadingMutableContainers error:&innerError];
//        NSLog(@"=res from iphone");
        
        if (innerError) {
            success = NO;
            [self dispatchHandlerRespondError:innerError frameOfType:type tag:tag];
            NSLog(@"wrong data from iphone");
            return;
        }
        
        if (!response) {
            resErrStr = @"wrong data from iphone";
            success = NO;
            NSLog(@"wrong data from iphone");
        }
        
        if (response && ![response isKindOfClass:NSDictionary.class]) {
            resErrStr = @"wrong data from iphone";
            success = NO;
            NSLog(@"wrong data from iphone");
        }
        
        if (success && [response.allKeys containsObject:TestAAgentUuidStr]) {
            NSString *requestUUID = response[TestAAgentUuidStr];
            
            NSString *errStr;
            if (![response.allKeys containsObject:TestAAgentHttpResStr]) {
                errStr = @"手机返回数据为空";
            }
            
            if (![response.allKeys containsObject:TestAAgentClientResStatusStr]) {
                NSString *err = @"手机没有正确返回状态";
                if(errStr) errStr = [NSString stringWithFormat:@"%@ 并且 %@",errStr,err];
            }
            else{
                NSNumber *statCode = response[TestAAgentClientResStatusStr];
                if (statCode != 0) {
                    NSString *stateErr = @"手机执行命令失败";
                    if(errStr) errStr = [NSString stringWithFormat:@"%@ 并且 %@",errStr,stateErr];
                }
            }
            
            NSError *error = nil;
            if (errStr) {
                errStr = [NSString stringWithFormat:@"%@\n",errStr];
                FBErrorBuilder *errB = [[FBErrorBuilder builder] withDescription:errStr];
                error = [errB build];
            }
            [self dispatchHandlerBlockForHttpRequestWithUDID:requestUUID response:response error:error frameOfType:type tag:tag];
            
        }
        else{
            NSLog(@"wrong data from iphone");
            resErrStr = @"wrong data from iphone";
            success = NO;
        }
        
        if (!success && resErrStr) {
            resErrStr = [NSString stringWithFormat:@"%@\n",resErrStr];
            FBErrorBuilder *errB = [[FBErrorBuilder builder] withDescription:resErrStr];
            NSError *resErr = [errB build];
            [self dispatchHandlerRespondError:resErr frameOfType:type tag:tag];
        }
    }
    else if (type == TestWaAgentFrameTypeUsbTalk || type == TestWaAgentFrameTypeUsbScreenshotTalk || type == TestWaAgentFrameTypeUsbSourceTalk){
        
        NSDictionary *response = [NSJSONSerialization JSONObjectWithData:resData options:NSJSONReadingMutableContainers error:&innerError];
        //                        NSLog(@"=res from iphone:%@",response);
        if (innerError) {
            success = NO;
            NSLog(@"innerE:%@,res:%@",innerError,response);
            [self dispatchHandlerRespondError:innerError frameOfType:type tag:tag];
            return;
        }
        
        if (!response) {
            NSLog(@"wrong data from iphone");
            success = NO;
        }
        
        if (response && ![response isKindOfClass:NSDictionary.class]) {
            NSLog(@"wrong data from iphone");
            success = NO;
        }
        
        if (success && [response.allKeys containsObject:TestAAgentUuidStr]) {
            NSString *requestUUID = response[TestAAgentUuidStr];
            
            [self dispatchHandlerBlockForHttpRequestWithUDID:requestUUID response:response error:nil frameOfType:type tag:tag];
        }
        else{
            resErrStr = @"wrong data from iphone";
            NSLog(@"==responseError:%@",response);
            resErrStr = [NSString stringWithFormat:@"%@\n",resErrStr];
            FBErrorBuilder *errB = [[FBErrorBuilder builder] withDescription:resErrStr];
            NSError *resErr = [errB build];
            [self dispatchHandlerRespondError:resErr frameOfType:type tag:tag];
        }
    }
}
- (void)dispatchHandlerRespondError:(NSError*)error frameOfType:(uint32_t)type tag:(uint32_t)tag
{
    if (type == TestWaAgentFrameTypeUsbScreenshotTalk) {
        self.refreshScreenshot = NO;
    }
    else if (type == TestWaAgentFrameTypeUsbSourceTalk){
        self.refreshSource = NO;
    }
    
    if (tag == TestWaAgentTagServerAnalyReqError || tag == TestWaAgentTagServerAnalyRouteResError || tag == TestWaAgentTagServerEncodeResError) {
        
    }
    else{
        
    }
    
    if ([self.delegate respondsToSelector:@selector(agentErrorResponseFromeDevice:frameOfType:tag:)]) {
        [self.delegate agentErrorResponseFromeDevice:error frameOfType:type tag:tag];
    }
}
- (void)dispatchHandlerBlockForHttpRequestWithUDID:(NSString *)requestUUID response:(NSDictionary *)response error:(NSError *)error frameOfType:(uint32_t)type tag:(uint32_t)tag
{
    if (type == TestWaAgentFrameTypeUsbScreenshotTalk) {
        if (self.autoRefreshImgCompletionBlock) {
            self.autoRefreshImgCompletionBlock(response,error,type);
        }
    }
    else if (type == TestWaAgentFrameTypeUsbSourceTalk){
        if (self.autoRefreshSourceCompletionBlock) {
            self.autoRefreshSourceCompletionBlock(response,error,type);
        }
    }
    else{
        if ([self.uuidToCallbackMap.allKeys containsObject:requestUUID]) {
            TestAAgentUSBResponseCompletion handler = self.uuidToCallbackMap[requestUUID];
            
            handler(response, error,type);
            [self.uuidToCallbackMap removeObjectForKey:requestUUID];
        }
    }
}
- (void)ioFrameChannel:(PTChannel*)channel didEndWithError:(NSError*)error {
    NSLog(@"==io end:%@",error);
    if (connectedDeviceID_ && [connectedDeviceID_ isEqualToNumber:channel.userInfo]) {
        [self didDisconnectFromDevice:connectedDeviceID_];
    }
    
    if (connectedChannel_ == channel) {
        self.connectedChannel = nil;
    }
}
#pragma mark - decorate
- (BOOL)validateChannel
{
    return connectedChannel_ != nil;
}
- (BOOL)decorateCommands:(TestAAgentServerRequestCommands*)commands
{
    BOOL success = NO;
    
    //    NSLog(@"==session:%@",self.sessionID);
    
    if (self.sessionID) {
        commands.sessionID = self.sessionID;
        //        NSLog(@"==2session:%@",self.sessionID);
        if (commands.requireSession) {
            commands.path = [commands.path stringByReplacingOccurrencesOfString:TestAAgentSessionIDPrefixStr withString:self.sessionID];
            success = YES;
        }
    }
    else{
        if (!commands.requireSession) {
            success = YES;
        }
    }
    
    if (commands.completionBlock && commands.uuid) {
        self.uuidToCallbackMap[commands.uuid] = commands.completionBlock;
    }
    
    return success;
}
#pragma mark - send request
- (void)sendWithJsonObject:(NSDictionary*)jsonObj type:(uint32_t)type tag:(uint32_t)tag callback:(void(^)(NSError *error))callback
{
    NSParameterAssert(jsonObj);
    NSParameterAssert(type);
    
    //        NSLog(@"==send request");
    NSError *error;
    NSData *data = [NSJSONSerialization dataWithJSONObject:jsonObj
                                                   options:NSJSONWritingPrettyPrinted
                                                     error:&error];
    if (error) {
        if (callback) {
            NSLog(@"=error:%@",error);
            callback(error);return;
        }
    }
    
    dispatch_data_t payload = data.createReferencingDispatchData;
    //     NSLog(@"==send request frame");
    [connectedChannel_ sendFrameOfType:type tag:tag withPayload:payload callback:callback];
}
- (void)callbackRespondWithErrorMessage:(NSString *)errorMessage callback:(void(^)(NSError *error))callback
{
    if (callback) {
        FBErrorBuilder *errorB = [[FBErrorBuilder builder] withDescription:errorMessage];
        NSError *error = [errorB build];
        callback(error);
    }
}
#pragma mark - test
- (IBAction)getSession:(id)sender {
//    NSLog(@"==get session");
    if ([self validateChannel]) {
        TestAAgentServerRequestCommands *commands = [TestAAgentServerRequestCommands getSessions];
        commands.completionBlock = ^(NSDictionary *response,NSError *reqError,uint32 type){
            NSString *key = (type == TestWaAgentFrameTypeUsbTalk) ? TestAAgentUsbResStr : TestAAgentHttpResStr;
            if ([response.allKeys containsObject:key]) {
                if(response[key]) {
                    NSDictionary *httpResDict = response[key];
                    if ([httpResDict.allKeys containsObject:TestAAgentSessionIDStr]) {
                        NSString *sessionValue = httpResDict[TestAAgentSessionIDStr];
                        if ([sessionValue isKindOfClass:[NSNull class]]) {
                            NSLog(@"null class");
                        }
                        
                        if (sessionValue && ![sessionValue isKindOfClass:[NSNull class]]) {
                            _sessionID = sessionValue;
                        }
                    }
                }
//                NSLog(@"self sessionID:%@",self.sessionID);
                if (!self.sessionID && connectedChannel_) {
                    [self performSelector:@selector(getSession:) withObject:nil afterDelay:1.0];
                }
                else{
                    if ([self.delegate respondsToSelector:@selector(agentSessionReady:)]) {
                        [self.delegate agentSessionReady:self.sessionID];
                    }
                }
            }
        };
        
        commands.callbackBlock = ^(NSError* error){
            if (error) {
                NSLog(@"failed to send request:%@",error);
            }
        };
        
        if ([self decorateCommands:commands]) {
            [self sendWithJsonObject:[commands commandJsonObject] type:TestWaAgentFrameTypeHttpTalk tag:PTFrameNoTag callback:^(NSError *error) {
                if (error) {
                    NSLog(@"Failed to send message: %@", error);
                    if (commands.callbackBlock) {
                        commands.callbackBlock(error);
                    }
                }
            }];
        }
        
        
    }
}
#pragma mark - refresh
- (BOOL)refreshing{
    return (self.refreshSource || self.refreshScreenshot);
}
- (void)refresh{
    [self agentRefreshSource];
    [self agentRefreshScreenshot];
}
- (void)agentRefreshSource{
    __weak TestAAgentTool *weakSelf = self;
    
    if (!self.autoRefreshSourceCompletionBlock) {
        self.autoRefreshSourceCompletionBlock = ^(NSDictionary *response,NSError *reqError,uint32 type){
            NSString *key = (type == TestWaAgentFrameTypeUsbSourceTalk) ? TestAAgentUsbResStr : TestAAgentHttpResStr;
            NSDictionary *elementDict = nil;
            
            //            key = TestAAgentHttpResStr;
            //        NSLog(@"=type:%d",type);
            if ([response.allKeys containsObject:key]) {
                NSDictionary *httpResDict = response[key];
                if(httpResDict) {
                    if ([httpResDict.allKeys containsObject:TestAAgentResValueStr]) {
                        elementDict = httpResDict[TestAAgentResValueStr];
                    }
                }
            }
            
            if (weakSelf.receivedSourceBlock) {
                weakSelf.receivedSourceBlock(elementDict,nil);
            }
            weakSelf.refreshSource =  NO;
            //            NSLog(@"==finish eleTree:");
        };
    }
    
    if (self.refreshSource) {
        self.autoRefreshSourceCompletionBlock = ^(NSDictionary *response,NSError *reqError,uint32 type){
            if (weakSelf.receivedSourceBlock) {
                weakSelf.receivedSourceBlock(nil,nil);
            }
        };
        return;
    }
    
    if (!self.refreshSource) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [self autoRefreshElementTree];
        });
    }
}
- (void)agentRefreshScreenshot{
    __weak TestAAgentTool *weakSelf = self;
    
    if (!self.autoRefreshImgCompletionBlock) {
        
        self.autoRefreshImgCompletionBlock = ^(NSDictionary *response,NSError *reqError,uint32 type){
            NSString *key = (type == TestWaAgentFrameTypeUsbScreenshotTalk) ? TestAAgentUsbResStr : TestAAgentHttpResStr;
            NSData *imgD = nil;
            
            //            key = TestAAgentHttpResStr;
            //                    NSLog(@"=type:%d",type);
            if ([response.allKeys containsObject:key]) {
                NSDictionary *httpResDict = response[key];
                if(httpResDict) {
                    if ([httpResDict isKindOfClass:[NSDictionary class]] && [httpResDict.allKeys containsObject:TestAAgentResValueStr]) {
                        NSString *imgStr = httpResDict[TestAAgentResValueStr];
                        if (imgStr && [imgStr isKindOfClass:[NSString class]]) {
                            imgD = [[NSData alloc]initWithBase64EncodedString:imgStr options:NSDataBase64DecodingIgnoreUnknownCharacters];
                            
                        }
                        
                    }
                }
            }
            if (weakSelf.receivedImgBlock) {
                weakSelf.receivedImgBlock(imgD,nil);
            }
            weakSelf.refreshScreenshot =  NO;
        };
    }
    
    if (self.refreshScreenshot){
        self.autoRefreshImgCompletionBlock = ^(NSDictionary *response,NSError *reqError,uint32 type){
            if (weakSelf.receivedImgBlock) {weakSelf.receivedImgBlock(nil,nil);}
        };
        return;
    }
    
    if (!self.refreshScreenshot) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            [self autoRefreshScreenshot];
        });
    }
}

- (void)autoRefreshElementTree{
    //    if ([self validateChannel]) {
    if(self.refreshSource) return;
    self.refreshSource = YES;
    
    TestAAgentServerRequestCommands *commands = [TestAAgentServerRequestCommands getSource];
    
    [self decorateCommands:commands];
    [self sendWithJsonObject:[commands commandJsonObject] type:TestWaAgentFrameTypeUsbSourceTalk tag:PTFrameNoTag callback:^(NSError *error) {
        if (error) {
            NSLog(@"Failed to send message: %@", error);
            self.refreshSource = NO;
            if (self.receivedSourceBlock) {
                self.receivedSourceBlock(nil,error);
            }
        }
    }];
    //    }
}
- (void)autoRefreshScreenshot{
    
    //    if ([self validateChannel]) {
    //    if(self.refreshScreenshot) return;
    
    //    NSLog(@"==getScreenshot ");
    self.refreshScreenshot = YES;
    
    TestAAgentServerRequestCommands *commands = [TestAAgentServerRequestCommands getScreenshot];
    
    [self decorateCommands:commands];
    [self sendWithJsonObject:[commands commandJsonObject] type:TestWaAgentFrameTypeUsbScreenshotTalk tag:PTFrameNoTag callback:^(NSError *error) {
        if (error) {
            NSLog(@"Failed to send message: %@", error);
            self.refreshScreenshot = NO;
            if (self.receivedImgBlock) {
                self.receivedImgBlock(nil,error);
            }
        }
    }];
    //    }
}
#pragma mark - remove temp file
+ (void)removeAgentTempFile
{
    NSString *dir = [NSHomeDirectory() stringByAppendingPathComponent:@"Library/Developer/Xcode/DerivedData"];
    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSArray *comps = [fm contentsOfDirectoryAtPath:dir error:nil];
    for (NSString *fileName in comps) {
        if ([fileName hasPrefix:@"WebDriverAgent-"]) {
            [fm removeItemAtPath:[dir stringByAppendingPathComponent:fileName] error:nil];
        }
    }
}
#pragma mark - singleton
+ (instancetype)sharedAgentTool
{
    if (!sharedInstance) {
        sharedInstance = [[TestAAgentTool alloc]init];
    }
    
    return sharedInstance;
}
+ (id)allocWithZone:(struct _NSZone *)zone
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [super allocWithZone:zone];
    });
    return sharedInstance;
}
- (void)dealloc
{
    [self deallocAgent];
}
- (instancetype)init
{
    if (self = [super init]) {
        static dispatch_once_t onceToken;
        dispatch_once(&onceToken, ^{
            _uuidToCallbackMap = [NSMutableDictionary dictionary];
            _udidToDeviceidMap = [NSMutableDictionary dictionary];
            
            // We use a serial queue that we toggle depending on if we are connected or
            // not. When we are not connected to a peer, the queue is running to handle
            // "connect" tries. When we are connected to a peer, the queue is suspended
            // thus no longer trying to connect.
            notConnectedQueue_ = dispatch_queue_create("TestWaAgent.notConnectedQueue", DISPATCH_QUEUE_SERIAL);
            
            [self startListeningForDevices];
        });
    }
    return self;
}
@end
