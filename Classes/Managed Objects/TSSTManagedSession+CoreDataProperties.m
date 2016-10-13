//
//  TSSTManagedSession+CoreDataProperties.m
//  SimpleComic
//
//  Created by C.W. Betts on 10/13/16.
//  Copyright © 2016 Dancing Tortoise Software. All rights reserved.
//

#import "TSSTManagedSession+CoreDataProperties.h"
#import "TSSTManagedGroup.h"
#import "TSSTPage.h"

@implementation TSSTManagedSession (CoreDataProperties)

+ (NSFetchRequest<TSSTManagedSession *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"Session"];
}

@dynamic fullscreen;
@dynamic loupe;
@dynamic pageOrder;
@dynamic position;
@dynamic rotation;
@dynamic scaleOptions;
@dynamic scrollPosition;
@dynamic selection;
@dynamic twoPageSpread;
@dynamic zoomLevel;
@dynamic groups;
@dynamic images;

@end
