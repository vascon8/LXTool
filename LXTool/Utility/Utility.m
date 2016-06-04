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
    NSLog(@"defP:%@",defaultPath);
    
    NSString *adbPath = [self pathToAndroidBinary:@"adb" atSDKPath:defaultPath];
    if (adbPath) {
        NSLog(@"==successful===");
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
    
    NSLog(@"androidHome:%@",androidHomePath);
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
    NSLog(@"getAndroid:%@\n,binary:%@",sdkPath,androidBinaryPath);
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
    NSLog(@"getAndroid:%@\n,binary:%@",sdkPath,androidBinaryPath);
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
        NSLog(@"can't be nil:%@",NSStringFromSelector(_cmd));
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
        NSLog(@"can't be nil:%@",NSStringFromSelector(_cmd));
        return @"failed";
    }
    
    NSString *commandStr = [NSString stringWithFormat:@"./adb -s '%@' pull '%@' '%@'",udid,apkPath,savePath];
    //        NSLog(@"==commandS:%@",commandStr);
    
    if ([[[androidBinaryPath lastPathComponent] lowercaseString] isEqualToString:@"adb"]) androidBinaryPath = [androidBinaryPath stringByDeletingLastPathComponent];
    
    NSString *result = [self runTaskInDefaultShellWithCommandStr:commandStr isSuccess:isDownloadSuccess path:androidBinaryPath];
    
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
    
    if ([packageStr hasPrefix:@"com.android."] || [packageStr hasPrefix:@"com.sec."] || [packageStr hasPrefix:@"com.samsung.android."] || [packageStr hasPrefix:@"com.samsung.sec."] || [packageStr hasPrefix:@"com.sec."])
        isSystemDefaultPackage = YES;
    
    return isSystemDefaultPackage;
}
#pragma mark - run method
+(NSString*)runTaskWithBinary:(NSString*)binary arguments:(NSArray*)args path:(NSString*)path
{
    NSTask *task = [NSTask new];
    if (path != nil)
    {
        [task setCurrentDirectoryPath:path];
    }
    
    static dispatch_once_t onceToken;
    static int i=0;
    i++;
    if(i>=80)
        dispatch_once(&onceToken, ^{
            //        NSLog(@"==invalidate== onceToken");
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
    NSString *pattern = @"[a-zA-Z0-9]{40}";
    
    NSRegularExpression *regular = [NSRegularExpression regularExpressionWithPattern:pattern options:0 error:nil];
    
    for (NSString* line in [deviceListString componentsSeparatedByString:@"\n"]) {
        //xcode 5,6 has simulator,while xcode 7 no
        //        NSRange realDeviceRange = [[line lowercaseString] rangeOfString:@"simulator"];
        //        if (realDeviceRange.location == NSNotFound) {
        if(!line || line.length<2) continue;
        
        NSTextCheckingResult *match = [regular firstMatchInString:line options:0 range:NSMakeRange(0, line.length)];
        if (match) {
            NSString *udid = [line substringWithRange:match.range];
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
    NSString *bundleString = [NSString stringWithFormat:@"ideviceinstaller -l -o list_user --udid %@",udid];
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
    
    //     NSLog(@"bundles:%@,dict:%@",bundles,bundleDict);
    
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
#pragma mark - android activity package
+ (void)refreshAndroidActivity:(NSMutableArray**)activityArr package:(NSMutableArray**)packageArr app:(NSString*)appPath customSDKPath:(NSString*)customSDKPath
{
    if (!customSDKPath || !appPath || !activityArr || !packageArr) {
        NSLog(@"failed:%@",NSStringFromSelector(_cmd));
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
    
    NSDictionary *hwDict = [self machineInfoWithCommandStr:@"system_profiler SPHardwareDataType"];
    NSDictionary *swDict = [self machineInfoWithCommandStr:@"system_profiler SPSoftwareDataType"];
    [dictM setValuesForKeysWithDictionary:hwDict];
    [dictM setValuesForKeysWithDictionary:swDict];
    [dictM setObject:appName forKey:@"BundleName"];
    [dictM setObject:appVersion forKey:@"BundleVersion"];
    [dictM setObject:appShortVersion forKey:@"BundleShortVersion"];
    [dictM setObject:[NSDate date] forKey:@"ClientGetInfoTime"];
    
    return dictM;
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
@end
