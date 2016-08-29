//
//  LXLicenseTool.h
//
//  Created by xin liu on 15/3/21.
//  Copyright (c) 2015年 TestWA. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LXLicenseTool : NSObject
+ (BOOL)validateLicense;
+ (BOOL)validateLicenseEndDate:(NSString*)endDate;
+ (BOOL)validateTestWaLicense;

+ (BOOL)readLicenseFile:(NSString*)filePath;
+ (BOOL)createApplyFile:(NSString*)destPath customer:(NSString*)customer;
@end
