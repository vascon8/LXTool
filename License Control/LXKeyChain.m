//
//  LXKeyChain.m
//  TestWA
//
//  Created by xinliu on 15-11-6.
//  Copyright (c) 2015年 ___xin.liu___. All rights reserved.
//

#import "LXKeyChain.h"

#define LXStringByteLength(a) (UInt32)(( [a UTF8String] ? strlen( [a UTF8String] ) : 0 ))

@implementation LXKeyChain
+ (void) setGenericPassword:(NSString *) password forService:(NSString *) service account:(NSString *) account {
	NSParameterAssert( service );
	NSParameterAssert( account );
    
	if( ! [password length] ) {
		[self removeGenericPasswordForService:service account:account];
	} else if( ! [[self genericPasswordForService:service account:account] isEqualToString:password] ) {
		[self removeGenericPasswordForService:service account:account];

		SecKeychainAddGenericPassword( NULL, LXStringByteLength( service ), [service UTF8String], LXStringByteLength( account ), [account UTF8String], LXStringByteLength( password ), (void *) [password UTF8String], NULL );
	}
}
+ (NSString *) genericPasswordForService:(NSString *) service account:(NSString *) account {
	OSStatus ret = 0;
	UInt32 len = 0;
	void *p = NULL;
	NSString *string = nil;
    
	ret = SecKeychainFindGenericPassword( NULL, LXStringByteLength( service ), [service UTF8String], LXStringByteLength( account ), [account UTF8String], &len, &p, NULL );
	if( ret == noErr ) string = [[NSString allocWithZone:nil] initWithBytes:(const void *) p length:len encoding:NSUTF8StringEncoding];
	SecKeychainItemFreeContent( NULL, p );
    
    //NSLog(@"keychain osstatus:%d",ret);
    
	return string;
}

+ (void) removeGenericPasswordForService:(NSString *) service account:(NSString *) account {
	OSStatus ret = 0;
	SecKeychainItemRef itemref = NULL;
    
	NSParameterAssert( service );
	NSParameterAssert( account );
    
	ret = SecKeychainFindGenericPassword( NULL, LXStringByteLength( service ), [service UTF8String], LXStringByteLength( account ), [account UTF8String], NULL, NULL, &itemref );
	if( ret == noErr ) SecKeychainItemDelete( itemref );
}
@end
