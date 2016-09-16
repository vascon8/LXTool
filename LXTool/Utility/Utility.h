//
//  Utility.h
//  TestA
//
//  Created by xin liu on 15/2/23.
//  Copyright (c) 2015年 ___xin.liu___. All rights reserved.
//

#import <Foundation/Foundation.h>

#define LXDefaultSDKPath @"Contents/Defaultandroid/android-sdk-macosx"
#define LXDefaultAndroidSDKPath [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:LXDefaultSDKPath]

#define TestWaDefaultMiniCapPath @"Contents/Vendor"
#define TestWaDefaultAndroidMiniCapPath [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:TestWaDefaultMiniCapPath]

@interface Utility : NSObject

+(NSString*) pathToAndroidBinary:(NSString*)binaryName atSDKPath:(NSString*)sdkPath;
+(NSString*) runTaskWithBinary:(NSString*)binary arguments:(NSArray*)args path:(NSString*)path;
+(NSString*) runTaskWithBinary:(NSString*)binary arguments:(NSArray*)args;
+(NSNumber*) getPidListeningOnPort:(NSNumber*)port;
+(NSString*) pathToVBoxManageBinary;

+ (NSString*)androidHomePath;

//+ (NSArray *)getAndroidDevices;
+ (NSArray *)getAndroidDevicesWithSDKPath:(NSString *)sdkPath;
//android device platform version
+ (NSString*)sdkVersionOfDevice:(NSString*)udid androidBinaryPath:(NSString*)androidBinaryPath;
+ (NSString*)androidDeviceNameOfUdid:(NSString*)udid androidBinaryPath:(NSString*)androidBinaryPath;

+ (BOOL)isAndroidSimulatorForUdid:(NSString*)udid sdkPath:(NSString*)sdkPath additional:(NSString*)addition;

//minicap
+ (BOOL)deployMiniCapOfUdid:(NSString*)udid customSDKPath:(NSString*)sdkPath;
+ (NSString*)startMiniCapWithCustomSDKPath:(NSString*)sdkPath angel:(NSInteger)angel udid:(NSString*)udid isSuccess:(BOOL*)isSuccess;
+ (NSString*)killMinicapPidWithCustomSdkPath:(NSString*)sdkPath udid:(NSString*)udid isSuccess:(BOOL*)isSuccess;
+ (NSString*)forwardWithCustomSDKPath:(NSString*)sdkPath forwardPort:(NSNumber*)forwardPort isSuccess:(BOOL*)isSuccess udid:(NSString*)udid;
+ (NSString*)removeForwardWithCustomSDKPath:(NSString*)sdkPath forwardPort:(NSNumber*)forwardPort isSuccess:(BOOL*)isSuccess udid:(NSString*)udid;
+ (BOOL)forwardSuccessWithCustomSDKPath:(NSString*)sdkPath forwardName:(NSString*)forwardName udid:(NSString*)udid;
+ (NSArray*)allMinicapPidWithCustomSDKPath:(NSString*)sdkPath udid:(NSString*)udid isSuccess:(BOOL*)isSuccess;

+ (NSArray *)getiOSDevicesSuccess:(BOOL*)isSuccess;
+ (NSDictionary *)getiOSUDIDs;
+ (NSArray *)getiOSPlatformIsSuccess:(BOOL*)isSuccess;
+ (NSDictionary*)getBundlesSuccess:(BOOL*)isSuccess;
+ (NSDictionary*)getBundlesWithUdid:(NSString*)udid isSuccess:(BOOL*)isSuccess;

+ (NSString *)getXcodeVersionisSuccess:(BOOL*)isSuccess;
+ (NSNumber *)xcodeFirstNumber;
+(NSString*)defaultXcodePathSuccess:(BOOL*)isSuccess;

//client info
+ (NSDictionary*)testwaClientInfo;
+ (NSDictionary*)hwDict;

//default android sdk in bundle
+ (NSString*)defaultAndroidHomePath;

//run command in default shell
//ie, which python
//+ (NSString*)runTaskInDefaultShellWithCommandStr:(NSString*)commandStr;
+ (NSString*)runTaskInDefaultShellWithCommandStr:(NSString*)commandStr isSuccess:(BOOL*)isSuccess;

+ (NSDictionary*)getAndroidDevicePackageDictWithSDKPath:(NSString *)sdkPath;
+ (NSArray *)packagsApkDictWithUdid:(NSString *)udid androidBinaryPath:(NSString *)androidBinaryPath;
+ (NSString *)readphoneApkWithUdid:(NSString *)udid pakcage:(NSString *)package androidBinaryPath:(NSString*)androidBinaryPath isSuccess:(BOOL*)isSuccess;
+ (NSString*)downloadApk:(NSString*)apkPath fromAndroidDevice:(NSString*)udid savePath:(NSString*)savePath androidBinaryPath:(NSString*)androidBinaryPath isDownloadSuccess:(BOOL*)isDownloadSuccess;

+ (void)refreshAndroidActivity:(NSMutableArray**)activityArr package:(NSMutableArray**)packageArr app:(NSString*)appPath customSDKPath:(NSString*)customSDKPath;
@end
