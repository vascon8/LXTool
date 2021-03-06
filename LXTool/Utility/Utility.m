//
//  Utility.m
//  TestA
//
//  Created by xin liu on 15/2/23.
//  Copyright (c) 2015年 ___xin.liu___. All rights reserved.
//

#import "Utility.h"

//#import "TestALogHandler.h"
#import "NSString+TrimLeadingWhitespace.h"
#import "LXLicenseTool.h"

#include <stdio.h>
#include <stdlib.h>
#define READ 0
#define WRITE 1

pid_t
popen2(const char *command, int *infp, int *outfp)
{
    int p_stdin[2], p_stdout[2];
    pid_t pid;
    
    if (pipe(p_stdin) != 0 || pipe(p_stdout) != 0)
        return -1;
    
    pid = fork();
    
    if (pid < 0)
        return pid;
    else if (pid == 0)
    {
        close(p_stdin[WRITE]);
        dup2(p_stdin[READ], READ);
        close(p_stdout[READ]);
        dup2(p_stdout[WRITE], WRITE);
        close(p_stdout[READ]);
        close(p_stdin[WRITE]);
        
        execl("/bin/sh", "sh", "-c", command, NULL);
        perror("execl");
        exit(1);
    }
    
    if (infp == NULL)
        close(p_stdin[WRITE]);
    else
        *infp = p_stdin[WRITE];
    
    if (outfp == NULL)
        close(p_stdout[READ]);
    else
        *outfp = p_stdout[READ];
    
    close(p_stdin[READ]);
    close(p_stdout[WRITE]);
    return pid;
}

@implementation Utility
#pragma mark - android
+ (NSString*)defaultAndroidHomePath
{
    NSString *defaultPath = LXDefaultAndroidSDKPath;
//    NSLog(@"defP:%@",defaultPath);
    
    NSString *adbPath = [self pathToAndroidBinary:@"adb" atSDKPath:defaultPath];
    if (adbPath) {
//        NSLog(@"==successful===");
    }
    else{
        defaultPath = nil;
    }
    
    //    NSLog(@"bundlePath:%@",bundlePath);
    return defaultPath;
}
+ (NSString*)androidHomePath
{
    NSString *androidHomePath = nil;
    
    NSTask *androidHomeTask = [NSTask new];
    [androidHomeTask setLaunchPath:@"/bin/bash"];
    [androidHomeTask setArguments: [NSArray arrayWithObjects: @"-l",
                                    @"-c", @"echo $ANDROID_HOME", nil]];
    NSPipe *pipe = [NSPipe pipe];
    [androidHomeTask setStandardOutput:pipe];
    [androidHomeTask setStandardError:[NSPipe pipe]];
    [androidHomeTask setStandardInput:[NSPipe pipe]];
    [androidHomeTask launch];
    [androidHomeTask waitUntilExit];
    NSFileHandle *stdOutHandle = [pipe fileHandleForReading];
    NSData *data = [stdOutHandle readDataToEndOfFile];
    [stdOutHandle closeFile];
    androidHomePath = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    
    if (androidHomePath.length < 2) {
        NSAttributedString *str=[[NSAttributedString alloc]initWithString:@"Warning:找不到Android SDK,请设置ANDROID_HOME环境变量或者在设置面板中指定Android SDK Path!\n" attributes:@{NSForegroundColorAttributeName: [NSColor redColor]}];
//        [[TestALogHandler sharedLogHandler]showDoctorResult:str];
        androidHomePath = @"";
    }
    
//    NSLog(@"androidHome:%@",androidHomePath);
    return androidHomePath;
}

+(NSString*) pathToAndroidBinary:(NSString*)binaryName atSDKPath:(NSString*)sdkPath
{
    NSString *androidHomePath = sdkPath;
    // get the path to $ANDROID_HOME if an sdk path is not supplied
    if (!androidHomePath)
    {
        //        androidHomePath = [self androidHomePath];
        
        if (!androidHomePath || androidHomePath.length < 2) {
            NSAttributedString *str=[[NSAttributedString alloc]initWithString:@"Warning:找不到Android SDK,请设置ANDROID_HOME环境变量或者在设置面板中指定Android SDK Path!\n" attributes:@{NSForegroundColorAttributeName: [NSColor redColor]}];
//            [[TestALogHandler sharedLogHandler]showDoctorResult:str];
            return nil;
        }
        
    }
    
    // check platform-tools folder
    NSString *androidBinaryPath = [[androidHomePath stringByAppendingPathComponent:@"platform-tools"] stringByAppendingPathComponent:binaryName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:androidBinaryPath])
    {
        return androidBinaryPath;
    }
    
    // check tools folder
    androidBinaryPath = [[androidHomePath stringByAppendingPathComponent:@"tools"] stringByAppendingPathComponent:binaryName];
    if ([[NSFileManager defaultManager] fileExistsAtPath:androidBinaryPath])
    {
        return androidBinaryPath;
    }
    
    
    
    // check build-tools folders
    NSString *buildToolsDirectory = [androidHomePath stringByAppendingPathComponent:@"build-tools"];
    NSEnumerator* enumerator = [[[[NSFileManager defaultManager] enumeratorAtPath:buildToolsDirectory] allObjects] reverseObjectEnumerator];
    NSString *buildToolsSubDirectory;
    while (buildToolsSubDirectory = [enumerator nextObject])
    {
        buildToolsSubDirectory = [buildToolsDirectory stringByAppendingPathComponent:buildToolsSubDirectory];
        BOOL isDirectory = NO;
        if ([[NSFileManager defaultManager] fileExistsAtPath:buildToolsSubDirectory isDirectory: &isDirectory])
        {
            if (isDirectory) {
                androidBinaryPath = [buildToolsSubDirectory stringByAppendingPathComponent:binaryName];
                if ([[NSFileManager defaultManager] fileExistsAtPath:androidBinaryPath])
                {
                    return androidBinaryPath;
                }
            }
        }
    }
    
    if (!sdkPath) {
        //        return [self pathToAndroidBinary:binaryName atSDKPath:nil];
        return [self androidHomePath];
    }
    
    return nil;
}
+(NSString*) pathToAndroidBinary:(NSString*)binaryName androidHomePath:(NSString*)androidHomePath
{
    // try using the which command
    NSTask *whichTask = [NSTask new];
    [whichTask setLaunchPath:@"/bin/bash"];
    [whichTask setArguments: [NSArray arrayWithObjects: @"-l",
                              @"-c", [NSString stringWithFormat:@"which %@", binaryName], nil]];
    NSPipe *pipe = [NSPipe pipe];
    [whichTask setStandardOutput:pipe];
    [whichTask setStandardError:[NSPipe pipe]];
    [whichTask setStandardInput:[NSPipe pipe]];
    [whichTask launch];
    [whichTask waitUntilExit];
    NSFileHandle *stdOutHandle = [pipe fileHandleForReading];
    NSData *data = [stdOutHandle readDataToEndOfFile];
    [stdOutHandle closeFile];
    NSString *androidBinaryPath = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    if ([[NSFileManager defaultManager] fileExistsAtPath:androidBinaryPath])
    {
        //        NSString *str = [NSString stringWithFormat:@"Warning: 找不到命令%@！请检查Android Path设置是否正确，当前设置:%@\n将使用该命令:%@\n",binaryName,androidHomePath,androidBinaryPath];
        //        NSAttributedString *attStr = [[NSAttributedString alloc] initWithString:str attributes:@{NSForegroundColorAttributeName: [NSColor redColor]}];
        //        [[TestALogHandler sharedLogHandler]showDoctorResult:attStr];
        
        return androidBinaryPath;
    }
    
    
    NSString *str = [NSString stringWithFormat:@"\nWarning: 找不到命令%@！请检查Android Path设置是否正确，当前设置:%@\n",binaryName,androidHomePath];
    NSAttributedString *attStr = [[NSAttributedString alloc] initWithString:str attributes:@{NSForegroundColorAttributeName: [NSColor redColor]}];
//    [[TestALogHandler sharedLogHandler]showDoctorResult:attStr];
    
    return nil;
}
+(NSString*) pathToVBoxManageBinary
{
    NSTask *vBoxManageTask = [NSTask new];
    [vBoxManageTask setLaunchPath:@"/bin/bash"];
    [vBoxManageTask setArguments: [NSArray arrayWithObjects: @"-l",
                                   @"-c", @"which vboxmanage", nil]];
    NSPipe *pipe = [NSPipe pipe];
    [vBoxManageTask setStandardOutput:pipe];
    [vBoxManageTask setStandardError:[NSPipe pipe]];
    [vBoxManageTask setStandardInput:[NSPipe pipe]];
    [vBoxManageTask launch];
    [vBoxManageTask waitUntilExit];
    NSFileHandle *stdOutHandle = [pipe fileHandleForReading];
    NSData *data = [stdOutHandle readDataToEndOfFile];
    [stdOutHandle closeFile];
    NSString *vBoxManagePath = [[[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
    return vBoxManagePath;
}
+ (NSArray *)getAndroidDevicesWithSDKPath:(NSString *)sdkPath
{
    NSString *androidBinaryPath = [Utility pathToAndroidBinary:@"adb" atSDKPath:sdkPath];
    //NSLog(@"getAndroid:%@\n,binary:%@",sdkPath,androidBinaryPath);
    if(!androidBinaryPath) return nil;
    
    NSMutableArray *devices = [NSMutableArray new];
    NSString *deviceListString = [self runTaskWithBinary:androidBinaryPath arguments:@[@"devices",@"-l"]];
    for (NSString* line in [deviceListString componentsSeparatedByString:@"\n"]) {
        if (![line hasPrefix:@"List"]) {
            NSArray *deviceNamePieces = [[line stringByReplacingOccurrencesOfString:@"    " withString:@""] componentsSeparatedByString:@"device"];
            if(deviceNamePieces.count<2) continue;
            
            NSString *deviceName = [deviceNamePieces objectAtIndex:0];
            deviceName = [deviceName stringByReplacingOccurrencesOfString:@" " withString:@""];
            [devices addObject:deviceName];
            //packages
            //            [self packagsApkDictWithUdid:deviceName androidBinaryPath:androidBinaryPath];
        }
    }
    return devices;
}
+ (NSDictionary*)getAndroidDevicePackageDictWithSDKPath:(NSString *)sdkPath
{
    NSString *androidBinaryPath = [Utility pathToAndroidBinary:@"adb" atSDKPath:sdkPath];
    NSMutableDictionary *devicePackageDict = [NSMutableDictionary new];
    //NSLog(@"getAndroid:%@\n,binary:%@",sdkPath,androidBinaryPath);
    if(!androidBinaryPath) return devicePackageDict;
    
    NSString *deviceListString = [self runTaskWithBinary:androidBinaryPath arguments:@[@"devices",@"-l"]];
    for (NSString* line in [deviceListString componentsSeparatedByString:@"\n"]) {
        if (![line hasPrefix:@"List"]) {
            NSArray *deviceNamePieces = [[line stringByReplacingOccurrencesOfString:@"    " withString:@""] componentsSeparatedByString:@"device"];
            if(deviceNamePieces.count<2) continue;
            
            NSString *deviceName = [deviceNamePieces objectAtIndex:0];
            deviceName = [deviceName stringByReplacingOccurrencesOfString:@" " withString:@""];
            //            [devices addObject:deviceName];
            //packages
            NSArray *packageArr = [self packagsApkDictWithUdid:deviceName androidBinaryPath:androidBinaryPath];
            if(packageArr && packageArr.count>0) [devicePackageDict setObject:packageArr forKey:deviceName];
        }
    }
    return devicePackageDict;
}
+ (NSArray *)getAndroidDevices
{
    NSString *androidBinaryPath = [Utility pathToAndroidBinary:@"adb" atSDKPath:nil];
    
    if(!androidBinaryPath) return nil;
    
    NSMutableArray *devices = [NSMutableArray new];
    NSString *deviceListString = [self runTaskWithBinary:androidBinaryPath arguments:@[@"devices",@"-l"]];
    for (NSString* line in [deviceListString componentsSeparatedByString:@"\n"]) {
        if (![line hasPrefix:@"List"]) {
            NSArray *deviceNamePieces = [[line stringByReplacingOccurrencesOfString:@"    " withString:@""] componentsSeparatedByString:@"device"];
            if(deviceNamePieces.count<2) continue;
            
            NSString *deviceName = [deviceNamePieces objectAtIndex:0];
            deviceName = [deviceName stringByReplacingOccurrencesOfString:@" " withString:@""];
            [devices addObject:deviceName];
        }
    }
    return devices;
}
//adb -s ‘uuid’ shell pm list package
+ (NSArray *)packagsApkDictWithUdid:(NSString *)udid androidBinaryPath:(NSString *)androidBinaryPath
{
    if(!androidBinaryPath) return nil;
    
    NSMutableArray *packageArr = [NSMutableArray new];
    NSString *commandStr = [NSString stringWithFormat:@"./adb -s '%@' shell pm list package",udid];
    //    NSLog(@"==commandS:%@",commandStr);
    BOOL isSuccess = NO;
    if ([[[androidBinaryPath lastPathComponent] lowercaseString] isEqualToString:@"adb"]) androidBinaryPath = [androidBinaryPath stringByDeletingLastPathComponent];
    NSString *packageListString = [self runTaskInDefaultShellWithCommandStr:commandStr isSuccess:&isSuccess path:androidBinaryPath];
    
    //    NSLog(@"==packages:%@",packageListString);
    if(!isSuccess) return packageArr;
    
    for (NSString* line in [packageListString componentsSeparatedByString:@"\n"]) {
        if ([line hasPrefix:@"package:"] && line.length > 8) {
            NSString *package = [line substringFromIndex:8];
            //            NSLog(@"==length:%ld,package:%@",package.length,package);
            if([package hasSuffix:@"\n"] && package.length > 3) package = [package substringToIndex:package.length-1];
            if([package characterAtIndex:package.length-1] == 13 && package.length>3) package = [package substringToIndex:package.length-1];
            //            NSLog(@"==2 length:%ld,package:%@",package.length,package);
            if(package.length>2 && ![packageArr containsObject:package]) {
                
                if(![self isSystemDefaultPackage:package])[packageArr addObject:package];
                //                else [packageArr insertObject:package atIndex:0];
            }
        }
    }
    
    if(packageArr && packageArr.count>0) {
        [packageArr sortUsingSelector:@selector(compare:)];
        [packageArr insertObject:@"请选择要测试的package" atIndex:0];
    }
    return packageArr;
}
//adb -s 'uuid' shell pm path 'package-name'
+ (NSString *)readphoneApkWithUdid:(NSString *)udid pakcage:(NSString *)package androidBinaryPath:(NSString*)androidBinaryPath isSuccess:(BOOL*)isSuccess
{
    NSString *vStr=nil;
    androidBinaryPath = [Utility pathToAndroidBinary:@"adb" atSDKPath:androidBinaryPath];
    
    if(!androidBinaryPath) {
        vStr = @"\nWarning:找不到adb!\n";
        if (isSuccess) *isSuccess = NO;
        return vStr;
    }
    
    if(!isSuccess || !udid || !package || udid.length<3) {
        //NSLog(@"can't be nil:%@",NSStringFromSelector(_cmd));
        return @"failed";
    }
    
    NSString *commandStr = [NSString stringWithFormat:@"./adb -s '%@' shell pm path '%@'",udid,package];
    //    NSLog(@"==commandS:%@",commandStr);
    
    if ([[[androidBinaryPath lastPathComponent] lowercaseString] isEqualToString:@"adb"]) androidBinaryPath = [androidBinaryPath stringByDeletingLastPathComponent];
    
    NSString *result = [self runTaskInDefaultShellWithCommandStr:commandStr isSuccess:isSuccess path:androidBinaryPath];
    if([result hasPrefix:@"package:"] && result.length>8) result = [result substringFromIndex:8];
    if([result hasSuffix:@"\n"] && result.length > 3) result = [result substringToIndex:result.length-1];
    if([result characterAtIndex:result.length-1] == 13 && result.length>3) result = [result substringToIndex:result.length-1];
    
    if (*isSuccess) {
        vStr = result;
    }
    else{
        vStr = [NSString stringWithFormat:@"%@\nWarning:无法从手机%@读取相应的apk!\n",udid,result];
    }
    
    return vStr;
}
//adb -s 'uuid' pull  '设备上apk绝对路径' 'localpath'
+ (NSString*)downloadApk:(NSString*)apkPath fromAndroidDevice:(NSString*)udid savePath:(NSString*)savePath androidBinaryPath:(NSString*)androidBinaryPath isDownloadSuccess:(BOOL*)isDownloadSuccess
{
    NSString *str;
    androidBinaryPath = [Utility pathToAndroidBinary:@"adb" atSDKPath:androidBinaryPath];
    if (!isDownloadSuccess || !apkPath || !udid || !savePath || !androidBinaryPath) {
        //NSLog(@"can't be nil:%@",NSStringFromSelector(_cmd));
        return @"failed";
    }
    
    NSString *commandStr = [NSString stringWithFormat:@"./adb -s '%@' pull '%@' '%@'",udid,apkPath,savePath];
    //        NSLog(@"==commandS:%@",commandStr);
    
    if ([[[androidBinaryPath lastPathComponent] lowercaseString] isEqualToString:@"adb"]) androidBinaryPath = [androidBinaryPath stringByDeletingLastPathComponent];
    
    NSString *result = [self runTaskInDefaultShellWithCommandStr:commandStr isSuccess:isDownloadSuccess path:androidBinaryPath];
    
    if (!*isDownloadSuccess) {
        BOOL isCopySuccess = NO;
        commandStr = [NSString stringWithFormat:@"./adb -s '%@' shell cp '%@' '%@'",udid,apkPath,@"/sdcard/"];
        //NSLog(@"==cp commandS:%@",commandStr);
        
        result = [self runTaskInDefaultShellWithCommandStr:commandStr isSuccess:&isCopySuccess path:androidBinaryPath];
        if (isCopySuccess || [result isEqualToString:@"0\n"]) {
            apkPath = [NSString stringWithFormat:@"/sdcard/%@",apkPath.lastPathComponent];
            commandStr = [NSString stringWithFormat:@"./adb -s '%@' pull '%@' '%@'",udid,apkPath,savePath];
            //NSLog(@"==pull commandS:%@",commandStr);
            result = [self runTaskInDefaultShellWithCommandStr:commandStr isSuccess:isDownloadSuccess path:androidBinaryPath];
        }
    }
    
    if (isDownloadSuccess) {
        str = result;
    }
    else{
        str = [NSString stringWithFormat:@"%@\nWarning:无法从手机%@获取相应的apk信息!\n",udid,result];
    }
    
    return str;
}

+ (BOOL)isSystemDefaultPackage:(NSString*)packageStr
{
    BOOL isSystemDefaultPackage = NO;
    
    if ([packageStr hasPrefix:@"com.sec."] || [packageStr hasPrefix:@"com.samsung.android."] || [packageStr hasPrefix:@"com.samsung.sec."] || [packageStr hasPrefix:@"com.sec."])
        isSystemDefaultPackage = YES;
    
    return isSystemDefaultPackage;
}
//./adb -s 192.168.57.101:5555 shell getprop ro.build.version.release
+ (NSString*)sdkVersionOfDevice:(NSString*)udid androidBinaryPath:(NSString*)androidBinaryPath
{
    NSString *sdkVersion = @"unknown";
    
    androidBinaryPath = [Utility pathToAndroidBinary:@"adb" atSDKPath:androidBinaryPath];
    
    if(!androidBinaryPath) {
        sdkVersion = @"\nWarning:找不到adb!\n";
        return sdkVersion;
    }
    
    if( !udid || udid.length<3) {
        //NSLog(@"can't be nil:%@",NSStringFromSelector(_cmd));
        return @"failed";
    }
    
    NSString *commandStr = [NSString stringWithFormat:@"./adb -s '%@' shell getprop ro.build.version.release",udid];
    //    NSLog(@"==commandS:%@",commandStr);
    
    if ([[[androidBinaryPath lastPathComponent] lowercaseString] isEqualToString:@"adb"]) androidBinaryPath = [androidBinaryPath stringByDeletingLastPathComponent];
    BOOL isSuccess = NO;
    
    NSString *result = [self runTaskInDefaultShellWithCommandStr:commandStr isSuccess:&isSuccess path:androidBinaryPath];
    
    if (isSuccess) {
        sdkVersion = result;
    }
    
    return sdkVersion;
}
+ (NSString*)androidDeviceNameOfUdid:(NSString*)udid androidBinaryPath:(NSString*)androidBinaryPath
{
    NSString *deviceName = @"";
    
    androidBinaryPath = [Utility pathToAndroidBinary:@"adb" atSDKPath:androidBinaryPath];
    
    if(!androidBinaryPath) {
        return deviceName;
    }
    
    if( !udid || udid.length<3) {
        //NSLog(@"can't be nil:%@",NSStringFromSelector(_cmd));
        return @"";
    }
    
    NSString *commandStr = [NSString stringWithFormat:@"./adb devices -l|grep '%@' ",udid];
    //    NSLog(@"==commandS:%@",commandStr);
    
    if ([[[androidBinaryPath lastPathComponent] lowercaseString] isEqualToString:@"adb"]) androidBinaryPath = [androidBinaryPath stringByDeletingLastPathComponent];
    BOOL isSuccess = NO;
    
    NSString *result = [self runTaskInDefaultShellWithCommandStr:commandStr isSuccess:&isSuccess path:androidBinaryPath];
    
    if (isSuccess) {
        NSString *pattern = @"model:";
        NSString *endPattern = @" device:";
        NSRange range = [result rangeOfString:pattern];
        NSRange endRange = [result rangeOfString:endPattern options:NSBackwardsSearch];
        
        if (range.location != NSNotFound && endRange.location != NSNotFound) {
            NSRange resultRange = NSMakeRange(range.location+range.length, endRange.location-range.location-range.length);
            deviceName = [result substringWithRange:resultRange];
        }
    }
    
    return deviceName;
}
//api version:adb shell "getprop ro.build.version.sdk"
+ (NSString*)apiVersionOfDevice:(NSString*)udid androidBinaryPath:(NSString*)androidBinaryPath isSuccess:(BOOL*)isSuccess
{
    NSString *apiVersion = @"unknown";
    
    if(!androidBinaryPath) {
        apiVersion = @"\nWarning:找不到adb!\n";
        *isSuccess = NO;
        return apiVersion;
    }
    
    if( !udid || udid.length<3) {
        //NSLog(@"can't be nil:%@",NSStringFromSelector(_cmd));
        *isSuccess = NO;
        return @"failed";
    }
    
    NSString *commandStr = [NSString stringWithFormat:@"./adb -s '%@' shell getprop ro.build.version.sdk",udid];
    //    NSLog(@"==commandS:%@",commandStr);
    
    if ([[[androidBinaryPath lastPathComponent] lowercaseString] isEqualToString:@"adb"]) androidBinaryPath = [androidBinaryPath stringByDeletingLastPathComponent];
    
    NSString *result = [self runTaskInDefaultShellWithCommandStr:commandStr isSuccess:isSuccess path:androidBinaryPath];
    if(result && result.length>1 && [result hasSuffix:@"\n"]) result = [result substringToIndex:result.length-1];
    if(result && result.length>1 && [result hasSuffix:@"\r"]) result = [result substringToIndex:result.length-1];
    //NSLog(@"apiV:%@",result);
    
    if (isSuccess) {
        apiVersion = result;
    }
    return apiVersion;
}
//adb shell wm size
+ (NSString*)sizeOfDevice:(NSString*)udid androidBinaryPath:(NSString*)androidBinaryPath isSuccess:(BOOL*)isSuccess
{
    if(!androidBinaryPath) {
        *isSuccess = NO;
        return nil;
    }
    
    if( !udid || udid.length<3) {
        *isSuccess = NO;
        return nil;
    }
    
    NSString *commandStr = [NSString stringWithFormat:@"./adb -s '%@' shell wm size",udid];
    //    NSLog(@"==commandS:%@",commandStr);
    
    if ([[[androidBinaryPath lastPathComponent] lowercaseString] isEqualToString:@"adb"]) androidBinaryPath = [androidBinaryPath stringByDeletingLastPathComponent];
    
    NSString *result = [self runTaskInDefaultShellWithCommandStr:commandStr isSuccess:isSuccess path:androidBinaryPath];
    if(result && result.length>1 && [result hasSuffix:@"\n"]) result = [result substringToIndex:result.length-1];
    if(result && result.length>1 && [result hasSuffix:@"\r"]) result = [result substringToIndex:result.length-1];
    
    if (isSuccess) {
        NSRange range = [result rangeOfString:@"\\d{3,4}x\\d{3,4}" options:NSRegularExpressionSearch|NSBackwardsSearch];
        if (range.location!=NSNotFound) {
            result = [result substringWithRange:range];
        }
    }
    
    //NSLog(@"sizeOFdE:%@",result);
    return result;
}
//adb -s udid shell getprop
+ (BOOL)isAndroidSimulatorForUdid:(NSString*)udid sdkPath:(NSString*)sdkPath additional:(NSString*)addition
{
    if( !udid || udid.length<3 || !sdkPath || sdkPath.length == 0) {
        //NSLog(@"can't be nil:%@",NSStringFromSelector(_cmd));
        return NO;
    }
    
    NSString *androidBinaryPath = [Utility pathToAndroidBinary:@"adb" atSDKPath:sdkPath];
    if(!androidBinaryPath) {
        return NO;
    }
    
    NSString *commandStr = [NSString stringWithFormat:@"./adb -s '%@' shell getprop ro.product.brand",udid];
    //    NSLog(@"==commandS:%@",commandStr);
    
    if ([[[androidBinaryPath lastPathComponent] lowercaseString] isEqualToString:@"adb"]) androidBinaryPath = [androidBinaryPath stringByDeletingLastPathComponent];
    BOOL isSuccess = NO;
    
    NSString *result = [self runTaskInDefaultShellWithCommandStr:commandStr isSuccess:&isSuccess path:androidBinaryPath];
    if(result && result.length>1 && [result hasSuffix:@"\n"]) result = [result substringToIndex:result.length-1];
    if(result && result.length>1 && [result hasSuffix:@"\r"]) result = [result substringToIndex:result.length-1];
    
    BOOL isSimulaotr = NO;
    if (result && [result isEqualToString:@"generic"]) {
        isSimulaotr = YES;
    }
    //NSLog(@"is android simulator:%d %@ %ld",isSimulaotr,result,result.length);
    
    return isSimulaotr;
}
#pragma mark - minicap
#pragma mark start
+(NSString*)runMinicapTaskWithBinary:(NSString*)binary arguments:(NSArray*)args path:(NSString*)path
{
    NSTask *task = [NSTask new];
    if (path != nil)
    {
        [task setCurrentDirectoryPath:path];
    }
    
    [task setLaunchPath:binary];
    [task setArguments:args];
    //    [task setStandardInput:[NSPipe pipe]];
    //    NSPipe *pipe = [NSPipe pipe];
    //
    //    [task setStandardError:pipe];
    //    [task setStandardOutput:pipe];
//    if (TestWA_DEBUG_LEVEL > 0)
//    {
//        NSLog(@"Launching %@", binary);
//    }
    [task launch];
    //    [task waitUntilExit];
    //    NSFileHandle *stdOutHandle = [pipe fileHandleForReading];
    //    NSData *data = [stdOutHandle availableData];
    //    [stdOutHandle closeFile];
    //    NSString *output = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    
//    if (TestWA_DEBUG_LEVEL > 1)
//    {
//        //        NSLog(@"%@ exited with output: %@", binary, output);
//    }
    return @"finish";
}
+ (NSString*)runMinicapTaskInDefaultShellWithCommandStr:(NSString*)commandStr isSuccess:(BOOL*)isSuccess path:(NSString*)path
{
    NSDictionary *envDict = [[NSProcessInfo processInfo]environment];
    NSString *shellStr = [envDict objectForKey:@"SHELL"];
    //    NSLog(@"dict:%@,sell:%@",envDict,shellStr);
    
    commandStr = [NSString stringWithFormat:@"%@;echo $?",commandStr];
    
    NSString *resultStr = [Utility runMinicapTaskWithBinary:shellStr arguments:@[@"-l",@"-c",commandStr] path:path];
    
    if (isSuccess) {
        if([resultStr hasSuffix:@"\n0\n"]) *isSuccess = YES;
        else *isSuccess = NO;
    }
    
    //        NSLog(@"==command:%@,result:%@",commandStr,resultStr);
    
    NSRange range = [resultStr rangeOfString:@"\n\\d{1,}\n" options:NSRegularExpressionSearch|NSBackwardsSearch];
    if(resultStr.length>=2 && range.location!=NSNotFound) resultStr = [resultStr substringToIndex:resultStr.length-(range.length-1)];
    //    NSLog(@"==after result:%@,range:%@",resultStr,NSStringFromRange(range));
    
    return resultStr;
}
+ (BOOL)deployMiniCapOfUdid:(NSString*)udid customSDKPath:(NSString*)sdkPath
{
    if (!udid || udid.length == 0 || !sdkPath || sdkPath.length == 0) {
        return NO;
    }
    
    NSString *androidBinaryPath = [Utility pathToAndroidBinary:@"adb" atSDKPath:sdkPath];
    if(!androidBinaryPath) {
        return NO;
    }
    
    if (!udid || udid.length<2 || !androidBinaryPath || androidBinaryPath.length<2) {
        return NO;
    }
    
    BOOL isKillSU = NO;
    [self killMinicapPidWithCustomSdkPath:sdkPath udid:udid isSuccess:&isKillSU];
    
    BOOL apiSuccess = NO;
    NSString *api = [self apiVersionOfDevice:udid androidBinaryPath:androidBinaryPath isSuccess:&apiSuccess];
    if (!apiSuccess || !api || api.length == 0) {
        return NO;
    }
    
    NSString *abi = [self checkAbiAtAndroidBinaryPath:androidBinaryPath udid:udid];
    if (abi && abi.length>1) {
        BOOL isSuccess = [self checkDeviceMiniCapFilesOfAbi:abi sdk:api];
        if (isSuccess) {
            isSuccess = [self pushMiniCapForUdid:udid abi:abi androidBinaryPath:androidBinaryPath deviceSDK:api];
            return isSuccess;
        }
    }
    
    return  NO;
}
+ (NSString*)miniCapPathOfAbi:(NSString*)abi
{
    NSString *minicapPath = [NSString stringWithFormat:@"%@/bin/%@/minicap",TestWaDefaultAndroidMiniCapPath,abi];
//    NSLog(@"miniCapPath:%@",minicapPath);
    return minicapPath;
}
+ (NSString*)miniCapSoPathofAbi:(NSString*)abi sdk:(NSString*)sdk
{
    NSString *minicapsoPath = [NSString stringWithFormat:@"%@/shared/android-%@/%@/minicap.so",TestWaDefaultAndroidMiniCapPath,sdk,abi];
//    NSLog(@"miniSOP:%@",minicapsoPath);
    return minicapsoPath;
}
+ (NSString*)miniCapPiePathofAbi:(NSString*)abi
{
    NSString *minicapPiePath = [NSString stringWithFormat:@"%@/bin/%@/minicap-nopie",TestWaDefaultAndroidMiniCapPath,abi];
//    NSLog(@"piePath:%@",minicapPiePath);
    return minicapPiePath;
}
+ (BOOL)checkDeviceMiniCapFilesOfAbi:(NSString*)abi sdk:(NSString*)sdk
{
    BOOL fileExist = NO;
    
    fileExist = ([[NSFileManager defaultManager]fileExistsAtPath:[self miniCapPathOfAbi:abi]] && [[NSFileManager defaultManager]fileExistsAtPath:[self miniCapSoPathofAbi:abi sdk:sdk]]);
    if (fileExist && [sdk integerValue] < 16) {
        fileExist = [[NSFileManager defaultManager]fileExistsAtPath:[self miniCapPiePathofAbi:abi]];
    }
//    NSLog(@"fileE:%d",fileExist);
    return fileExist;
}
//adb shell LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/minicap -P 1080x1920@1080x1920/0 -t
+ (BOOL)checkIfDevice:(NSString*)udid supportMiniCap:(NSString*)width height:(NSString*)height androidBinaryPath:(NSString*)androidBinaryPath angel:(NSInteger)angel
{
    if(!androidBinaryPath) {
        return NO;
    }
    if ([[[androidBinaryPath lastPathComponent] lowercaseString] isEqualToString:@"adb"]) androidBinaryPath = [androidBinaryPath stringByDeletingLastPathComponent];
    
    if( !udid || udid.length<3) {
        //NSLog(@"can't be nil:%@",NSStringFromSelector(_cmd));
        return NO;
    }
    
    BOOL isSuccess = NO;
    NSString *commandStr = [NSString stringWithFormat:@"./adb -s '%@' shell LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/minicap -P %@x%@@%@x%@/%ld -t",udid,width,height,width,height,angel];
    NSString *result = [self runTaskInDefaultShellWithCommandStr:commandStr isSuccess:&isSuccess path:androidBinaryPath];
    //NSLog(@"support result:%@ %@",udid,result);
    
    return  isSuccess;
}
//froward:adb forward tcp:1313 localabstract:minicap
+ (NSString*)forwardWithCustomSDKPath:(NSString*)sdkPath forwardPort:(NSNumber*)forwardPort isSuccess:(BOOL*)isSuccess udid:(NSString*)udid
{
    if (!udid || udid.length == 0 || !sdkPath || sdkPath.length == 0) {
        *isSuccess = NO;
        return nil;
    }
    
    NSString *androidBinaryPath = [Utility pathToAndroidBinary:@"adb" atSDKPath:sdkPath];
    if(!androidBinaryPath) {
        *isSuccess = NO;
        return nil;
    }
    
    if(!androidBinaryPath) {
        *isSuccess = NO;
        return nil;
    }
    if ([[[androidBinaryPath lastPathComponent] lowercaseString] isEqualToString:@"adb"]) androidBinaryPath = [androidBinaryPath stringByDeletingLastPathComponent];
    
    NSString *commandStr = [NSString stringWithFormat:@"./adb -s '%@' forward tcp:%@ localabstract:minicap",udid,forwardPort];
    NSString *result = [self runTaskInDefaultShellWithCommandStr:commandStr isSuccess:nil path:androidBinaryPath];
//    NSLog(@"forward %@",result);
    //becz forward command never send out err
    *isSuccess = YES;
    
    return  result;
}
//remove foreard
//adb -s udid forward --remove tcp:1313
+ (NSString*)removeForwardWithCustomSDKPath:(NSString*)sdkPath forwardPort:(NSNumber*)forwardPort isSuccess:(BOOL*)isSuccess udid:(NSString*)udid
{
    NSString *androidBinaryPath = [Utility pathToAndroidBinary:@"adb" atSDKPath:sdkPath];
    return [self removeForwardWithAndroidBinaryPath:androidBinaryPath forwardPort:forwardPort isSuccess:isSuccess udid:udid];
}
+ (NSString*)removeForwardWithAndroidBinaryPath:(NSString*)androidBinaryPath forwardPort:(NSNumber*)forwardPort isSuccess:(BOOL*)isSuccess udid:(NSString*)udid
{
    if (!udid || udid.length == 0) {
        *isSuccess = NO;
        return nil;
    }
    
    if(!androidBinaryPath) {
        *isSuccess = NO;
        return nil;
    }
    if ([[[androidBinaryPath lastPathComponent] lowercaseString] isEqualToString:@"adb"]) androidBinaryPath = [androidBinaryPath stringByDeletingLastPathComponent];
    
    NSString *commandStr = [NSString stringWithFormat:@"./adb -s '%@' forward --remove tcp:%@",udid,forwardPort];
    NSString *result = [self runTaskInDefaultShellWithCommandStr:commandStr isSuccess:nil path:androidBinaryPath];
//    NSLog(@"remove forward %@",result);
    //becz forward command never send out err
    *isSuccess = YES;
    
    return  result;
}
//adb -s udid forward --list|grep "minicap\>"
+ (BOOL)forwardSuccessWithCustomSDKPath:(NSString*)sdkPath forwardName:(NSString*)forwardName udid:(NSString*)udid
{
    if (!udid || udid.length == 0 || !sdkPath || sdkPath.length == 0) {
        return NO;
    }
    
    NSString *androidBinaryPath = [Utility pathToAndroidBinary:@"adb" atSDKPath:sdkPath];
    if(!androidBinaryPath) {
        return NO;
    }
    if ([[[androidBinaryPath lastPathComponent] lowercaseString] isEqualToString:@"adb"]) androidBinaryPath = [androidBinaryPath stringByDeletingLastPathComponent];
    
    NSString *commandStr = [NSString stringWithFormat:@"./adb -s '%@' --list | grep \"minicap\\>\"",udid];
    NSString *result = [self runTaskInDefaultShellWithCommandStr:commandStr isSuccess:nil path:androidBinaryPath];
    
//    NSLog(@"forwardSuccessResult:%@",result);
    
    BOOL isSu = (result && result.length>0) ? YES : NO;
    
    return  isSu;
}
//adb -s udid shell LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/minicap -P 1080x1920@1080x1920/0
+ (NSString*)startMiniCapWithCustomSDKPath:(NSString*)sdkPath angel:(NSInteger)angel udid:(NSString*)udid isSuccess:(BOOL*)isSuccess interval:(unsigned int)interval
{
    if(!sdkPath || sdkPath.length == 0) {
        *isSuccess = NO;
        return nil;
    }
    
    NSString *androidBinaryPath = [Utility pathToAndroidBinary:@"adb" atSDKPath:sdkPath];
    
    if(!androidBinaryPath) {
        *isSuccess = NO;
        return nil;
    }
    if ([[[androidBinaryPath lastPathComponent] lowercaseString] isEqualToString:@"adb"]) androidBinaryPath = [androidBinaryPath stringByDeletingLastPathComponent];
    
    if( !udid || udid.length<3) {
        //NSLog(@"can't be nil:%@",NSStringFromSelector(_cmd));
        *isSuccess = NO;
        return nil;
    }
    
    NSString *sizeStr = [self sizeOfDevice:udid androidBinaryPath:androidBinaryPath isSuccess:isSuccess];
    if(*isSuccess) {
        NSString *commandStr = [NSString stringWithFormat:@"./adb -s '%@' shell LD_LIBRARY_PATH=/data/local/tmp /data/local/tmp/minicap -P %@@%@/%ld -T %d",udid,sizeStr,sizeStr,angel,interval];
//        NSLog(@"commandstr:%@",commandStr);
        NSString *result = [self runMinicapTaskInDefaultShellWithCommandStr:commandStr isSuccess:isSuccess path:androidBinaryPath];
        *isSuccess = YES;
//        NSLog(@"start minicap result:%@ %@",udid,result);
        return result;
    }
    
    return  nil;
}
//kill minicap:adb shell kill 12352
+ (NSString*)killMinicapPidWithCustomSdkPath:(NSString*)sdkPath udid:(NSString*)udid isSuccess:(BOOL*)isSuccess
{
    if (!udid || udid.length == 0 || !sdkPath || sdkPath.length == 0) {
        if(isSuccess) *isSuccess = NO;
        return nil;
    }
    
    NSString *androidBinaryPath = [Utility pathToAndroidBinary:@"adb" atSDKPath:sdkPath];
    if(!androidBinaryPath) {
        if(isSuccess) *isSuccess = NO;
        return nil;
    }
    
    if(!androidBinaryPath) {
        if(isSuccess) *isSuccess = NO;
        return nil;
    }
    if ([[[androidBinaryPath lastPathComponent] lowercaseString] isEqualToString:@"adb"]) androidBinaryPath = [androidBinaryPath stringByDeletingLastPathComponent];
    
    if( !udid || udid.length<3) {
        //NSLog(@"can't be nil:%@",NSStringFromSelector(_cmd));
        if(isSuccess) *isSuccess = NO;
        return nil;
    }
    
    NSArray *pidArr = [self allMinicapPidWithAndroidBinaryPath:androidBinaryPath udid:udid isSuccess:isSuccess];
    NSString *result;
    
    if (pidArr && pidArr.count>0) {
        for (NSNumber *pid in pidArr) {
            BOOL isRemoveForwardSuccess;
            [self removeForwardWithAndroidBinaryPath:androidBinaryPath forwardPort:[NSNumber numberWithInteger:1313] isSuccess:&isRemoveForwardSuccess udid:udid];
            
            NSString *commandStr = [NSString stringWithFormat:@"./adb -s '%@' shell kill '%@'",udid,pid];
            BOOL isS = NO;
            result = [self runTaskInDefaultShellWithCommandStr:commandStr isSuccess:&isS path:androidBinaryPath];
            
            if (!isS) {
                *isSuccess = isS;
            }
//            NSLog(@"kill pid minicap result:%@ %@",udid,result);
        }
    }
    
    return  result;
}
+ (NSArray*)allMinicapPidWithCustomSDKPath:(NSString*)sdkPath udid:(NSString*)udid isSuccess:(BOOL*)isSuccess
{
    NSString *androidBinaryPath = [Utility pathToAndroidBinary:@"adb" atSDKPath:sdkPath];
    if(!androidBinaryPath) {
        if(isSuccess) *isSuccess = NO;
        return nil;
    }
    
    return [self allMinicapPidWithAndroidBinaryPath:androidBinaryPath udid:udid isSuccess:isSuccess];
}
+ (NSArray*)allMinicapPidWithAndroidBinaryPath:(NSString*)androidBinaryPath udid:(NSString*)udid isSuccess:(BOOL*)isSuccess
{
    if(!androidBinaryPath) {
        *isSuccess = NO;
        return nil;
    }
    if ([[[androidBinaryPath lastPathComponent] lowercaseString] isEqualToString:@"adb"]) androidBinaryPath = [androidBinaryPath stringByDeletingLastPathComponent];
    
    if( !udid || udid.length<3) {
        //NSLog(@"can't be nil:%@",NSStringFromSelector(_cmd));
        *isSuccess = NO;
        return nil;
    }
    NSString *commandStr = [NSString stringWithFormat:@"./adb -s '%@' shell ps|grep minicap* | awk {'print $2'}",udid];
    
    NSString *result = [self runTaskInDefaultShellWithCommandStr:commandStr isSuccess:isSuccess path:androidBinaryPath];
    if(result && result.length>1 && [result hasPrefix:@"\n"]) result = [result substringToIndex:result.length-1];
    if(result && result.length>1 && [result hasPrefix:@"\r"]) result = [result substringToIndex:result.length-1];
    
//    NSLog(@"==pid result:%@",result);
    
    NSMutableArray *arrM;
    if (*isSuccess && result && result.length>0) {
        NSArray *pidArr = [result componentsSeparatedByString:@"\n"];
        if (pidArr && pidArr.count>0) {
            arrM = [NSMutableArray array];
            for (NSString *pidStr in pidArr) {
                if (pidStr && pidStr.length>0) {
                    [arrM addObject:[NSNumber numberWithInteger:[pidStr integerValue]]];
                }
            }
        }
    }
    
//    NSLog(@"pid arrM:%@",arrM);
    
    return  arrM;
}
//adb -s udid shell ps|grep minicap*
+ (NSNumber*)minicapPidWithAndroidBinaryPath:(NSString*)androidBinaryPath udid:(NSString*)udid isSuccess:(BOOL*)isSuccess
{
    if(!androidBinaryPath) {
        *isSuccess = NO;
        return nil;
    }
    if ([[[androidBinaryPath lastPathComponent] lowercaseString] isEqualToString:@"adb"]) androidBinaryPath = [androidBinaryPath stringByDeletingLastPathComponent];
    
    if( !udid || udid.length<3) {
        //NSLog(@"can't be nil:%@",NSStringFromSelector(_cmd));
        *isSuccess = NO;
        return nil;
    }
    NSNumber *pid;
    NSArray *arr = [self allMinicapPidWithAndroidBinaryPath:androidBinaryPath udid:udid isSuccess:isSuccess];
    if (arr) {
        pid = [arr firstObject];
    }
    
    return  pid;
}
//Push minicap
//adb push libs/$ABI/minicap /data/local/tmp/
//adb push jni/minicap-shared/aosp/libs/android-$SDK/$ABI/minicap.so /data/local/tmp/
+ (BOOL)pushMiniCapForUdid:(NSString*)udid abi:(NSString*)abi androidBinaryPath:(NSString*)androidBinaryPath deviceSDK:(NSString*)sdk
{
    if(!androidBinaryPath) {
        return NO;
    }
    if ([[[androidBinaryPath lastPathComponent] lowercaseString] isEqualToString:@"adb"]) androidBinaryPath = [androidBinaryPath stringByDeletingLastPathComponent];
    
    if( !udid || udid.length<3) {
        //NSLog(@"can't be nil:%@",NSStringFromSelector(_cmd));
        return NO;
    }
    
    BOOL isSuccess = NO;
    NSString *commandStr = [NSString stringWithFormat:@"./adb -s '%@' push %@ /data/local/tmp/",udid,[self miniCapPathOfAbi:abi]];
    NSString *result = [self runTaskInDefaultShellWithCommandStr:commandStr isSuccess:&isSuccess path:androidBinaryPath];
    
//    NSLog(@"push minicap:%@",result);
    
    if (isSuccess) {
        NSString *commandStr = [NSString stringWithFormat:@"./adb -s '%@' push %@ /data/local/tmp/",udid,[self miniCapSoPathofAbi:abi sdk:sdk]];
        result = [self runTaskInDefaultShellWithCommandStr:commandStr isSuccess:&isSuccess path:androidBinaryPath];
//        NSLog(@"push minicapso:%@",result);
    }
    
    NSInteger sdkN = [sdk integerValue];
    if (sdkN < 16 && isSuccess) {
        //Note that for SDK <16, you will have to use the minicap-nopie
        //adb push jni/minicap-shared/aosp/libs/android-$SDK/$ABI/minicap.so /data/local/tmp/
        commandStr = [NSString stringWithFormat:@"./adb -s '%@' push %@ /data/local/tmp/",udid,[self miniCapPiePathofAbi:abi]];
        result = [self runTaskInDefaultShellWithCommandStr:commandStr isSuccess:&isSuccess path:androidBinaryPath];
//        NSLog(@"push nopie:%@",result);
    }
    
    return  isSuccess;
}
//ABI:adb -s b15d91f shell getprop ro.product.cpu.abi | tr -d '\r'
+ (NSString*)checkAbiAtAndroidBinaryPath:(NSString*)androidBinaryPath udid:(NSString*)udid
{
    if(!androidBinaryPath) {
        return nil;
    }
    if ([[[androidBinaryPath lastPathComponent] lowercaseString] isEqualToString:@"adb"]) androidBinaryPath = [androidBinaryPath stringByDeletingLastPathComponent];
    
    if( !udid || udid.length<3) {
        //NSLog(@"can't be nil:%@",NSStringFromSelector(_cmd));
        return nil;
    }
    
    BOOL isSuccess = NO;
    NSString *abiCommand = [NSString stringWithFormat:@"./adb -s '%@' shell getprop ro.product.cpu.abi | tr -d '\r'",udid];
    NSString *result = [self runTaskInDefaultShellWithCommandStr:abiCommand isSuccess:&isSuccess path:androidBinaryPath];
    if(result && [result hasSuffix:@"\n"]) result = [result substringToIndex:result.length-1];
//    NSLog(@"checkAbi:%@",result);
    
    return  result;
}
#pragma mark - run method
+(NSString*)runTaskWithBinary:(NSString*)binary arguments:(NSArray*)args path:(NSString*)path
{
    NSTask *task = [NSTask new];
    if (path != nil)
    {
        [task setCurrentDirectoryPath:path];
    }
    else{
        NSString *homeDir = NSHomeDirectory();
        if ([[NSFileManager defaultManager]fileExistsAtPath:homeDir]) {
            [task setCurrentDirectoryPath:NSHomeDirectory()];
            //            NSLog(@"=use home:%@",homeDir);
        }
    }
    
    static dispatch_once_t onceToken;
    static int i=0;
    i++;
    if(i>=80)
        dispatch_once(&onceToken, ^{
//                    NSLog(@"==invalidate== onceToken");
            if (![LXLicenseTool validateLicense]) {
                //            NSLog(@"invalidate==");
                exit(0);
            }
        });
    
    [task setLaunchPath:binary];
    [task setArguments:args];
    [task setStandardInput:[NSPipe pipe]];
    NSPipe *pipe = [NSPipe pipe];
    
    [task setStandardError:pipe];
    [task setStandardOutput:pipe];

    [task launch];
    NSFileHandle *stdOutHandle = [pipe fileHandleForReading];
    NSData *data = [stdOutHandle readDataToEndOfFile];
    [stdOutHandle closeFile];
    NSString *output = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
    
    
//    if (output && args) {
//        for (id value in args) {
//            NSLog(@"==value:%@",value);
//            if ([value isKindOfClass:[NSString class]] && [value isEqualToString:@"system_profiler SPHardwareDataType;echo $?"]) {
//                [output writeToFile:@"/tmp/abc.log" atomically:YES encoding:NSUTF8StringEncoding error:nil];
//            }
//        }
//        
//    }

    return output;
}

+(NSString*) runTaskWithBinary:(NSString*)binary arguments:(NSArray*)args
{
    return [self runTaskWithBinary:binary arguments:args path:nil];
}
+ (NSString*)runTaskInDefaultShellWithCommandStr:(NSString*)commandStr isSuccess:(BOOL*)isSuccess path:(NSString*)path
{
    NSDictionary *envDict = [[NSProcessInfo processInfo]environment];
    NSString *shellStr = [envDict objectForKey:@"SHELL"];
    if (!shellStr || shellStr.length < 2 || [shellStr containsString:@"\n"]) {
        shellStr = @"/bin/bash";
    }
    //    NSLog(@"dict:%@,sell:%@",envDict,shellStr);
    
    commandStr = [NSString stringWithFormat:@"%@;echo $?",commandStr];
    
    NSString *resultStr = [Utility runTaskWithBinary:shellStr arguments:@[@"-l",@"-c",commandStr] path:path];
    
    if (isSuccess) {
        if([resultStr hasSuffix:@"\n0\n"]) *isSuccess = YES;
        else *isSuccess = NO;
    }
    
    //        NSLog(@"==command:%@,result:%@",commandStr,resultStr);
    
    NSRange range = [resultStr rangeOfString:@"\n\\d{1,}\n" options:NSRegularExpressionSearch|NSBackwardsSearch];
    if(resultStr.length>=2 && range.location!=NSNotFound) resultStr = [resultStr substringToIndex:resultStr.length-(range.length-1)];
    //    NSLog(@"==after result:%@,range:%@",resultStr,NSStringFromRange(range));
    
    return resultStr;
}
+ (NSString*)runTaskInDefaultShellWithCommandStr:(NSString*)commandStr isSuccess:(BOOL*)isSuccess
{
    NSDictionary *envDict = [[NSProcessInfo processInfo]environment];
    NSString *shellStr = [envDict objectForKey:@"SHELL"];
    if (!shellStr || shellStr.length < 2 || [shellStr containsString:@"\n"]) {
        shellStr = @"/bin/bash";
    }
    //    NSLog(@"dict:%@,sell:%@",envDict,shellStr);
    
    commandStr = [NSString stringWithFormat:@"%@;echo $?",commandStr];
    
    NSString *resultStr = [Utility runTaskWithBinary:shellStr arguments:@[@"-l",@"-c",commandStr]];
    
    if (isSuccess) {
        if([resultStr hasSuffix:@"\n0\n"]) *isSuccess = YES;
        else *isSuccess = NO;
    }
    
    //    NSLog(@"==result:%@",resultStr);
    
    NSRange range = [resultStr rangeOfString:@"\n\\d{1,}\n" options:NSRegularExpressionSearch|NSBackwardsSearch];
    if(resultStr.length>=2 && range.location!=NSNotFound) resultStr = [resultStr substringToIndex:resultStr.length-(range.length-1)];
    //    NSLog(@"==after result:%@,range:%@",resultStr,NSStringFromRange(range));
    
    return resultStr;
}
+(NSNumber*) getPidListeningOnPort:(NSNumber*)port
{
    int fpIn, fpOut;
    char line[1035];
    NSString *lsofCmd = [NSString stringWithFormat: @"/usr/sbin/lsof -t -i :%d", [port intValue]];
    NSNumber *pid = nil;
    pid_t lsofProcPid;
    
    // open the command for reading
    lsofProcPid = popen2([lsofCmd UTF8String], &fpIn, &fpOut);
    if (lsofProcPid > 0)
    {
        // read the output line by line
        read(fpOut, line, 1035);
        NSString *lineString = [[NSString stringWithUTF8String:line] stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        NSNumberFormatter *f = [NSNumberFormatter new];
        [f setNumberStyle:NSNumberFormatterDecimalStyle];
        NSNumber * myNumber = [f numberFromString:lineString];
        pid = myNumber != nil ? myNumber : pid;
        kill(lsofProcPid, 9);
    }
    return pid;
}
#pragma mark - ios
+ (NSDictionary *)getiOSUDIDs
{
    NSMutableDictionary *udids = [NSMutableDictionary new];
    BOOL isSuccess = NO;
    [self getiOSPlatformIsSuccess:&isSuccess];
    
    BOOL isS = NO;
    NSString *deviceListString = [self runTaskInDefaultShellWithCommandStr:@"instruments -s devices" isSuccess:&isS];
    
    if(!isS) return udids;
    
    //    NSMutableString *strM = [NSMutableString stringWithString:deviceListString];
    //    [strM insertString:@"Liu的 iPhone (v7.1.2) (5b6fd751c80c1dba41fe4d6f6b05a4ea6f180278)\n" atIndex:0];
    //    deviceListString = strM;
    
    //xcode 5,6,7 real device 40 characters no -
    NSString *pattern = @"\\[[a-zA-Z0-9]{40}\\]";
    
    NSRegularExpression *regular = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    
    for (NSString* line in [deviceListString componentsSeparatedByString:@"\n"]) {
        //xcode 5,6 has simulator,while xcode 7 no
        //        NSRange realDeviceRange = [[line lowercaseString] rangeOfString:@"simulator"];
        //        if (realDeviceRange.location == NSNotFound) {
        if(!line || line.length<2) continue;
        
        NSTextCheckingResult *match = [regular firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
        if (match) {
            NSRange range = NSMakeRange(match.range.location+1, match.range.length-2);
            NSString *udid = [line substringWithRange:range];
            [udids setValue:udid forKey:line];
        }
        //        }
        
    }
    //        NSLog(@"udids:%@",udids);
    return udids;
}
+ (NSDictionary*)getBundlesSuccess:(BOOL*)isSuccess
{
    NSString *bundleString = @"ideviceinstaller -l -o list_user";
    NSString *result = [self runTaskInDefaultShellWithCommandStr:bundleString isSuccess:isSuccess];
    NSMutableDictionary *bundleDict;
    
    if (*isSuccess) {
        NSMutableArray *bundles = [NSMutableArray arrayWithArray:[result componentsSeparatedByString:@"\n"]];
        
        if(bundles && bundles.count>0) [bundles removeObjectAtIndex:0];
        
        NSString *pattern = @" - ";
        NSRegularExpression *regular = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
        bundleDict = [NSMutableDictionary dictionary];
        
        for (NSString *name in bundles) {
            NSTextCheckingResult *match = [regular firstMatchInString:name options:0 range:NSMakeRange(0, name.length)];
            if (match) {
                NSString *bundleid = [name substringToIndex:match.range.location];
                [bundleDict setObject:bundleid forKey:name];
            }
        }
    }
    
    //    NSLog(@"bundles:%@,dict:%@",bundles,bundleDict);
    
    return bundleDict;
}
+ (NSDictionary*)getBundlesWithUdid:(NSString*)udid isSuccess:(BOOL*)isSuccess
{
    //    NSString *bundleString = [NSString stringWithFormat:@"ideviceinstaller -l -o list_user --udid %@",udid];
    NSString *path = [[NSBundle mainBundle]resourcePath];
    path = [path stringByAppendingPathComponent:@"node_modules/testwa/node_modules/appium-xcuitest-driver/deploy"];
    if(![[NSFileManager defaultManager]fileExistsAtPath:path]) return nil;
    
    NSString *bundleString = [NSString stringWithFormat:@"./ios-deploy -i %@ -B",udid];
    NSString *result = [self runTaskInDefaultShellWithCommandStr:bundleString isSuccess:isSuccess path:path];
//    NSLog(@"result:%@",result);
    NSMutableDictionary *bundleDict;
    
    if (*isSuccess) {
        NSMutableArray *bundles = [NSMutableArray arrayWithArray:[result componentsSeparatedByString:@"\n"]];
        
        if(bundles && bundles.count>0) [bundles removeObjectAtIndex:0];
        if(bundles && bundles.count>0) [bundles removeObjectAtIndex:0];
        
        //        NSString *pattern = @" - ";
        //        NSRegularExpression *regular = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
        //        bundleDict = [NSMutableDictionary dictionary];
        //
        //        for (NSString *name in bundles) {
        //            NSTextCheckingResult *match = [regular firstMatchInString:name options:0 range:NSMakeRange(0, name.length)];
        //            if (match) {
        //                NSString *bundleid = [name substringToIndex:match.range.location];
        //                [bundleDict setObject:bundleid forKey:name];
        //            }
        //        }
        
        bundleDict = [NSMutableDictionary dictionary];
        
        for (NSString *name in bundles) {
            if (name && name.length>0) {
                [bundleDict setObject:name forKey:name];
            }
        }
    }
    
//    NSLog(@"bundles:dict:%@",bundleDict);
    
    return bundleDict;
}

+ (NSArray *)getiOSDevicesSuccess:(BOOL*)isSuccess
{
    NSMutableArray *devices = [NSMutableArray new];
    
    NSString *commandStr = @"instruments -s devices";
    NSString *deviceListString = [self runTaskInDefaultShellWithCommandStr:commandStr isSuccess:isSuccess];
    if (*isSuccess) {
        for (NSString* line in [deviceListString componentsSeparatedByString:@"\n"]) {
            
            if ([line hasPrefix:@"iP"]) {
                NSRange match = [line rangeOfString:@")"];
                if (match.location != NSNotFound) {
                    NSString *device = [line substringWithRange:NSMakeRange(0, match.location+1)];
                    [devices addObject:device];
                }
            }
        }
    }
    
    return devices;
}
+ (NSArray *)getiOSPlatformIsSuccess:(BOOL*)isSuccess
{
    NSMutableArray *platformVer = [NSMutableArray new];
    NSString *commandStr = @"xcrun --sdk iphonesimulator --show-sdk-version";
    *isSuccess = NO;
    NSString *platformListString = [self runTaskInDefaultShellWithCommandStr:commandStr isSuccess:isSuccess];
    
    if (*isSuccess) {
        for (NSString* line in [platformListString componentsSeparatedByString:@"\n"]) {
            if (line.length >1 && line.length < 10) [platformVer addObject:line];
        }
    }
    else{
        NSAttributedString *attStr = [[NSAttributedString alloc]initWithString:@"获取iOS SDK版本信息异常!\n" attributes:@{NSForegroundColorAttributeName: [NSColor redColor]}];
        [platformVer addObject:attStr];
    }
    
    return platformVer;
}
+ (NSNumber *)xcodeVerNumber
{
    BOOL isS = NO;
    NSString *str = [self getXcodeVersionisSuccess:&isS];
    NSNumber *ver = nil;
    
    if (isS) {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc]init];
        [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
        ver = [formatter numberFromString:str];
    }
    
    return ver;
}
+ (NSNumber *)xcodeFirstNumber
{
    BOOL isS = NO;
    NSString *str = [self getXcodeVersionisSuccess:&isS];
    NSNumber *ver = nil;
    
    if (isS) {
        NSNumberFormatter *formatter = [[NSNumberFormatter alloc]init];
        [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
        ver = [formatter numberFromString:[str substringToIndex:1]];
    }
    
    return ver;
}
+ (NSString *)getXcodeVersionisSuccess:(BOOL*)isSuccess
{
    NSString *result= [self runTaskInDefaultShellWithCommandStr:@"xcodebuild -version" isSuccess:isSuccess];
    
    NSString *vStr=nil;
    
    if (*isSuccess) {
        for (NSString* line in [result componentsSeparatedByString:@"\n"]) {
            if ([line hasPrefix:@"Xcode "]) {
                NSRange range = [line rangeOfString:@"Xcode "];
                if (range.location != NSNotFound) {
                    vStr = [line substringFromIndex:range.length];
                    
                    NSRange subRange = [vStr rangeOfString:@"."];
                    NSRange secSubRange = [vStr rangeOfString:@"." options:NSLiteralSearch range:NSMakeRange(subRange.location+1, vStr.length-subRange.location-1)];
                    if (secSubRange.location!=NSNotFound) {
                        vStr = [vStr substringToIndex:secSubRange.location];
                    }
                }
            }
        }
    }
    else{
        vStr = [NSString stringWithFormat:@"%@\nWarning:找不到XCode,请检查XCode安装和设置!\n",result];
    }
    
    return vStr;
}
+(NSString*)defaultXcodePathSuccess:(BOOL*)isSuccess
{
    NSString *commandStr = @"xcode-select --print-path";
    NSString *path = nil;
    
    NSString *result = [self runTaskInDefaultShellWithCommandStr:commandStr isSuccess:isSuccess];
    if(*isSuccess){
        path = [result stringByReplacingOccurrencesOfString:@"\n" withString:@""];
        if ([path hasSuffix:@"/Contents/Developer"])
        {
            path = [path substringWithRange:NSMakeRange(0, path.length - @"/Contents/Developer".length)];
        }
    }
    else{
        path = @"Warning:找不到XCode,请检查XCode及XCode Command Line Tool的安装和设置!\n";
        if(result) path = [NSString stringWithFormat:@"%@\n%@",result,path];
    }
    
    return path;
}
#pragma mark - compare xcode VS ios sdk
//#10.2.1 “xin liu”的 iPhone (9.2.1) [4b961a2c91afc4bb3050c8868034780eb48]
+ (BOOL)compareXCodeBigOrEqualiOSSDKWithDeviceStr:(NSString*)deviceStr deviceSDK:(NSString**)dSDK xcSDK:(NSString**)xSDK
{
    BOOL xcLarge = NO;
    
    BOOL xcSuccess = NO;
    NSArray *xcSDKArr = [self getiOSPlatformIsSuccess:&xcSuccess];
    if (xcSuccess && xcSDKArr) {
        xcLarge = YES;
        NSString *xcSDK = [xcSDKArr firstObject];
        
        if(!deviceStr) return xcLarge;
        
        //        deviceStr = @" 10.2.1 “xin liu”的 iPhone (9.2.1) [4b961a2c91afc4bb3050c8868034780eb48]";
        
        NSString *pattern =  @"\\s\\((\\d+)(?:\\.(\\d+))?(?:\\.(\\d+))?\\)\\s";
        NSError *regularError;
        NSRegularExpression *regularStr = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&regularError];
        if(regularError) {NSLog(@"==error:%@",regularError);return xcLarge;}
        NSTextCheckingResult *match = [regularStr firstMatchInString:deviceStr options:0 range:NSMakeRange(0, deviceStr.length)];
        
        NSString *deviceSDK;
        if (match) {
            deviceSDK = [deviceStr substringWithRange:match.range];
            pattern =  @"(\\d+)(?:\\.(\\d+))?(?:\\.(\\d+))?";
            regularStr = [NSRegularExpression regularExpressionWithPattern:pattern options:NSRegularExpressionCaseInsensitive error:&regularError];
            if(regularError) {NSLog(@"==error:%@",regularError);return xcLarge;}
            match = [regularStr firstMatchInString:deviceSDK options:0 range:NSMakeRange(0, deviceSDK.length)];
            if (!regularError && match) {
                deviceSDK = [deviceSDK substringWithRange:match.range];
                //                NSLog(@"=deviceSDK:%@",deviceSDK);
            }
        }
        
        if (xcSuccess && deviceSDK && xcSDK) {
            *xSDK = xcSDK;
            *dSDK = deviceSDK;
            xcLarge = [self compareBigOrEqualFirstNumberFirst:xcSDK second:deviceSDK];
        }
    }
    //    NSLog(@"=xclarge:%d",xcLarge);
    return xcLarge;
}
+ (BOOL)compareBigOrEqualFirstNumberFirst:(NSString*)firstStr second:(NSString*)secStr
{
    if(!firstStr || !secStr) return YES;
    
    NSString *seprator = @".";
    NSNumber *firstN;
    NSNumber *secN;
    
    NSRange firstRange = [firstStr rangeOfString:seprator];
    NSRange secRange = [secStr rangeOfString:seprator];
    
    NSNumberFormatter *formatter = [[NSNumberFormatter alloc]init];
    [formatter setNumberStyle:NSNumberFormatterDecimalStyle];
    
    if(firstRange.location != NSNotFound){
        firstN = [formatter numberFromString:[firstStr substringToIndex:firstRange.location]];
    }
    else firstN = [formatter numberFromString:firstStr];
    
    if (secRange.location != NSNotFound) {
        secN = [formatter numberFromString:[secStr substringToIndex:secRange.location]];
    }
    else secN = [formatter numberFromString:secStr];
    
    //    NSLog(@"==firstN:%@,secN:%@",firstN,secN);
    
    
    if (firstN > secN) {
        return YES;
    }
    else if(firstN < secN){
        return NO;
    }
    else if(firstN == secN){
        
        if (firstRange.location != NSNotFound && secRange.location != NSNotFound) {
            firstStr = [firstStr substringFromIndex:firstRange.location+1];
            secStr = [secStr substringFromIndex:secRange.location+1];
            return [self compareBigOrEqualFirstNumberFirst:firstStr second:secStr];
        }
        else{
            if (secRange.location == NSNotFound && secRange.location == NSNotFound) {
                return YES;
            }
            else if (secRange.location == NSNotFound && firstRange.location != NSNotFound){
                return YES;
            }
            else if (secRange.location != NSNotFound && firstRange.location == NSNotFound){
                return NO;
            }
        }
    }
    
    return YES;
}
+ (NSString *)getFullXcodeVersionisSuccess:(BOOL*)isSuccess
{
    NSString *result= [self runTaskInDefaultShellWithCommandStr:@"xcodebuild -version" isSuccess:isSuccess];
    
    NSString *vStr=nil;
    
    if (*isSuccess) {
        for (NSString* line in [result componentsSeparatedByString:@"\n"]) {
            if ([line hasPrefix:@"Xcode "]) {
                NSRange range = [line rangeOfString:@"Xcode "];
                if (range.location != NSNotFound) {
                    vStr = [line substringFromIndex:range.length];
                }
            }
        }
    }
    else{
        vStr = [NSString stringWithFormat:@"%@\nWarning:找不到XCode,请检查XCode安装和设置!\n",result];
    }
    
    return vStr;
}
#pragma mark - android activity package
+ (NSDictionary*)apkPackageAndVersionTheAppPath:(NSString*)appPath customSDKPath:(NSString*)customSDKPath
{
    if (!customSDKPath || !appPath) {
        NSLog(@"failed:%@",NSStringFromSelector(_cmd));
        return nil;
    }
    
    NSString *aaptPath = [self pathToAndroidBinary:@"aapt" atSDKPath:customSDKPath];
    if(!aaptPath || aaptPath.length < 10) return nil;
    if ([[[aaptPath lastPathComponent] lowercaseString] isEqualToString:@"aapt"]) aaptPath = [aaptPath stringByDeletingLastPathComponent];
    
    // get the xml dump from aapt
    NSString *commandStr = [NSString stringWithFormat:@"./aapt dump xmltree '%@' AndroidManifest.xml",appPath];
    
    BOOL isAaptSuccess = NO;
    NSString *aaptString = [self runTaskInDefaultShellWithCommandStr:commandStr isSuccess:&isAaptSuccess path:aaptPath];
    
    NSArray *aaptLines = [aaptString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    
    NSString *ver;
    NSString *appID;
    
    NSString *pattern = @"=";
    NSString *contentPattern = @"\"";
    
    for (int i=0; i < aaptLines.count; i++)
    {
        NSString *line = [((NSString*)[aaptLines objectAtIndex:i]) stringByTrimmingLeadingWhitespace];
        
        // determine when an activity element has started or ended
        if ([line hasPrefix:@"A: android:versionName"])
        {
            NSRange range = [line rangeOfString:pattern];
            if (range.location != NSNotFound) {
                NSRange bgRange = [line rangeOfString:contentPattern options:0 range:NSMakeRange(range.location+1, line.length-range.location-1)];
                if (bgRange.location != NSNotFound) {
                    NSRange endRange = [line rangeOfString:contentPattern options:0 range:NSMakeRange(bgRange.location+1, line.length-bgRange.location-1)];
                    if (bgRange.location != NSNotFound && endRange.location != NSNotFound) {
                        ver = [line substringWithRange:NSMakeRange(bgRange.location+1, endRange.location-bgRange.location-1)];
                    }
                }
            }
        }
        if ([line hasPrefix:@"A: package="])
        {
            NSRange range = [line rangeOfString:pattern];
            if (range.location != NSNotFound) {
                NSRange bgRange = [line rangeOfString:contentPattern options:0 range:NSMakeRange(range.location+1, line.length-range.location-1)];
                if (bgRange.location != NSNotFound) {
                    NSRange endRange = [line rangeOfString:contentPattern options:0 range:NSMakeRange(bgRange.location+1, line.length-bgRange.location-1)];
                    if (bgRange.location != NSNotFound && endRange.location != NSNotFound) {
                        appID = [line substringWithRange:NSMakeRange(bgRange.location+1, endRange.location-bgRange.location-1)];
                    }
                }
            }
        }
        
    }
    
    if (ver && appID) {
        return @{@"ver":ver,@"appID":appID};
    }
    
    return nil;
}
+ (void)refreshAndroidActivity:(NSMutableArray**)activityArr package:(NSMutableArray**)packageArr app:(NSString*)appPath customSDKPath:(NSString*)customSDKPath
{
    if (!customSDKPath || !appPath || !activityArr || !packageArr) {
        //NSLog(@"failed:%@",NSStringFromSelector(_cmd));
        return;
    }
    
    NSString *aaptPath = [self pathToAndroidBinary:@"aapt" atSDKPath:customSDKPath];
    if(!aaptPath || aaptPath.length < 10) return;
    if ([[[aaptPath lastPathComponent] lowercaseString] isEqualToString:@"aapt"]) aaptPath = [aaptPath stringByDeletingLastPathComponent];
    
    // get the xml dump from aapt
    NSString *commandStr = [NSString stringWithFormat:@"./aapt dump xmltree '%@' AndroidManifest.xml",appPath];
    
    BOOL isAaptSuccess = NO;
    NSString *aaptString = [self runTaskInDefaultShellWithCommandStr:commandStr isSuccess:&isAaptSuccess path:aaptPath];
    //       NSLog(@"==aaptPath:%@",aaptPath);
    
    // read line by line
    NSArray *aaptLines = [aaptString componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    NSMutableArray *activities = [NSMutableArray new];
    NSMutableArray *packages = [NSMutableArray new];
    BOOL currentElementIsActivity = NO;
    
    for (int i=0; i < aaptLines.count; i++)
    {
        NSString *line = [((NSString*)[aaptLines objectAtIndex:i]) stringByTrimmingLeadingWhitespace];
        
        // determine when an activity element has started or ended
        if ([line hasPrefix:@"E:"])
        {
            currentElementIsActivity = [line hasPrefix:@"E: activity (line="];
        }
        
        // determine when the activity name has appeared
        if (currentElementIsActivity && [line hasPrefix:@"A: android:name("])
        {
            NSArray *lineComponents = [line componentsSeparatedByString:@"\""];
            if (lineComponents.count >= 3)
            {
                [activities addObject:(NSString*)[lineComponents objectAtIndex:1]];
            }
        }
        
        // detect packages
        if ([line hasPrefix:@"A: package="])
        {
            NSArray *lineComponents = [line componentsSeparatedByString:@"\""];
            if (lineComponents.count >= 3)
            {
                [packages addObject:(NSString*)[lineComponents objectAtIndex:1]];
            }
        }
    }
    
    NSString *activityCommand = [NSString stringWithFormat:@"./aapt dump badging '%@'",appPath];
    BOOL isActivitySuccess = NO;
    NSString *activityStr = [self runTaskInDefaultShellWithCommandStr:activityCommand isSuccess:&isActivitySuccess path:aaptPath];
    NSString *packageStr = [[NSString alloc]initWithString:activityStr];
    
    if (isActivitySuccess && activityStr) {
        NSString *pattern = @"launchable-activity: name='[a-zA-Z0-9.]{1,200}'";
        NSRegularExpression *reg = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
        NSTextCheckingResult *match = [reg firstMatchInString:activityStr options:0 range:NSMakeRange(0, activityStr.length)];
        if (match) {
            NSString *result = [activityStr substringWithRange:match.range];
            //                NSLog(@"app:%@\n,result:%@",self.appPath.lastPathComponent,result);
            NSRange range = [result rangeOfString:@"'"];
            if (range.location != NSNotFound) {
                NSString *activity = [result substringWithRange:NSMakeRange(range.location+1, result.length-range.location-2)];
                //                    NSLog(@"activity:%@",activity);
                if (![activities containsObject:activity]) {
                    [activities insertObject:activity atIndex:0];
                }
                else {
                    if ([activities indexOfObject:activity] != 0)
                        [activities exchangeObjectAtIndex:0 withObjectAtIndex:[activities indexOfObject:activity]];
                }
                
            }
        }
        
        NSString *packagePattern = @"package: name='[a-zA-Z0-9.]{1,200}'";
        NSRegularExpression *packageReg = [NSRegularExpression regularExpressionWithPattern:packagePattern options:0 error:nil];
        NSTextCheckingResult *packageMatch = [packageReg firstMatchInString:activityStr options:0 range:NSMakeRange(0, packageStr.length)];
        if (packageMatch) {
            NSString *packageResult = [packageStr substringWithRange:packageMatch.range];
            //                NSLog(@"app:%@\n,result:%@",self.appPath.lastPathComponent,packageResult);
            NSRange range2 = [packageResult rangeOfString:@"'"];
            if (range2.location != NSNotFound) {
                NSString *package = [packageResult substringWithRange:NSMakeRange(range2.location+1, packageResult.length-range2.location-2)];
                //                    NSLog(@"package:%@",package);
                if (![packages containsObject:package]) [packages insertObject:package atIndex:0];
                else{
                    if([packages indexOfObject:package] != 0) [packages exchangeObjectAtIndex:0 withObjectAtIndex:[packages indexOfObject:package]];
                }
                
            }
        }
    }
    
    if(activities.count>0) [*activityArr addObjectsFromArray:activities];
    if(packages.count>0) [*packageArr addObjectsFromArray:packages];
    
    //    NSString *packageCommand = [NSString stringWithFormat:@"adb dump badging %@"];
    //    NSString *packageStr = [Utility runTaskWithBinary:androidBinaryPath arguments:[NSArray arrayWithObjects:@"dump", @"badging",appPath, nil]];
    
    //    if (packageStr) {
    //        NSString *packagePattern = @"package: name='[a-zA-Z0-9.]{1,200}'";
    //        NSRegularExpression *packageReg = [NSRegularExpression regularExpressionWithPattern:packagePattern options:0 error:nil];
    //        NSTextCheckingResult *packageMatch = [packageReg firstMatchInString:activityStr options:0 range:NSMakeRange(0, packageStr.length)];
    //        if (packageMatch) {
    //            NSString *packageResult = [packageStr substringWithRange:packageMatch.range];
    //            //                NSLog(@"app:%@\n,result:%@",self.appPath.lastPathComponent,packageResult);
    //            NSRange range2 = [packageResult rangeOfString:@"'"];
    //            if (range2.location != NSNotFound) {
    //                NSString *package = [packageResult substringWithRange:NSMakeRange(range2.location+1, packageResult.length-range2.location-2)];
    //                //                    NSLog(@"package:%@",package);
    //                if (![packages containsObject:package]) [packages insertObject:package atIndex:0];
    //                else{
    //                    if([packages indexOfObject:package] != 0) [packages exchangeObjectAtIndex:0 withObjectAtIndex:[packages indexOfObject:package]];
    //                }
    //
    //            }
    //        }
    //    }
    
}
#pragma mark - get testwa user client info
+ (NSDictionary*)testwaClientInfo
{
    NSDictionary *dict = [[NSBundle mainBundle] infoDictionary];
    NSString *appName = [dict objectForKey:@"CFBundleName"];
    NSString *appShortVersion = [dict objectForKey:@"CFBundleShortVersionString"];
    NSString *appVersion = [dict objectForKey:@"CFBundleVersion"];
    
    NSMutableDictionary *dictM = [NSMutableDictionary dictionary];
    
    NSDictionary *hwDict = [self hwDict];
    NSDictionary *swDict = [self machineInfoWithCommandStr:@"system_profiler SPSoftwareDataType"];
    [dictM setValuesForKeysWithDictionary:hwDict];
    [dictM setValuesForKeysWithDictionary:swDict];
    [dictM setObject:appName forKey:@"BundleName"];
    [dictM setObject:appVersion forKey:@"BundleVersion"];
    [dictM setObject:appShortVersion forKey:@"BundleShortVersion"];
    [dictM setObject:[NSDate date] forKey:@"ClientGetInfoTime"];
    
    return dictM;
}
+ (NSDictionary*)hwDict
{
    return [self machineInfoWithCommandStr:@"system_profiler SPHardwareDataType"];
}
+ (NSDictionary*)machineInfoWithCommandStr:(NSString*)commandStr
{
    BOOL isSuccess = NO;
    NSString *hw = [self runTaskInDefaultShellWithCommandStr:commandStr isSuccess:&isSuccess];
    
    hw = [hw componentsSeparatedByString:@"Overview:"][1];
    NSArray *hwArr = [hw componentsSeparatedByString:@"\n"];
    NSMutableDictionary *hwDict = [NSMutableDictionary new];
    
    if (!isSuccess) return hwDict;
    
    for (NSString *str in hwArr) {
        NSString *line = [str stringByTrimmingLeadingWhitespace];
        NSRange range = [line rangeOfString:@": "];
        if (range.location != NSNotFound) {
            NSString *key = [line substringToIndex:range.location];
            NSString *value = [line substringFromIndex:range.location+range.length];
            [hwDict setValue:value forKey:key];
        }
    }
    
    return hwDict;
}
#pragma mark - angle
+ (float)angleOfStartPoint:(NSPoint)startPoint endPoint:(NSPoint)endPoint
{
    int x = startPoint.x;
    int y = startPoint.y;
    float dx = endPoint.x - x;
    float dy = endPoint.y - y;
    CGFloat radians = atan2(dy,dx); // in radians
    CGFloat degrees = radians * 180 / M_PI; // in degrees
    
    if (degrees < 0) return fabs(degrees);
    else return 360 - degrees;
}

+ (NSString*)directionForAngle:(float)angle
{
    if (angle >= 0 && angle < 45) {
        return @"left";
    } else if (angle >= 45 && angle < 135) {
        return @"down";
    } else if (angle >= 135 && angle < 225) {
        return @"right";
    } else if (angle >= 225 && angle < 315) {
        return @"up";
    } else if (angle >= 315 && angle < 360) {
        return @"left";
    } else {
        return @"left";
    }
}
+ (NSString*)directionString:(NSString*)direction
{
    if ([direction isEqualToString:@"up"]) {
        return @"向上";
    }
    else if ([direction isEqualToString:@"down"]) {
        return @"向下";
    }
    else if ([direction isEqualToString:@"right"]) {
        return @"向右";
    }
    else if ([direction isEqualToString:@"left"]) {
        return @"向左";
    }
    
    return direction;
}
#pragma mark - pipe
-(void)normalLoop:(TaskMsgBlock)taskNormalBlock
{
    while (self.task.isRunning) {
        NSFileHandle *serverStdErr = [self.task.standardOutput fileHandleForReading];
        NSData *data = [serverStdErr availableData];
        NSString *string = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
        taskNormalBlock(string);
    }
}
-(void)errorLoop:(TaskMsgBlock)taskErrorBlock
{
    while (self.task.isRunning) {
        NSFileHandle *serverStdErr = [self.task.standardError fileHandleForReading];
        NSData *data = [serverStdErr availableData];
        NSString *string = [[NSString alloc] initWithData:data encoding: NSUTF8StringEncoding];
        taskErrorBlock(string);
    }
}
-(void)exitTask:(TaskFinishBlock)taskExitBlock
{
    taskExitBlock();
}
- (void)runDefaultShellInBGWithCommandStr:(NSString*)commandStr Msgblock:(TaskMsgBlock)msgBlock finishBlock:(TaskFinishBlock)finishBlock
{
    self.task = [NSTask new];
    NSString *homeDir = NSHomeDirectory();
    if ([[NSFileManager defaultManager]fileExistsAtPath:homeDir]) {
        [self.task setCurrentDirectoryPath:NSHomeDirectory()];
    }
    
    [self.task setLaunchPath:@"/bin/bash"];
    [self.task setArguments:@[@"-l",@"-c",commandStr]];
    [self.task setStandardInput:[NSPipe pipe]];
    NSPipe *pipe = [NSPipe pipe];
    
    [self.task setStandardError:pipe];
    [self.task setStandardOutput:pipe];
    
    [self.task launch];
    
    [self performSelectorInBackground:@selector(normalLoop:) withObject:msgBlock];
    [self performSelectorInBackground:@selector(errorLoop:) withObject:msgBlock];
    [self performSelectorInBackground:@selector(exitTask:) withObject:finishBlock];
}
#pragma mark - certificate
+ (NSDictionary*)runSecurityCheckInDefaultShellWithProfilePath:(NSString*)profilePath
{
    NSDictionary *dict = nil;
    NSString *tempPath = @"/tmp/testwaSecTemp.plist";
    if ([[NSFileManager defaultManager] fileExistsAtPath:tempPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:tempPath error:nil];
    }
    [Utility runTaskWithBinary:@"/usr/bin/security" arguments:@[@"cms",@"-i",profilePath,@"-D",@"-o",tempPath]];
    
    if([[NSFileManager defaultManager] fileExistsAtPath:tempPath])
    {
        dict = [NSDictionary dictionaryWithContentsOfFile:tempPath];
    }
    
    return dict;
}
+ (void)openFileInDefaultShellWithFilePath:(NSString*)FilePath
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:FilePath]) {
        BOOL isSuccess;
        NSString *commandStr = [NSString stringWithFormat:@"open %@",FilePath];
        [Utility runTaskInDefaultShellWithCommandStr:commandStr isSuccess:&isSuccess];
    }
}
+ (NSArray*)schemesWithPrjPath:(NSString*)PrjPath
{
    if ([[NSFileManager defaultManager] fileExistsAtPath:PrjPath]) {
        NSString *commandStr = [NSString stringWithFormat:@"cd %@;xcodebuild -list -json",[PrjPath stringByDeletingLastPathComponent]];
        NSString *result = [Utility runTaskWithBinary:@"/bin/bash" arguments:@[@"-l",@"-c",commandStr]];
        if (result) {
            NSError *error;
            NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:[result dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingAllowFragments error:&error];
            if (error) {
                NSString *errStr = [error localizedDescription];
            }
            else{
                NSDictionary *prjDict = dict[@"project"];
                if (prjDict && [prjDict isKindOfClass:[NSDictionary class]]) {
                    NSArray* schemes = prjDict[@"schemes"];
                    return schemes;
                }
            }
        }
    }
    
    return nil;
}
/*
 xcodebuild clean -project ./weibo_webView.xcodeproj
 xcodebuild -project weibo_webView.xcodeproj -scheme weibo_webView -archivePath build/weibo_webView-adhoc.xcarchive clean archive build CODE_SIGN_IDENTITY="iPhone Distribution" PROVISIONING_PROFILE="d1137b63-a9ca-456a-a398-9fa433bd469a" DEVELOPMENT_TEAM="359TERPD84"
 xcodebuild -exportArchive -archivePath build/weibo_webView-adhoc.xcarchive -exportOptionsPlist ADHOCExportOptionsPlist.plist -exportPath exportPath/weibo_webView-adhoc
 */
+(NSString*)xcodebuildCleanPrj:(NSString*)prjPath
{
    NSString *result;
    if ([[NSFileManager defaultManager] fileExistsAtPath:prjPath]) {
        NSString *commandStr = [NSString stringWithFormat:@"cd %@;xcodebuild clean -project ./%@",[prjPath stringByDeletingLastPathComponent],[prjPath lastPathComponent]];
        result = [Utility runTaskWithBinary:@"/bin/bash" arguments:@[@"-l",@"-c",commandStr]];
    }
    return result;
}
-(NSString*)xcodebuildPrj:(NSString*)prjPath scheme:(NSString*)scheme ppuuid:(NSString*)ppuuid teamID:(NSString*)teamID taskmsgBlock:(TaskMsgBlock)msgblock taskFinishBlock:(TaskFinishBlock)finishBlock
{
    if (!prjPath || ![[NSFileManager defaultManager] fileExistsAtPath:prjPath]) {
        return @"项目出错：该项目不存在或者项目路径不对。\n";
    }
    if (!scheme) {
        return @"项目出错：无法读取项目中scheme信息。\n";
    }
    if (!ppuuid) {
        return @"ProvisioningProfile出错：对应的ppuuid找不到。\n";
    }
    if (!teamID) {
        return @"开发者账号出错：没有获取到账号信息。\n";
    }
    
    NSString *result;
    if ([[NSFileManager defaultManager] fileExistsAtPath:prjPath]) {
        NSString *commandStr = [NSString stringWithFormat:@"cd %@;xcodebuild -project %@ -scheme %@ -archivePath build/%@-adhoc.xcarchive clean archive build CODE_SIGN_IDENTITY=\"iPhone Distribution\" PROVISIONING_PROFILE=\"%@\" DEVELOPMENT_TEAM=\"%@\"",[prjPath stringByDeletingLastPathComponent],[prjPath lastPathComponent],scheme,scheme,ppuuid,teamID];
        //result = [Utility runTaskWithBinary:@"/bin/bash" arguments:@[@"-l",@"-c",commandStr]];
        
        [self runDefaultShellInBGWithCommandStr:commandStr Msgblock:msgblock finishBlock:finishBlock];
    }
    return result;
}
-(NSString*)xcodebuildArchivePrj:(NSString*)prjPath scheme:(NSString*)scheme ppuuid:(NSString*)ppuuid teamID:(NSString*)teamID taskmsgBlock:(TaskMsgBlock)msgblock taskFinishBlock:(TaskFinishBlock)finishBlock
{
    if (!prjPath || ![[NSFileManager defaultManager] fileExistsAtPath:prjPath]) {
        return @"项目出错：该项目不存在或者项目路径不对。\n";
    }
    if (!scheme) {
        return @"项目出错：无法读取项目中scheme信息。\n";
    }
    if (!ppuuid) {
        return @"ProvisioningProfile出错：对应的ppuuid找不到。\n";
    }
    if (!teamID) {
        return @"开发者账号出错：没有获取到账号信息。\n";
    }
    
    NSString *result;
    NSString *plistName = @"ADHOCExportOptionsPlist.plist";
    if ([[NSFileManager defaultManager] fileExistsAtPath:prjPath] && [Utility generateADHocOptPlistPrjPath:prjPath scheme:scheme ppuuid:ppuuid plistFileName:plistName teamID:teamID]) {
        NSString *commandStr = [NSString stringWithFormat:@"cd %@;xcodebuild -exportArchive -archivePath build/%@-adhoc.xcarchive -exportOptionsPlist %@  -exportPath exportPath/%@-adhoc",[prjPath stringByDeletingLastPathComponent],scheme,plistName,scheme];
        //        result = [Utility runTaskWithBinary:@"/bin/bash" arguments:@[@"-l",@"-c",commandStr]];
        [self runDefaultShellInBGWithCommandStr:commandStr Msgblock:msgblock finishBlock:finishBlock];
    }
    return result;
}
+(BOOL)generateADHocOptPlistPrjPath:(NSString*)prjPath scheme:(NSString*)scheme ppuuid:(NSString*)ppuuid plistFileName:(NSString*)plistName teamID:(NSString*)teamID
{
    if (!prjPath || ![[NSFileManager defaultManager] fileExistsAtPath:prjPath]) {
        return NO;
    }
    
    NSString *infoPath = [NSString stringWithFormat:@"%@/build/%@-adhoc.xcarchive/info.plist",[prjPath stringByDeletingLastPathComponent],scheme];
    NSString *bundleID;
    if ([[NSFileManager defaultManager] fileExistsAtPath:infoPath]) {
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:infoPath];
        dict = dict[@"ApplicationProperties"];
        bundleID = dict[@"CFBundleIdentifier"];
        if (!bundleID) {
            return NO;
        }
    }
    
    NSString *plistString = [NSString stringWithFormat:@"<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n\
<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n\
<plist version=\"1.0\">\n\
<dict>\n\
\t<key>compileBitcode</key>\n\
\t<true/>\n\
\t<key>method</key>\n\
\t<string>ad-hoc</string>\n\
\t<key>provisioningProfiles</key>\n\
\t<dict>\n\
\t\t<key>%@</key>\n\
\t\t<string>%@</string>\n\
\t</dict>\n\
\t<key>signingCertificate</key>\n\
\t<string>iPhone Distribution</string>\n\
\t<key>signingStyle</key>\n\
\t<string>manual</string>\n\
\t<key>stripSwiftSymbols</key>\n\
\t<true/>\n\
\t<key>teamID</key>\n\
\t<string>%@</string>\n\
</dict>\n\
</plist>",bundleID,ppuuid,teamID];
    NSString *file = [NSString stringWithFormat:@"%@/%@",[prjPath stringByDeletingLastPathComponent],plistName];
    NSError *error = nil;
    if ([[NSFileManager defaultManager] fileExistsAtPath:file]) {
        [[NSFileManager defaultManager] removeItemAtPath:file error:&error];
    }
    [plistString writeToFile:file atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    if (!error) {
        return YES;
    }
    
    return NO;
}
@end
