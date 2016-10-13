//
//  TSSTManagedSession+CoreDataProperties.h
//  SimpleComic
//
//  Created by C.W. Betts on 10/13/16.
//  Copyright © 2016 Dancing Tortoise Software. All rights reserved.
//

#import "TSSTManagedSession.h"


@class TSSTManagedGroup;
@class TSSTPage;

NS_ASSUME_NONNULL_BEGIN

@interface TSSTManagedSession (CoreDataProperties)

+ (NSFetchRequest<TSSTManagedSession *> *)fetchRequest;

@property (nullable, nonatomic, copy) NSNumber *fullscreen;
@property (nullable, nonatomic, copy) NSNumber *loupe;
@property (nullable, nonatomic, copy) NSNumber *pageOrder;
@property (nullable, nonatomic, retain) NSData *position;
@property (nullable, nonatomic, copy) NSNumber *rotation;
@property (nullable, nonatomic, copy) NSNumber *scaleOptions;
@property (nullable, nonatomic, retain) NSData *scrollPosition;
@property (nullable, nonatomic, copy) NSNumber *selection;
@property (nullable, nonatomic, copy) NSNumber *twoPageSpread;
@property (nullable, nonatomic, copy) NSNumber *zoomLevel;
@property (nullable, nonatomic, retain) NSSet<TSSTManagedGroup *> *groups;
@property (nullable, nonatomic, retain) NSSet<TSSTPage *> *images;

@end

@interface TSSTManagedSession (CoreDataGeneratedAccessors)

- (void)addGroupsObject:(TSSTManagedGroup *)value;
- (void)removeGroupsObject:(TSSTManagedGroup *)value;
- (void)addGroups:(NSSet<TSSTManagedGroup *> *)values;
- (void)removeGroups:(NSSet<TSSTManagedGroup *> *)values;

- (void)addImagesObject:(TSSTPage *)value;
- (void)removeImagesObject:(TSSTPage *)value;
- (void)addImages:(NSSet<TSSTPage *> *)values;
- (void)removeImages:(NSSet<TSSTPage *> *)values;

@end

NS_ASSUME_NONNULL_END
