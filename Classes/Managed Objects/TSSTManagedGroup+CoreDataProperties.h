//
//  TSSTManagedGroup+CoreDataProperties.h
//  SimpleComic
//
//  Created by C.W. Betts on 10/13/16.
//  Copyright © 2016 Dancing Tortoise Software. All rights reserved.
//

#import "TSSTManagedGroup.h"

@class TSSTManagedSession;
@class TSSTPage;

NS_ASSUME_NONNULL_BEGIN

@interface TSSTManagedGroup (CoreDataProperties)

+ (NSFetchRequest<TSSTManagedGroup *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSDate *modified;
@property (nullable, nonatomic, copy) NSString *name;
@property (nullable, nonatomic, copy) NSNumber *nested;
@property (nullable, nonatomic, retain) NSObject *nestedImages;
@property (nullable, nonatomic, retain) NSData *pathData;
@property (nullable, nonatomic, retain) TSSTManagedGroup *group;
@property (nullable, nonatomic, retain) NSSet<TSSTManagedGroup *> *groups;
@property (nullable, nonatomic, retain) NSSet<TSSTPage *> *images;
@property (nullable, nonatomic, retain) TSSTManagedSession *session;

@end

@interface TSSTManagedGroup (CoreDataGeneratedAccessors)

- (void)addGroupsObject:(TSSTManagedGroup *)value;
- (void)removeGroupsObject:(TSSTManagedGroup *)value;
- (void)addGroups:(NSSet<TSSTManagedGroup *> *)values;
- (void)removeGroups:(NSSet<TSSTManagedGroup *> *)values;

- (void)addImagesObject:(TSSTPage *)value;
- (void)removeImagesObject:(TSSTPage *)value;
- (void)addImages:(NSSet<TSSTPage *> *)values;
- (void)removeImages:(NSSet<TSSTPage *> *)values;

@end


@interface TSSTManagedArchive (CoreDataProperties)

+ (NSFetchRequest<TSSTManagedArchive *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSString *password;
@property (nullable, nonatomic, copy) NSString *solidDirectory;

@end


@interface TSSTManagedPDF (CoreDataProperties)

+ (NSFetchRequest<TSSTManagedPDF *> *)fetchRequest;

@end

NS_ASSUME_NONNULL_END
