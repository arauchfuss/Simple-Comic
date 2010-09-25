//
//  DTPartialArchiveParser.m
//  QuickComic
//
//  Created by Alexander Rauchfuss on 7/12/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "DTPartialArchiveParser.h"
#include <XADMaster/XADArchive.h>

@implementation DTPartialArchiveParser

- (id) init
{
	self = [super init];
	if (self != nil) {
	}
	return self;
}


- (id)initWithPath:(NSString *)archivePath searchString:(NSString *)search
{
	self=[self init];	
	if(self)
	{
		searchString = [search retain];
		XADArchiveParser * parser = [XADArchiveParser archiveParserForPath: archivePath];
		if(parser)
		{
			[parser setDelegate: self];
			
			@try { [parser parse]; }
			@catch(NSException * exception)
			{
				NSLog(@"DTPartialArchiveParser: Caught %@: %@", [exception name], [exception reason]);
			}
		}
	}
	
	return self;
}


- (void) dealloc
{
	[searchString release];
	[foundData release];
	[super dealloc];
}


- (NSData *)searchResult
{
	return foundData;
}


#pragma mark XADArchiveParser Delegates

-(void)archiveParser:(XADArchiveParser *)parser foundEntryWithDictionary:(NSDictionary *)dict
{	
	NSNumber * resnum = [dict objectForKey: XADIsResourceForkKey];
	BOOL isres = resnum&&[resnum boolValue];
	foundData = nil;

	if(!isres)
	{
		XADString * name = [dict objectForKey: XADFileNameKey];
		NSString * encodedName = [name stringWithEncoding: NSNonLossyASCIIStringEncoding];
//		NSLog(@"Encoded Name: %@", encodedName);
		if([searchString isEqualToString: encodedName])
		{
			CSHandle * handle = [parser handleForEntryWithDictionary: dict wantChecksum:YES];
			if(!handle) [XADException raiseDecrunchException];
			foundData = [[handle remainingFileContents] retain];
//			NSLog(@"found %@", encodedName);
			if([handle hasChecksum]&&![handle isChecksumCorrect])
			{
				[XADException raiseChecksumException];
			}
		}
	}
}


-(BOOL)archiveParsingShouldStop:(XADArchiveParser *)parser
{
	return foundData != nil ? YES : NO;
}


@end
