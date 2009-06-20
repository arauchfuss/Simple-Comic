//
//  TSSTManagedBookmark.m
//  SimpleComic
//
//  Created by Alexander Rauchfuss on 4/29/08.
//  Copyright 2008 __MyCompanyName__. All rights reserved.
//

#import "TSSTManagedBookmark.h"
#import "BDAlias.h"
#import "NSImage+QuickLook.h"

@implementation TSSTManagedBookmark

@synthesize alias;


- (void)awakeFromFetch
{
    [super awakeFromFetch];
	
    NSData * aliasData = [self valueForKey: @"locationData"];
	
    if (aliasData != nil)
    {
        BDAlias * savedAlias = [[BDAlias alloc] initWithData: aliasData];
		[self setValue: savedAlias forKey: @"alias"];
		[savedAlias release];
    }
}



- (void)didTurnIntoFault
{
	[alias release];
}



- (void)setFilePath:(NSString *)path
{
	BDAlias * newAlias = [[BDAlias alloc] initWithPath: path];
	[self setValue: newAlias forKey: @"alias"];
	[self setValue: [newAlias aliasData] forKey: @"locationData"];
	[newAlias release];
}



- (NSString *)filePath
{
	return [self.alias fullPath];
}


- (NSImage *)coverImage
{
	NSImage * cover = nil;
	NSString * path = [self filePath];
	
	if(path)
	{
		cover = [NSImage imageWithPreviewOfFileAtPath: path ofSize: NSMakeSize(512, 512) asIcon: NO];
	}
	
	return cover;
}


@end
