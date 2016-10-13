//
//  TSSTPage+CoreDataProperties.m
//  SimpleComic
//
//  Created by C.W. Betts on 10/13/16.
//  Copyright © 2016 Dancing Tortoise Software. All rights reserved.
//

#import "TSSTPage+CoreDataProperties.h"

@implementation TSSTPage (CoreDataProperties)

+ (NSFetchRequest<TSSTPage *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"Image"];
}

@dynamic aspectRatio;
@dynamic height;
@dynamic imagePath;
@dynamic index;
@dynamic text;
@dynamic thumbnailData;
@dynamic width;
@dynamic group;
@dynamic session;

@end
