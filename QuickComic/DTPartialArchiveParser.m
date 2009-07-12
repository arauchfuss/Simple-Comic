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
		foundData = nil;
		fileNames = [[NSMutableDictionary dictionary] retain];
	}
	return self;
}


- (id)initWithPath:(NSString *)archivePath searchIndex:(int)search
{
	NSLog(@"test");
	self=[self init];	
	if(self)
	{
		searchIndex = search;
		XADArchiveParser * parser = [XADArchiveParser archiveParserForPath: archivePath];
		if(parser)
		{
			[parser setDelegate: self];
			
			@try { [parser parse]; }
			@catch(id e)
			{
				NSLog([e name]);
			}
		}
	}
	
	return self;
}


- (void) dealloc
{
	[fileNames release];
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
	
	XADString * name = [dict objectForKey:XADFileNameKey];
	NSNumber * index = [fileNames objectForKey: name];
	
	if(index)
	{
		int n=[index intValue];
		if(n != searchIndex || isres)
		{
			dict = nil;
		}
	}
	else
	{
		if(isres)
		{
			dict = nil;
		}
		
		[fileNames setObject:[NSNumber numberWithInt: [fileNames count]] forKey: name];
	}
	// Create a new entry instead
	
	if(dict)
	{
		CSHandle * handle = [parser handleForEntryWithDictionary: dict wantChecksum:YES];
		if(!handle) [XADException raiseDecrunchException];
		foundData = [[handle remainingFileContents] retain];
		if([handle hasChecksum]&&![handle isChecksumCorrect]) [XADException raiseChecksumException];
		
	}
}


-(BOOL)archiveParsingShouldStop:(XADArchiveParser *)parser
{
	NSLog(@"stop?");
	return foundData ? YES : NO;
}


@end
