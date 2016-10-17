//
//  TestAElementTypeTransformer.h
//  TestWa
//
//  Created by xin liu on 16/10/5.
//  Copyright © 2016年 ___xin.liu___. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TestWaAgentGeneral.h"

@interface TestAElementTypeTransformer : NSObject

//XCUIELement -> XCUIELement String
+ (NSString *)xcuiElementStringWithXCUIElement:(NSNumber*)number;

//UIClass String -> XCUIELement String
+ (NSString *)xcuiElementStringWithUIAClassName:(NSString *)className;

//UIClass Short String -> XCUIELement String
+ (NSString *)xcuiElementStringWithUIShortString:(NSString*)shortString;

//UIClass String -> XCUIELement
+ (XCUIElementType)elementTypeWithUIAClassName:(NSString *)className;

//XCUIElementType -> UIClass String
+ (NSString *)UIAClassNameWithElementType:(XCUIElementType)elementType;

//XCUIElementType String -> XCUIElementType
+ (XCUIElementType)elementTypeWithTypeName:(NSString *)typeName;

//XCUIElementType -> XCUIElementType String
+ (NSString *)stringWithElementType:(XCUIElementType)type;

@end
