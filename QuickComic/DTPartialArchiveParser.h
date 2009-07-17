//
//  DTPartialArchiveParser.h
//  QuickComic
//
//  Created by Alexander Rauchfuss on 7/12/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class XADArchiveParser, XADString;

@interface DTPartialArchiveParser : NSObject 
{
	NSString * searchString;
	NSData * foundData;
}

- (id)initWithPath:(NSString *)archivePath searchString:(NSString *)search;
- (NSData *)searchResult;

-(void)archiveParser:(XADArchiveParser *)parser foundEntryWithDictionary:(NSDictionary *)dict;
-(BOOL)archiveParsingShouldStop:(XADArchiveParser *)parser;

@end
