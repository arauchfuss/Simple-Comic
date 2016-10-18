//
//  TSSTManagedGroup+CoreDataProperties.m
//  SimpleComic
//
//  Created by C.W. Betts on 10/13/16.
//  Copyright © 2016 Dancing Tortoise Software. All rights reserved.
//

#import "TSSTManagedGroup+CoreDataProperties.h"
#import "TSSTManagedSession.h"
#import "TSSTPage.h"

@implementation TSSTManagedGroup (CoreDataProperties)

+ (NSFetchRequest<TSSTManagedGroup *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"ImageGroup"];
}

@dynamic modified;
@dynamic name;
@dynamic nested;
@dynamic pathData;
@dynamic group;
@dynamic groups;
@dynamic images;
@dynamic session;

@end

@implementation TSSTManagedArchive (CoreDataProperties)

+ (NSFetchRequest<TSSTManagedArchive *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"Archive"];
}

@dynamic password;
@dynamic solidDirectory;

@end


@implementation TSSTManagedPDF (CoreDataProperties)

+ (NSFetchRequest<TSSTManagedPDF *> *)fetchRequest {
    return [[NSFetchRequest alloc] initWithEntityName:@"PDF"];
}

@end
