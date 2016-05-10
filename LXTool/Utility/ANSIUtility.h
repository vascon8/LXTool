//
//  ANSIUtils.h
//
//
// Code adapted from Samuel Goodwin's Turbo Mud Client
// "https://github.com/sgoodwin/Turbo-Mud/tree/experiment/Turbo%20Mud"
//

#import <Foundation/Foundation.h>

@interface ANSIUtility : NSObject

+ (NSAttributedString*)processIncomingStream:(NSString*)string withPreviousAttributes:(NSMutableDictionary **)attrs;
@end
