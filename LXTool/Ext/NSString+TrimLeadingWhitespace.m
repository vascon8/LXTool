//
//  NSString+RemoveLeadingWhitespace.m
//
//

#import "NSString+TrimLeadingWhitespace.h"

@implementation NSString (trimLeadingWhitespace)
-(NSString*)stringByTrimmingLeadingWhitespace {
    NSInteger i = 0;

    while ((i < [self length])
           && [[NSCharacterSet whitespaceCharacterSet] characterIsMember:[self characterAtIndex:i]]) {
        i++;
    }
    return [self substringFromIndex:i];
}
-(NSString*)stringByTrimmingRightWhitespace {
    NSInteger i = self.length-1;
//    NSLog(@"len:%ld,i:%ld",self.length,i);
    while ((i >= 0)
           && [[NSCharacterSet whitespaceCharacterSet] characterIsMember:[self characterAtIndex:i]]) {
        i--;
    }
//    NSLog(@"i:%ld",i);
    return [self substringToIndex:i+1];
}
@end