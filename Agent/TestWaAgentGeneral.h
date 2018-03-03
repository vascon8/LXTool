//
//  TestWaAgentGeneral.h
//  TestWaAgent
//
//  Created by test on 16/9/8.
//  Copyright © 2016年 xinliu. All rights reserved.
//

#ifndef TestWaAgentGeneral_h
#define TestWaAgentGeneral_h

#define TestAAgentSessionIDStr @"sessionId"
#define TestAAgentSessionIDPrefixStr @":sessionID"
#define TestAAgentUuidStr @"uuid"
#define TestAAgentMethodStr @"method"
#define TestAAgentPathStr @"path"
#define TestAAgentParametersStr @"parameters"
#define TestAAgentActionStr @"action"

#define TestAAgentHttpResStr @"httpResponse"
#define TestAAgentResValueStr @"value"
#define TestAAgentHttpResStatusStr @"status"
#define TestAAgentUsbResStr @"usbResponse"

#define TestAAgentClientResStatusStr @"statusCode"

#pragma mark - command verb
#define TestAAgentCommandGetScreenshot @"screenshot"
#define TestAAgentCommandGetSource @"source"
#define TestAAgentCommandCreateSession @"session"
#define TestAAgentCommandGetTree @"tree"
#define TestAAgentCommandGetStatus @"status"
#define TestAAgentCommandGetSessions @"sessions"
#define TestAAgentCommandSetSourceFormtDescription @"description"
#define TestAAgentCommandSetSourceFormatDefault @"defaylt_format"

static const in_port_t TestWaAgentIPv4PortNumber = 5000;

enum uint32_t{
    TestWaAgentNoTag = 0,
    TestWaAgentTagServerAnalyReqError = 1,
    TestWaAgentTagServerAnalyRouteResError = 2,
    TestWaAgentTagServerEncodeResError = 3,
    TestWaAgentFrameTypeDeviceInfo = 101,
    TestWaAgentFrameTypeHttpTalk = 102,
    TestWaAgentFrameTypeUsbTalk = 103,
    TestWaAgentFrameTypeUsbScreenshotTalk = 104,
    TestWaAgentFrameTypeUsbSourceTalk = 105,
    TestWaAgentFrameTypePing = 116,
    TestWaAgentFrameTypePong = 117
};

NS_ENUM_AVAILABLE(10_11, 9_0)
typedef NS_ENUM(NSUInteger, XCUIElementType) {
    XCUIElementTypeAny = 0,
    XCUIElementTypeOther = 1,
    XCUIElementTypeApplication = 2,
    XCUIElementTypeGroup = 3,
    XCUIElementTypeWindow = 4,
    XCUIElementTypeSheet = 5,
    XCUIElementTypeDrawer = 6,
    XCUIElementTypeAlert = 7,
    XCUIElementTypeDialog = 8,
    XCUIElementTypeButton = 9,
    XCUIElementTypeRadioButton = 10,
    XCUIElementTypeRadioGroup = 11,
    XCUIElementTypeCheckBox = 12,
    XCUIElementTypeDisclosureTriangle = 13,
    XCUIElementTypePopUpButton = 14,
    XCUIElementTypeComboBox = 15,
    XCUIElementTypeMenuButton = 16,
    XCUIElementTypeToolbarButton = 17,
    XCUIElementTypePopover = 18,
    XCUIElementTypeKeyboard = 19,
    XCUIElementTypeKey = 20,
    XCUIElementTypeNavigationBar = 21,
    XCUIElementTypeTabBar = 22,
    XCUIElementTypeTabGroup = 23,
    XCUIElementTypeToolbar = 24,
    XCUIElementTypeStatusBar = 25,
    XCUIElementTypeTable = 26,
    XCUIElementTypeTableRow = 27,
    XCUIElementTypeTableColumn = 28,
    XCUIElementTypeOutline = 29,
    XCUIElementTypeOutlineRow = 30,
    XCUIElementTypeBrowser = 31,
    XCUIElementTypeCollectionView = 32,
    XCUIElementTypeSlider = 33,
    XCUIElementTypePageIndicator = 34,
    XCUIElementTypeProgressIndicator = 35,
    XCUIElementTypeActivityIndicator = 36,
    XCUIElementTypeSegmentedControl = 37,
    XCUIElementTypePicker = 38,
    XCUIElementTypePickerWheel = 39,
    XCUIElementTypeSwitch = 40,
    XCUIElementTypeToggle = 41,
    XCUIElementTypeLink = 42,
    XCUIElementTypeImage = 43,
    XCUIElementTypeIcon = 44,
    XCUIElementTypeSearchField = 45,
    XCUIElementTypeScrollView = 46,
    XCUIElementTypeScrollBar = 47,
    XCUIElementTypeStaticText = 48,
    XCUIElementTypeTextField = 49,
    XCUIElementTypeSecureTextField = 50,
    XCUIElementTypeDatePicker = 51,
    XCUIElementTypeTextView = 52,
    XCUIElementTypeMenu = 53,
    XCUIElementTypeMenuItem = 54,
    XCUIElementTypeMenuBar = 55,
    XCUIElementTypeMenuBarItem = 56,
    XCUIElementTypeMap = 57,
    XCUIElementTypeWebView = 58,
    XCUIElementTypeIncrementArrow = 59,
    XCUIElementTypeDecrementArrow = 60,
    XCUIElementTypeTimeline = 61,
    XCUIElementTypeRatingIndicator = 62,
    XCUIElementTypeValueIndicator = 63,
    XCUIElementTypeSplitGroup = 64,
    XCUIElementTypeSplitter = 65,
    XCUIElementTypeRelevanceIndicator = 66,
    XCUIElementTypeColorWell = 67,
    XCUIElementTypeHelpTag = 68,
    XCUIElementTypeMatte = 69,
    XCUIElementTypeDockItem = 70,
    XCUIElementTypeRuler = 71,
    XCUIElementTypeRulerMarker = 72,
    XCUIElementTypeGrid = 73,
    XCUIElementTypeLevelIndicator = 74,
    XCUIElementTypeCell = 75,
    XCUIElementTypeLayoutArea = 76,
    XCUIElementTypeLayoutItem = 77,
    XCUIElementTypeHandle = 78,
    XCUIElementTypeStepper = 79,
    XCUIElementTypeTab = 80,
};

#endif /* TestWaAgentGeneral_h */
