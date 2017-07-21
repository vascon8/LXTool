//
//  LXLicenseTool.m
//
//  Created by xin liu on 15/3/21.
//  Copyright (c) 2015年 TestWA. All rights reserved.
//

#import "LXLicenseTool.h"
//#import "keyChain.h"
//#import "TestAGlobal.h"

#import <CommonCrypto/CommonCrypto.h>
//#import "RSA.h"
//#import "NSData+Base64.h"

#import "CCMCryptor.h"
#import "CCMPrivateKey.h"
#import "CCMPublicKey.h"
#import "CCMKeyLoader.h"
#import "CCMBase64.h"

#import "AA3DESManager.h"

#import "Utility.h"
//#import "NSString+LXString.h"

#import "LXKeyChain.h"

#define TestWALicenseValue_EndDate @"2017-10-30 23:59:59 +0800"
#define TestWaLicenseDateFormatter @"yyyy-MM-dd HH:mm:ss Z"

#define TestWaFlag @"TestWaFlag"
#define TestWaExpire @"TestWaExpire"
#define TestWaAccount @"TestWa"

//-- 生成 RSA 私钥（传统格式的）
//openssl genrsa -out rsa_private_key.pem 1024
//-- 生成 RSA 公钥
//openssl rsa -in rsa_private_key.pem -pubout -out rsa_public_key.pem

#define TestWa_Private_Key_App @"MIICXAIBAAKBgQC7/UAnCCE+uI1v1IRCNlHK7b2kfaew4Mv1Mq96UDwe0SpyKiEIccbxEGtE0iiRpngIj6eUJUoJw/aYzdx+0zcPGL0oPdpVkXTWWyNgY+A6Jn/gqHmz9bsU4dZkMMyEMOXD9EdSo6hvNGIxSrqX35XxVzvbz8DxFltDH4jOgF7J9wIDAQABAoGAAJ9ZDAgJ3CROS5V/jpyRbsOUwiusV3iXFEvDqvsDB/MXWeNr0pRV3Ux5nnO3sKvFb/nRyzrIYPnmIiFkXoMihofQ3nmTk/ebkeefByLN93xBo9ZbwA3A7gk7cKVl2nDH78eUBlmey50tvdO6Qk00R3DeIormnfBo56EdoLElY3kCQQDo29jKstbGV8Km+cy72iCCgAMw+agp8ob/+fFFYr47evyOg0mxkDtuYNYDdYGFrpQmiXBGOL4q5A1phAK6eXnjAkEAzqvhNb8JyB7U8/JqkE7mpjYFlEzU7zHMN2tWzCa4O8FqxY3aLOi8punBXGdD0F7vTYK/QWF08+hqxjtKRTX73QJAeSZQj30mUwE768XRZ/bfrSXPAz8Q5+ofpLQ0fAYYtTeSiM7zm2dQFGhbUGdlYNjoiXg+KrrA7e3CsKAXD0++QwJBAMAz/0VxvlIbwmaA+3PrvPu03+l0rs8pG8gqjlVcaRhBn9/MNaxwYgpE+KvL6bheoeUPBHl0fkTb0Hk86KyHMQ0CQGClrtwlQlzfOQ1MSiLSMsN5UW6S/2o6D+8ds4+x5yD1EcIADeTKrkIvYwH8bYRw073k4WYpHWGlAlKe9wNNQCg="
#define TestWa_Public_Key_Reg @"MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCbP1eqJJLVTCJWAA4bot75/Knlj0+VXEt3pK4d/rQIyKHT38wRrZX6aARAirlr/YzcWyhr3mpF6oCA9MNsVUpi5JBCdaX5SEceERyo5BkcO16eFwI4By6iR+xBBVTD4Jo0ryajCQl8Eu5TVXcMC4fE5CWtcNYPhWmwsBCJ/PSu4wIDAQAB"
#define TestWa_Private_Key_Reg @"MIICXAIBAAKBgQCbP1eqJJLVTCJWAA4bot75/Knlj0+VXEt3pK4d/rQIyKHT38wRrZX6aARAirlr/YzcWyhr3mpF6oCA9MNsVUpi5JBCdaX5SEceERyo5BkcO16eFwI4By6iR+xBBVTD4Jo0ryajCQl8Eu5TVXcMC4fE5CWtcNYPhWmwsBCJ/PSu4wIDAQABAoGAGEfd5CR4Opf/vsefbT8Z9KtJvzec0NVwkDPXb6WIbt9CQCr+db1aeaGPGLEZswQi5cv0FHri0DCPDJw7fFQSoAqXNXP6lVXjrhss1etsd+qThumG8VlEsJEbZZqAFOsNecZnWfXcP/IlX8pSQfCjSV7L7NdMrWiewS4tyx9gCfECQQDH5TYl2DquHJdpnS5kT0e7eCcNLIlZvDa9q39fAOr2/By5Npgy2Th46EKmMAuIci80qibxrHtfE8JWG95RfCTFAkEAxtIb3en77jVqXExATK25WZoAoLDld/+JUOjsqQhisxxmSYciu6jAUek+soXiUbOuHAtLRiFRrqYCAkRcN9rPhwJBAJ3EZZk28RFsVYCw4uWewQHQUhoOtZUSfK30RkIoSkqHLvBri3JOiUi8H6ZksyWM4X8ScEw8Et82jCJEOpJbhfUCQEIESA6CgA2TnPJyuzL6yD2xPh4dPsR+jBjajqJ9z1AL0Qb/IRBQszM/kHr0q7ZXRCu5sE/kBlxIcQhRrJE7TYcCQFV1IEUzjTY4hSbrCA5S/7u3Da+Ui9CvN4msFdARQiCHsCBjnP0C6nlhfrun7vn+UpwnX/ca7JInoCfonaPUCjA="
#define TestWa_Public_Key_App @"MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC7/UAnCCE+uI1v1IRCNlHK7b2kfaew4Mv1Mq96UDwe0SpyKiEIccbxEGtE0iiRpngIj6eUJUoJw/aYzdx+0zcPGL0oPdpVkXTWWyNgY+A6Jn/gqHmz9bsU4dZkMMyEMOXD9EdSo6hvNGIxSrqX35XxVzvbz8DxFltDH4jOgF7J9wIDAQAB"

@implementation LXLicenseTool
#pragma mark - 3des
+ (NSString*)threeEncrypt:(NSString*)theString keyFlag:(NSString*)keyFlag ivFlag:(NSString*)ivFlag
{
    NSString *encrypptString = [AA3DESManager getEncryptWithString:theString keyString:keyFlag ivString:ivFlag];
    
    return encrypptString;
}
+ (NSString*)threeDecrypt:(NSString*)theString keyFlag:(NSString*)keyFlag ivFlag:(NSString*)ivFlag
{
    NSString *decryptString = [AA3DESManager getDecryptWithString:theString keyString:keyFlag ivString:ivFlag];
    
    return decryptString;
}
#pragma mark - signature
+ (NSString*)unsign:(NSString*)theString
{
    NSData *decryData = [CCMBase64 dataFromBase64String:theString];
    CCMPublicKey *pubKey = [self loadPublicKeyResource:@"public_key"];
    CCMCryptor *cryptor = [[CCMCryptor alloc]init];
    NSError *error;
    NSData *decry = [cryptor decryptData:decryData withPublicKey:pubKey error:&error];
    NSString *result = [[NSString alloc]initWithData:decry encoding:NSUTF8StringEncoding];
//    NSLog(@"result:%@",result);
    
    return result;
}
+ (NSString*)sign:(NSString*)theString
{
//    NSString *md5 = [self MD5Digest:@"xinliu"];
//    NSLog(@"md5:%@",md5);
    
    NSData *inputData = [theString dataUsingEncoding:NSUTF8StringEncoding];
    CCMPrivateKey *key = [self loadPrivateKeyResource:@"private_key"];
    NSError *error;
    CCMCryptor *cryptor = [[CCMCryptor alloc]init];
    NSData *encryptedData = [cryptor encryptData:inputData withPrivateKey:key error:&error];
    NSString *output = [CCMBase64 base64StringFromData:encryptedData];
    NSLog(@"outP:%@",output);
    
    return output;
}
#pragma mark  signature
+ (CCMPrivateKey *)loadPrivateKeyResource:(NSString *)name {
    NSString *pem = [self loadPEMResource:@"private_key"];
    CCMKeyLoader *keyLoader = [[CCMKeyLoader alloc] init];
    return [keyLoader loadRSAPEMPrivateKey:pem];
}
+ (CCMPublicKey *)loadPublicKeyResource:(NSString *)name {
    NSString *pem = [self loadPEMResource:@"public_key"];
    CCMKeyLoader *keyLoader = [[CCMKeyLoader alloc] init];
    return [keyLoader loadX509PEMPublicKey:pem];
}

+ (NSString *)loadPEMResource:(NSString *)name {
    
    NSString *str;
    
    if ([name isEqualToString:@"public_key"]) {
        str = @"MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQCbP1eqJJLVTCJWAA4bot75/Knlj0+VXEt3pK4d/rQIyKHT38wRrZX6aARAirlr/YzcWyhr3mpF6oCA9MNsVUpi5JBCdaX5SEceERyo5BkcO16eFwI4By6iR+xBBVTD4Jo0ryajCQl8Eu5TVXcMC4fE5CWtcNYPhWmwsBCJ/PSu4wIDAQAB";
    }
    else{
        str = @"MIICXAIBAAKBgQC7/UAnCCE+uI1v1IRCNlHK7b2kfaew4Mv1Mq96UDwe0SpyKiEIccbxEGtE0iiRpngIj6eUJUoJw/aYzdx+0zcPGL0oPdpVkXTWWyNgY+A6Jn/gqHmz9bsU4dZkMMyEMOXD9EdSo6hvNGIxSrqX35XxVzvbz8DxFltDH4jOgF7J9wIDAQABAoGAAJ9ZDAgJ3CROS5V/jpyRbsOUwiusV3iXFEvDqvsDB/MXWeNr0pRV3Ux5nnO3sKvFb/nRyzrIYPnmIiFkXoMihofQ3nmTk/ebkeefByLN93xBo9ZbwA3A7gk7cKVl2nDH78eUBlmey50tvdO6Qk00R3DeIormnfBo56EdoLElY3kCQQDo29jKstbGV8Km+cy72iCCgAMw+agp8ob/+fFFYr47evyOg0mxkDtuYNYDdYGFrpQmiXBGOL4q5A1phAK6eXnjAkEAzqvhNb8JyB7U8/JqkE7mpjYFlEzU7zHMN2tWzCa4O8FqxY3aLOi8punBXGdD0F7vTYK/QWF08+hqxjtKRTX73QJAeSZQj30mUwE768XRZ/bfrSXPAz8Q5+ofpLQ0fAYYtTeSiM7zm2dQFGhbUGdlYNjoiXg+KrrA7e3CsKAXD0++QwJBAMAz/0VxvlIbwmaA+3PrvPu03+l0rs8pG8gqjlVcaRhBn9/MNaxwYgpE+KvL6bheoeUPBHl0fkTb0Hk86KyHMQ0CQGClrtwlQlzfOQ1MSiLSMsN5UW6S/2o6D+8ds4+x5yD1EcIADeTKrkIvYwH8bYRw073k4WYpHWGlAlKe9wNNQCg=";
    }
    
    return str;
}
#pragma mark - read license file
+ (void)saveLicense:(NSString*)flag expire:(NSString*)expire
{
    [LXKeyChain setGenericPassword:flag forService:TestWaFlag account:TestWaAccount];
    [LXKeyChain setGenericPassword:expire forService:TestWaExpire account:TestWaAccount];
}
+ (BOOL)readLicenseFile:(NSString*)filePath
{
//    NSLog(@"fileP:%@",filePath);
    
    BOOL isSuccess = NO;
    
    if(!filePath) filePath = @"/tmp/request.twreq";
    
    if ([[NSFileManager defaultManager]fileExistsAtPath:filePath]) {
        NSData *data = [NSData dataWithContentsOfFile:filePath];
        NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:nil];
//        NSLog(@"dict:%@",dict);
        if ([dict isKindOfClass:[NSDictionary class]]) {
            NSString *content;
            NSString *keyFlag;
            NSString *ivFlag;
            if([dict.allKeys containsObject:@"Content"]) content = dict[@"Content"];
            if([dict.allKeys containsObject:@"Flag1"]) ivFlag = dict[@"Flag1"];
            if([dict.allKeys containsObject:@"Flag2"]) keyFlag = dict[@"Flag2"];
            if (content && ivFlag && keyFlag) {
                NSString *decrypt3Des = [self threeDecrypt:content keyFlag:keyFlag ivFlag:ivFlag];
                NSString *unsign = [self unsign:decrypt3Des];
                NSData *data = [unsign dataUsingEncoding:NSUTF8StringEncoding];
                NSError *error;
                NSDictionary *dict = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&error];
                if (!error) {
                    NSString *flag;
                    NSString *expire;
                    if([dict.allKeys containsObject:@"flag"]) flag = dict[@"flag"];
                    if([dict.allKeys containsObject:@"expire"]) expire = dict[@"expire"];
                    
                    NSString *md5 = [self getMd5];
                    if (md5 && expire && [md5 isEqualToString:flag]) {
                        isSuccess = [self validateLicenseEndDate:expire];
                    }
                    
                    if(isSuccess) [self saveLicense:flag expire:expire];
                }
            }
        }
    }
    
    return isSuccess;
}
#pragma mark - generate license file
+ (BOOL)createApplyFile:(NSString*)destPath customer:(NSString*)customer
{
    NSError *error ;
    if(!customer) customer = @"unknown";
    
    @try {
        NSString *applydate = [self dateStringFromeDate:[NSDate date] formatterStr:TestWaLicenseDateFormatter];
        NSDictionary *dict = @{@"flag":[self getMd5],@"applyDate":applydate,@"customer":customer,@"udid":[self getComputerUdid]};
        NSData *data = [NSJSONSerialization dataWithJSONObject:dict options:NSJSONWritingPrettyPrinted error:&error];
        NSString *str = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
        
        
        //sign
        NSString *signedStr = [self sign:str];
        
        //3des
        NSString *keyFlag = [self threeDesKeyFlag];
        NSString *ivFlag = [self threeDesIvFlag];
        NSString *finalStr = [self threeEncrypt:signedStr keyFlag:keyFlag ivFlag:ivFlag];
        
        //the file
        NSDictionary *finalDict = @{@"Content":finalStr,@"Flag1":ivFlag,@"Flag2":keyFlag};
        NSData *finalData = [NSJSONSerialization dataWithJSONObject:finalDict options:NSJSONWritingPrettyPrinted error:&error];
        NSString *result = [[NSString alloc]initWithData:finalData encoding:NSUTF8StringEncoding];
        
        if(!destPath) destPath = @"/tmp";
        NSString *ext = @"twreq";
        NSString *fileName = [self applyFileName:customer path:destPath ext:ext];
        fileName = [fileName stringByAppendingPathExtension:ext];
        NSString *finalPath = [destPath stringByAppendingPathComponent:fileName];
        
        [result writeToFile:finalPath  atomically:YES encoding:NSUTF8StringEncoding error:&error];
        
        if (!error) return YES;
        return NO;
    }
    @catch (NSException *exception) {
        return NO;
    }
}
+ (NSString*)applyFileName:(NSString*)name path:(NSString*)path ext:(NSString*)ext
{
    NSString *finalPath = [[path stringByAppendingPathComponent:name] stringByAppendingPathExtension:ext];
    
    int i=1;
    while ([[NSFileManager defaultManager]fileExistsAtPath:finalPath]) {
        name = [NSString stringWithFormat:@"%@_%d",name,++i];
        finalPath = [[path stringByAppendingPathComponent:name] stringByAppendingPathExtension:ext];
    }
    
    return name;
}
#pragma mark - old
+ (NSString*)expire
{
    NSString *expire = [LXKeyChain genericPasswordForService:TestWaExpire account:TestWaAccount];
    
    if (expire) {
        NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
        formatter.dateFormat = TestWaLicenseDateFormatter;
        formatter.timeZone = [NSTimeZone systemTimeZone];
        
        NSDate *date = [formatter dateFromString:expire];
        
        formatter.dateFormat = @"yyyy-MM-dd";
        
        return [formatter stringFromDate:date];
    }
    else return nil;
}
+ (BOOL)validateTestWaLicense
{
    BOOL isSuccess = NO;
    
    NSString *flag = [LXKeyChain genericPasswordForService:TestWaFlag account:TestWaAccount];
    NSString *expire = [LXKeyChain genericPasswordForService:TestWaExpire account:TestWaAccount];
    
    if (flag && expire && [flag isEqualToString:[self getMd5]]) {
        isSuccess = [self validateLicenseEndDate:expire];
    }
    
    if (!isSuccess) {
        if(flag) [LXKeyChain removeGenericPasswordForService:TestWaFlag account:TestWaAccount];
        if(expire) [LXKeyChain removeGenericPasswordForService:TestWaExpire account:TestWaAccount];
    }
    
    return isSuccess;
}
+ (BOOL)validateLicense
{
    return [self validateLicenseEndDate:TestWALicenseValue_EndDate];
}
+ (NSString*)dateStringFromeDate:(NSDate*)date formatterStr:(NSString*)formatterStr
{
    NSDateFormatter *myDate = [[NSDateFormatter alloc] init];
    [myDate setDateFormat:formatterStr];
    [myDate setLocale:[NSLocale systemLocale]];
    
    return [myDate stringFromDate:date];
}
+ (NSDate*)dateFromString:(NSString*)dateString formatter:(NSString*)formatterStr
{
    NSDateFormatter *myDate = [[NSDateFormatter alloc] init];
    [myDate setDateFormat:formatterStr];
    [myDate setLocale:[NSLocale systemLocale]];
    
    return [myDate dateFromString:formatterStr];
}
+ (BOOL)validateLicenseEndDate:(NSString*)endDate
{
    
//    [self createLicenseFile:nil];
//    [self readLicenseFile:nil];
    
    NSDate *expireDate;
    NSDate *currentDate = [self getInternetDate];
    
    NSDateFormatter *myDate = [[NSDateFormatter alloc] init];
    [myDate setDateFormat:@"yyyy-MM-dd HH:mm:ss Z"];
    [myDate setLocale:[NSLocale systemLocale]];
    if (endDate) {
        expireDate = [myDate dateFromString:endDate];
    }
    else{
        expireDate = [myDate dateFromString:TestWALicenseValue_EndDate];
    }
    
    if (!currentDate) {
        currentDate = [NSDate date];
    }
	
    NSInteger hour = [self getAllHour:expireDate endDate:currentDate];
	
//    NSLog(@"cur:%@,expire:%@,hour:%ld",currentDate,expireDate,hour);
    
	if (hour>0) {
        
//        NSString *msg = @"温馨提示：该版本已到期!";
//        NSString *info = @"请去testwa.com获取最新版本，即可免费体验更多新功能.";
//        NSAlert *alert = [NSAlert alertWithMessageText:msg defaultButton:@"获取最新版本" alternateButton:@"取消" otherButton:nil informativeTextWithFormat:info];
//        
//        NSModalResponse returnCode = [alert runModal];
//        
//        if (returnCode == 1) {
//            [[NSWorkspace sharedWorkspace]openURL:[NSURL URLWithString:TestWASyncCloudServer]];
//        }
        
		return NO;
	}
    return YES;
}

+(NSDate *)getInternetDate
{
    NSString *urlString = @"http://www.baidu.com2";

    NSString *date = [self dateWithUrl:urlString];
    if (!date) {
        urlString = @"http://www.sina.com";
        date = [self dateWithUrl:urlString];
    }

    NSDateFormatter *dMatter = [[NSDateFormatter alloc] init];

    dMatter.locale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US"];
    [dMatter setTimeZone:[NSTimeZone localTimeZone]];
    [dMatter setDateFormat:@"dd MM yyyy HH:mm:ss Z"];

    NSDate *netDate = [dMatter dateFromString:date];
//    NSLog(@"netDate:%@,str:%@",netDate,date);
    return netDate;

}
+ (NSString*)dateWithUrl:(NSString *)urlString
{
    urlString = [urlString stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    
    [request setURL:[NSURL URLWithString: urlString]];
    
    [request setCachePolicy:NSURLRequestReloadIgnoringCacheData];
    
    [request setTimeoutInterval:10];
    
    [request setHTTPShouldHandleCookies:FALSE];
    
    [request setHTTPMethod:@"GET"];
    
    
    
    NSHTTPURLResponse *response;
    
    [NSURLConnection sendSynchronousRequest:request
     
                          returningResponse:&response error:nil];
    
//        NSLog(@"response is %@",response);
    
    NSString *date = [[response allHeaderFields] objectForKey:@"Date"];
    
    date = [date substringFromIndex:5];
    
    date = [date substringToIndex:[date length]];
    
    return date;
}
#pragma mark - calculate hour
+ (NSInteger)getAllHour:(NSDate *)beginDate  endDate:(NSDate *)endDate{
    NSCalendar *calendarHour = [[NSCalendar alloc] initWithCalendarIdentifier:NSChineseCalendar];
    NSInteger uniteHour = NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit|NSDayCalendarUnit|NSMonthCalendarUnit|NSYearCalendarUnit;
    NSDateComponents *compHour = [calendarHour components:uniteHour fromDate:beginDate toDate:endDate options:0];
    return  [self getCalcuHour:[compHour year] day:[compHour day] hour:[compHour hour]];
}

+ (NSInteger)getCalcuHour:(NSInteger)year  day:(NSInteger)day hour:(NSInteger)hour{
    return year*365*24 + day*24 + hour;
}
/*
#pragma mark - 3des
+ (NSString *)desEncryptionString:(NSString*)string deskKey:(NSString*)Des3Key desIv:(NSString*)Des3Iv
{
    if (!string || [string isEqual:@""]) return nil;
    
    NSData* data = [string dataUsingEncoding:NSUTF8StringEncoding];
    size_t plainTextBufferSize = [data length];
    const void *vplainText = (const void *)[data bytes];
    
    CCCryptorStatus ccStatus;
    uint8_t *bufferPtr = NULL;
    size_t bufferPtrSize = 0;
    size_t movedBytes = 0;
    
    bufferPtrSize = (plainTextBufferSize + kCCBlockSize3DES) & ~(kCCBlockSize3DES - 1);
    bufferPtr = malloc( bufferPtrSize * sizeof(uint8_t));
    memset((void *)bufferPtr, 0x0, bufferPtrSize);
    
    const void *vkey = (const void *) [Des3Key UTF8String];
    const void *vinitVec = (const void *) [Des3Iv UTF8String];
    
    ccStatus = CCCrypt(kCCEncrypt,
                       kCCAlgorithm3DES,
                       kCCOptionPKCS7Padding,
                       vkey,
                       kCCKeySize3DES,
                       vinitVec,
                       vplainText,
                       plainTextBufferSize,
                       (void *)bufferPtr,
                       bufferPtrSize,
                       &movedBytes);
    
    NSData *myData = [NSData dataWithBytes:(const void *)bufferPtr length:(NSUInteger)movedBytes];
    NSLog(@"==decryData:%@",myData);
    NSString *result = [myData base64EncodedString];
    return result;
}

+ (NSString *)desDecryptionString:(NSString*)string deskKey:(NSString*)Des3Key desIv:(NSString*)Des3Iv
{
    if (!string || [string isEqual:@""]) return nil;
    
    NSData *encryptData = [NSData dataFromBase64String:string];
    size_t plainTextBufferSize = [encryptData length];
    const void *vplainText = [encryptData bytes];
    
    CCCryptorStatus ccStatus;
    uint8_t *bufferPtr = NULL;
    size_t bufferPtrSize = 0;
    size_t movedBytes = 0;
    bufferPtrSize = (plainTextBufferSize + kCCBlockSize3DES) & ~(kCCBlockSize3DES - 1);
    bufferPtr = malloc( bufferPtrSize * sizeof(uint8_t));
    memset((void *)bufferPtr, 0x0, bufferPtrSize);
    const void *vkey = (const void *) [Des3Iv UTF8String];
    const void *vinitVec = (const void *) [Des3Iv UTF8String];
    
    ccStatus = CCCrypt(kCCDecrypt,
                       kCCAlgorithm3DES,
                       kCCOptionPKCS7Padding,
                       vkey,
                       kCCKeySize3DES,
                       vinitVec,
                       vplainText,
                       plainTextBufferSize,
                       (void *)bufferPtr,
                       bufferPtrSize,
                       &movedBytes);
    
    NSString *result = [[NSString alloc] initWithData:[NSData dataWithBytes:(const void *)bufferPtr length:(NSUInteger)movedBytes] encoding:NSUTF8StringEncoding];
    return result;
}
#pragma mark - signature
+ (NSString*)signatureString:(NSString*)string
{
    NSString *pubK = @"-----BEGIN PUBLIC KEY-----\nMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDDI2bvVLVYrb4B0raZgFP60VXY\ncvRmk9q56QiTmEm9HXlSPq1zyhyPQHGti5FokYJMzNcKm0bwL1q6ioJuD4EFI56D\na+70XdRz1CjQPQE3yXrXXVvOsmq9LsdxTFWsVBTehdCmrapKZVVx6PKl7myh0cfX\nQmyveT/eqyZK1gYjvQIDAQAB\n-----END PUBLIC KEY-----";
    NSString *encrypted = [RSA encryptString:@"1234abc" publicKey:pubK];
    
    return encrypted;
}
+ (NSString*)unSignatureString:(NSString*)string
{
    NSString *decrypted = [RSA decryptString:string privateKey:TestWa_Private_Key_App];
    return decrypted;
}
*/
#pragma mark - md5
+ (NSString *)MD5Digest:(NSString*)string
{
    const char* input = [string UTF8String];
    unsigned char result[CC_MD5_DIGEST_LENGTH];
    CC_MD5(input, (CC_LONG)strlen(input), result);
    
    NSMutableString *digest = [NSMutableString stringWithCapacity:CC_MD5_DIGEST_LENGTH * 2];
    for (NSInteger i = 0; i < CC_MD5_DIGEST_LENGTH; i++) {
        [digest appendFormat:@"%02x", result[i]];
    }
    
    return digest;
}
#pragma mark - computer info
+ (BOOL)hwinfo:(NSString*)udid
{
    BOOL udidRight = NO;
    
    if(!udid || udid.length == 0) return NO;
    
    NSString *computerUdid = [self getComputerUdid];
    if (computerUdid && [computerUdid isEqualToString:udid]) {
        udidRight = YES;
    }
    
    return udidRight;
}
+(NSString*)getComputerUdid
{
    NSString *computerUuid;
    NSDictionary *dict = [Utility hwDict];
    if(dict[@"Hardware UUID"]) computerUuid = dict[@"Hardware UUID"];
    else computerUuid = @"No Udid found,maybe authorization problem";
    
    return computerUuid;
}
+(NSString*)getMd5
{
    NSString *computerUuid;
    NSDictionary *dict = [Utility hwDict];
    if(dict[@"Hardware UUID"]) computerUuid = dict[@"Hardware UUID"];
    else {
        computerUuid = @"No Udid found,maybe authorization problem";
        
        NSAlert *alert = [NSAlert new];
        [alert setMessageText:computerUuid];
        [alert setInformativeText:@"授权出错，无法获取系统信息，请确认当前用户的权限!"];
        
        [alert runModal];
    }
    
    NSString *digest = [NSString stringWithFormat:@"%@%@",[self randFlag:@"testwa"],computerUuid];
    
    return [self MD5Digest:computerUuid];
}

#pragma mark - 3des flag
#define ARC4RANDOM_MAX      0x100000000
#define MyFlag @"Testwa_By_XinLiu0821"
#define TestWaFlag @"www.testwa.com or www.testwa.cn"
//flag1:iv falg2:key
+ (double)randomF
{
    return (((double)arc4random() / ARC4RANDOM_MAX) * 10000092048.2f);
}
+ (NSString*)base64String:(NSString*)theStr
{
    return [CCMBase64 base64StringFromData:[theStr dataUsingEncoding:NSUTF8StringEncoding]];
}
+ (NSString*)randFlag:(NSString*)flag
{
    int rand = arc4random();
    if (rand%2 == 0) {
        flag = [NSString stringWithFormat:@"%@_%@_%@%d",flag,TestWaFlag,[self dateString],rand];
    }
    else flag = [NSString stringWithFormat:@"%d_%@%@_%@",rand,TestWaFlag,flag,[self timeString]];
//    NSLog(@"rand:%d",rand);
    
    return flag;
}
+(NSString*)threeDesKeyFlag{
    NSString *keyStr = [self timeString];
    double val = [self randomF];
    keyStr = [NSString stringWithFormat:@"key(%@%@)%f",keyStr,MyFlag,val];
    keyStr = [self randFlag:keyStr];
   
    keyStr = [self base64String:keyStr];
//    NSLog(@"keyStr:%@",keyStr);
    
    return keyStr;
}
+(NSString*)threeDesIvFlag{
    NSString *ivFlag = [self dateString];
    double val = [self randomF];
    ivFlag = [NSString stringWithFormat:@"iv%@_%@_%.10f",MyFlag,ivFlag,val];
    ivFlag = [self randFlag:ivFlag];
    
    ivFlag = [self base64String:ivFlag];
    
//    NSLog(@"ivFlag:%@",ivFlag);
    
    return ivFlag;
}
#pragma mark - nsstring
+ (NSString *)timeString
{
    return [self stringWithFormatterStr:@"yyyyMMddHHmmssSSSS"];
}
+ (NSString*)dateString
{
    return [self stringWithFormatterStr:@"yyyy/MM/dd HH:mm"];
}
+ (NSString*)dateStringWithFormatterStr:(NSString*)formatterStr
{
    return [self stringWithFormatterStr:formatterStr];
}
+ (NSString*)stringWithFormatterStr:(NSString*)formatterStr
{
    NSDateFormatter *formatter = [[NSDateFormatter alloc]init];
    formatter.dateFormat = formatterStr;
    formatter.timeZone = [NSTimeZone systemTimeZone];
    
    NSString *date = [formatter stringFromDate:[NSDate date]];
    
    return date;
}
@end
