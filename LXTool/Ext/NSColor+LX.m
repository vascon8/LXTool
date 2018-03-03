//
//  NSColor+LX.m
//  TestWa
//
//  Created by xin liu on 2018/2/8.
//  Copyright © 2018年 ___xin.liu___. All rights reserved.
//

#import "NSColor+LX.h"

@implementation NSColor (LX)
+ (NSColor*)testwaMainColor
{
    NSColor *color = [NSColor colorWithRed:1.0 green:1.0 blue:244.0/255.0 alpha:1.0];
    return color;
}
+ (NSColor *)toolbarColor
{
    NSColor *color = [NSColor colorWithRed:240.0/255.0 green:1.0 blue:240.0/255.0 alpha:0.9];
    return color;
}
+ (NSColor *)toolbarBorderHightlightColor
{
    NSColor *color = [NSColor colorWithRed:0 green:117.0/255.0 blue:15.0/255.0 alpha:1.0];
    return color;
}
+ (NSColor *)buttonHightlightColor
{
    NSColor *color = [NSColor colorWithRed:196.0/255.0 green:238.0/255.0 blue:191.0/255.0 alpha:1.0];
    return color;
}
@end
