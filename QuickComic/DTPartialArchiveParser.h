//
//  DTPartialArchiveParser.h
//  QuickComic
//
//  Created by Alexander Rauchfuss on 7/12/09.
//  Copyright 2009 Dancing Tortoise Software. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class XADArchiveParser, XADString;

NS_ASSUME_NONNULL_BEGIN

@interface DTPartialArchiveParser : NSObject 

- (instancetype)init UNAVAILABLE_ATTRIBUTE;
- (instancetype)initWithURL:(NSURL *)archivePath searchString:(NSString *)search;
@property (readonly, copy, nullable) NSData *searchResult;

@end

NS_ASSUME_NONNULL_END
