//
//  LXLicenseTool.m
//
//  Created by xin liu on 15/3/21.
//  Copyright (c) 2015年 TestWA. All rights reserved.
//

#import "LXLicenseTool.h"
//#import "keyChain.h"
//#import "TestAGlobal.h"

#define TestWALicenseValue_EndDate @"2016-12-28 23:59:59 +0800"

@implementation LXLicenseTool
+ (BOOL)validateLicense
{
    return [self validateLicenseEndDate:TestWALicenseValue_EndDate];
}
+ (BOOL)validateLicenseEndDate:(NSString*)endDate
{
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
    NSString *urlString = @"http://www.baidu.com";

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
@end
