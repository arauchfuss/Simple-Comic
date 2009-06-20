//
//  TSSTManagedBookmarkGroup.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 5/2/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TSSTManagedBookmarkGroup.h"


@implementation TSSTManagedBookmarkGroup


//- (BOOL)validateForDelete:(NSError **)error
//{
//	BOOL superValidate = [super validateForDelete: error];
//	
//	if([self valueForKey: @"identifier"] != nil)
//	{
//		NSLog(@"test");
//		*error = [NSError errorWithDomain: @"com.tsst.simplecomic" code: 9001 userInfo: 0];
//		superValidate = NO;
//	}
//	
//	return superValidate;
//}
//
//
//-(BOOL)validateName:(id *)ioValue error:(NSError **)outError
//{
//	BOOL valid;
//	if([self valueForKey: @"identifier"])
//	{
//		NSLog(@"test edit");
//		*outError = [NSError errorWithDomain: @"com.tsst.simplecomic" code: 9002 userInfo: 0];
//		valid = NO;
//	}
//	
//	return valid;
//}


@end

