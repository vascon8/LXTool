//
//  TestAElementTypeTransformer.m
//  TestWa
//
//  Created by xin liu on 16/10/5.
//  Copyright © 2016年 ___xin.liu___. All rights reserved.
//

#import "TestAElementTypeTransformer.h"

@implementation TestAElementTypeTransformer

static NSDictionary *ElementTypeToStringMapping;
static NSDictionary *StringToElementTypeMapping;

static NSDictionary *UIAClassToElementTypeMapping;
static NSDictionary *ElementTypeToUIAClassMapping;

+ (void)createMapping
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        ElementTypeToStringMapping =
        @{
          @0 : @"XCUIElementTypeAny",
          @1 : @"XCUIElementTypeOther",
          @2 : @"XCUIElementTypeApplication",
          @3 : @"XCUIElementTypeGroup",
          @4 : @"XCUIElementTypeWindow",
          @5 : @"XCUIElementTypeSheet",
          @6 : @"XCUIElementTypeDrawer",
          @7 : @"XCUIElementTypeAlert",
          @8 : @"XCUIElementTypeDialog",
          @9 : @"XCUIElementTypeButton",
          @10 : @"XCUIElementTypeRadioButton",
          @11 : @"XCUIElementTypeRadioGroup",
          @12 : @"XCUIElementTypeCheckBox",
          @13 : @"XCUIElementTypeDisclosureTriangle",
          @14 : @"XCUIElementTypePopUpButton",
          @15 : @"XCUIElementTypeComboBox",
          @16 : @"XCUIElementTypeMenuButton",
          @17 : @"XCUIElementTypeToolbarButton",
          @18 : @"XCUIElementTypePopover",
          @19 : @"XCUIElementTypeKeyboard",
          @20 : @"XCUIElementTypeKey",
          @21 : @"XCUIElementTypeNavigationBar",
          @22 : @"XCUIElementTypeTabBar",
          @23 : @"XCUIElementTypeTabGroup",
          @24 : @"XCUIElementTypeToolbar",
          @25 : @"XCUIElementTypeStatusBar",
          @26 : @"XCUIElementTypeTable",
          @27 : @"XCUIElementTypeTableRow",
          @28 : @"XCUIElementTypeTableColumn",
          @29 : @"XCUIElementTypeOutline",
          @30 : @"XCUIElementTypeOutlineRow",
          @31 : @"XCUIElementTypeBrowser",
          @32 : @"XCUIElementTypeCollectionView",
          @33 : @"XCUIElementTypeSlider",
          @34 : @"XCUIElementTypePageIndicator",
          @35 : @"XCUIElementTypeProgressIndicator",
          @36 : @"XCUIElementTypeActivityIndicator",
          @37 : @"XCUIElementTypeSegmentedControl",
          @38 : @"XCUIElementTypePicker",
          @39 : @"XCUIElementTypePickerWheel",
          @40 : @"XCUIElementTypeSwitch",
          @41 : @"XCUIElementTypeToggle",
          @42 : @"XCUIElementTypeLink",
          @43 : @"XCUIElementTypeImage",
          @44 : @"XCUIElementTypeIcon",
          @45 : @"XCUIElementTypeSearchField",
          @46 : @"XCUIElementTypeScrollView",
          @47 : @"XCUIElementTypeScrollBar",
          @48 : @"XCUIElementTypeStaticText",
          @49 : @"XCUIElementTypeTextField",
          @50 : @"XCUIElementTypeSecureTextField",
          @51 : @"XCUIElementTypeDatePicker",
          @52 : @"XCUIElementTypeTextView",
          @53 : @"XCUIElementTypeMenu",
          @54 : @"XCUIElementTypeMenuItem",
          @55 : @"XCUIElementTypeMenuBar",
          @56 : @"XCUIElementTypeMenuBarItem",
          @57 : @"XCUIElementTypeMap",
          @58 : @"XCUIElementTypeWebView",
          @59 : @"XCUIElementTypeIncrementArrow",
          @60 : @"XCUIElementTypeDecrementArrow",
          @61 : @"XCUIElementTypeTimeline",
          @62 : @"XCUIElementTypeRatingIndicator",
          @63 : @"XCUIElementTypeValueIndicator",
          @64 : @"XCUIElementTypeSplitGroup",
          @65 : @"XCUIElementTypeSplitter",
          @66 : @"XCUIElementTypeRelevanceIndicator",
          @67 : @"XCUIElementTypeColorWell",
          @68 : @"XCUIElementTypeHelpTag",
          @69 : @"XCUIElementTypeMatte",
          @70 : @"XCUIElementTypeDockItem",
          @71 : @"XCUIElementTypeRuler",
          @72 : @"XCUIElementTypeRulerMarker",
          @73 : @"XCUIElementTypeGrid",
          @74 : @"XCUIElementTypeLevelIndicator",
          @75 : @"XCUIElementTypeCell",
          @76 : @"XCUIElementTypeLayoutArea",
          @77 : @"XCUIElementTypeLayoutItem",
          @78 : @"XCUIElementTypeHandle",
          @79 : @"XCUIElementTypeStepper",
          @80 : @"XCUIElementTypeTab",
          };
        NSMutableDictionary *swappedMapping = [NSMutableDictionary dictionary];
        [ElementTypeToStringMapping enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
            swappedMapping[obj] = key;
        }];
        StringToElementTypeMapping = swappedMapping.copy;
        
        UIAClassToElementTypeMapping =
        @{
          @"UIAActionSheet" : @(XCUIElementTypeSheet),
          @"UIAActivityIndicator" : @(XCUIElementTypeActivityIndicator),
          //    @"UIAActivityView"
          @"UIAAlert" : @(XCUIElementTypeAlert),
          @"UIAApplication" : @(XCUIElementTypeApplication),
          @"UIAButton" : @(XCUIElementTypeButton),
          @"UIACollectionView" : @(XCUIElementTypeCollectionView),
          @"UIACellView" : @(XCUIElementTypeCell),
          @"UIAImage" : @(XCUIElementTypeImage),
          @"UIAKey" : @(XCUIElementTypeKey),
          @"UIAKeyboard" : @(XCUIElementTypeKeyboard),
          @"UIALink" : @(XCUIElementTypeLink),
          @"UIANavigationBar" : @(XCUIElementTypeNavigationBar),
          @"UIAPageIndicator" : @(XCUIElementTypePageIndicator),
          @"UIAPicker" : @(XCUIElementTypePicker),
          @"UIAPickerWheel" : @(XCUIElementTypePickerWheel),
          @"UIAPopover" : @(XCUIElementTypePopover),
          @"UIAScrollView" : @(XCUIElementTypeScrollView),
          @"UIASearchBar" : @(XCUIElementTypeSearchField),
          @"UIASecureTextField" : @(XCUIElementTypeSecureTextField),
          @"UIASegmentedControl" : @(XCUIElementTypeSegmentedControl),
          @"UIASlider" : @(XCUIElementTypeSlider),
          @"UIAStaticText" : @(XCUIElementTypeStaticText),
          @"UIAStatusBar" : @(XCUIElementTypeStatusBar),
          @"UIASwitch" : @(XCUIElementTypeSwitch),
          @"UIATabBar" : @(XCUIElementTypeTabBar),
          @"UIATableGroup" : @(XCUIElementTypeTableColumn), //?
          @"UIATableView" : @(XCUIElementTypeTable),
          @"UIATextField" : @(XCUIElementTypeTextField),
          @"UIATextView" : @(XCUIElementTypeTextView),
          @"UIAToolbar" : @(XCUIElementTypeToolbar),
          @"UIAWebView" : @(XCUIElementTypeWebView),
          @"UIAWindow" : @(XCUIElementTypeWindow),
          @"UIAElement" : @(XCUIElementTypeAny),
          //@"" : @(XCUIElementTypeGroup),
          //@"" : @(XCUIElementTypeDrawer),
          //@"" : @(XCUIElementTypeDialog),
          //@"" : @(XCUIElementTypeRadioButton),
          //@"" : @(XCUIElementTypeRadioGroup),
          //@"" : @(XCUIElementTypeCheckBox),
          //@"" : @(XCUIElementTypeDisclosureTriangle),
          //@"" : @(XCUIElementTypePopUpButton),
          //@"" : @(XCUIElementTypeComboBox),
          //@"" : @(XCUIElementTypeMenuButton),
          //@"" : @(XCUIElementTypeToolbarButton),
          //@"" : @(XCUIElementTypeTabGroup),
          //@"" : @(XCUIElementTypeOutline),
          //@"" : @(XCUIElementTypeOutlineRow),
          //@"" : @(XCUIElementTypeBrowser),
          //@"" : @(XCUIElementTypeProgressIndicator),
          //@"" : @(XCUIElementTypeToggle),
          //@"" : @(XCUIElementTypeIcon),
          //@"" : @(XCUIElementTypeScrollBar),
          //@"" : @(XCUIElementTypeDatePicker),
          //@"" : @(XCUIElementTypeMenu),
          //@"" : @(XCUIElementTypeMenuItem),
          //@"" : @(XCUIElementTypeMenuBar),
          //@"" : @(XCUIElementTypeMenuBarItem),
          //@"" : @(XCUIElementTypeMap),
          //@"" : @(XCUIElementTypeIncrementArrow),
          //@"" : @(XCUIElementTypeDecrementArrow),
          //@"" : @(XCUIElementTypeTimeline),
          //@"" : @(XCUIElementTypeRatingIndicator),
          //@"" : @(XCUIElementTypeValueIndicator),
          //@"" : @(XCUIElementTypeSplitGroup),
          //@"" : @(XCUIElementTypeSplitter),
          //@"" : @(XCUIElementTypeRelevanceIndicator),
          //@"" : @(XCUIElementTypeColorWell),
          //@"" : @(XCUIElementTypeHelpTag),
          //@"" : @(XCUIElementTypeMatte),
          //@"" : @(XCUIElementTypeDockItem),
          //@"" : @(XCUIElementTypeRuler),
          //@"" : @(XCUIElementTypeRulerMarker),
          //@"" : @(XCUIElementTypeGrid),
          //@"" : @(XCUIElementTypeLevelIndicator),
          //@"" : @(XCUIElementTypeLayoutArea),
          //@"" : @(XCUIElementTypeLayoutItem),
          //@"" : @(XCUIElementTypeHandle),
          //@"" : @(XCUIElementTypeStepper),
          //@"" : @(XCUIElementTypeTab),
          };
        NSMutableDictionary *elementUIswappedMapping = [NSMutableDictionary dictionary];
        [UIAClassToElementTypeMapping enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            elementUIswappedMapping[obj] = key;
        }];
        ElementTypeToUIAClassMapping = elementUIswappedMapping.copy;
    });
}
//XCUIELement -> XCUIELement String
+ (NSString *)xcuiElementStringWithXCUIElement:(NSNumber*)number
{
    [self createMapping];
    
    XCUIElementType xcuiEType;
    if (number) {
        xcuiEType = (XCUIElementType)[number unsignedIntegerValue];
    }
    else{
        xcuiEType = XCUIElementTypeAny;
    }
    
    return ElementTypeToStringMapping[@(xcuiEType)];
}
//UIClass String -> XCUIELement String
+ (NSString *)xcuiElementStringWithUIAClassName:(NSString *)className
{
    [self createMapping];
    
    XCUIElementType xcuiEType;
    NSNumber *type = UIAClassToElementTypeMapping[className];
    if (type) {
        xcuiEType = (XCUIElementType)[type unsignedIntegerValue];
    }
    else{
        const BOOL isCellType = ([className isEqualToString:@"UIATableCell"] || [className isEqualToString:@"UIACollectionCell"]);
        if (isCellType) {
            xcuiEType = XCUIElementTypeCell;
        }
        else xcuiEType = XCUIElementTypeAny;
    }
    
    return ElementTypeToStringMapping[@(xcuiEType)];
}
//UIClass Short String -> XCUIELement String
+ (NSString *)xcuiElementStringWithUIShortString:(NSString*)shortString
{
    return [NSString stringWithFormat:@"XCUIElementType%@",shortString];
}
//UIClass String -> XCUIELement
+ (XCUIElementType)elementTypeWithUIAClassName:(NSString *)className
{
    NSNumber *type = UIAClassToElementTypeMapping[className];
    if (type) {
        return (XCUIElementType)[type unsignedIntegerValue];
    }
    const BOOL isCellType = ([className isEqualToString:@"UIATableCell"] || [className isEqualToString:@"UIACollectionCell"]);
    if (isCellType) {
        return XCUIElementTypeCell;
    }
    return XCUIElementTypeAny;
}
//XCUIElementType -> UIClass String
+ (NSString *)UIAClassNameWithElementType:(XCUIElementType)elementType
{
    return ElementTypeToUIAClassMapping[@(elementType)] ?: @"UIAElement";
}
//XCUIElementType String -> XCUIElementType
+ (XCUIElementType)elementTypeWithTypeName:(NSString *)typeName
{
    [self createMapping];
    NSNumber *type = StringToElementTypeMapping[typeName];
    return (XCUIElementType) ( type ? type.unsignedIntegerValue : XCUIElementTypeAny);
}
//XCUIElementType -> XCUIElementType String
+ (NSString *)stringWithElementType:(XCUIElementType)type
{
    [self createMapping];
    return ElementTypeToStringMapping[@(type)];
}
//XCUIElementType -> short string
+ (NSString *)shortStringWithElementType:(XCUIElementType)type
{
    return [[self stringWithElementType:type] stringByReplacingOccurrencesOfString:@"XCUIElementType" withString:@""];
}

@end
