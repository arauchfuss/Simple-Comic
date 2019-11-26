//
//  DTPartialArchiveParser.m
//  QuickComic
//
//  Created by Alexander Rauchfuss on 7/12/09.
//  Copyright 2009 Dancing Tortoise Software. All rights reserved.
//

#import "DTPartialArchiveParser.h"
#import <XADMaster/XADArchiveParser.h>

@interface DTPartialArchiveParser () <XADArchiveParserDelegate>

@end

@implementation DTPartialArchiveParser
{
	NSString * searchString;
}
@synthesize searchResult = foundData;

- (instancetype)initWithURL:(NSURL *)archivePath searchString:(NSString *)search
{
	if(self=[super init])
	{
		searchString = [search copy];
		XADArchiveParser * parser = [XADArchiveParser archiveParserForFileURL: archivePath];
		if(parser)
		{
			parser.delegate = self;

			@try { [parser parse]; }
			@catch(NSException * exception)
			{
				NSLog(@"DTPartialArchiveParser: Caught %@: %@", [exception name], [exception reason]);
			}
		}
	}
	
	return self;
}

#pragma mark XADArchiveParser Delegates

-(void)archiveParser:(XADArchiveParser *)parser foundEntryWithDictionary:(NSDictionary<XADArchiveKeys,id> *)dict
{	
	NSNumber * resnum = dict[XADIsResourceForkKey];
	BOOL isres = resnum&&[resnum boolValue];
	foundData = nil;

	if(!isres)
	{
		XADString * name = dict[XADFileNameKey];
		NSString * encodedName = [name stringWithEncodingName:parser.encodingName];
		// NSLog(@"Encoded Name: %@", encodedName);
		if([searchString isEqualToString: encodedName])
		{
			CSHandle * handle = [parser handleForEntryWithDictionary: dict wantChecksum:YES];
			if(!handle) [XADException raiseDecrunchException];
			foundData = [handle remainingFileContents];
			// NSLog(@"found %@", encodedName);
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
