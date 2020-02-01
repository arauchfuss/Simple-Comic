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

@property (nonatomic) BOOL fullscreen;
@property (nonatomic) BOOL loupe;
@property (nonatomic) BOOL pageOrder;
@property (nullable, nonatomic, retain) NSData *position;
@property (nonatomic) int16_t rotation;
@property (nonatomic) int16_t scaleOptions;
@property (nullable, nonatomic, retain) NSData *scrollPosition;
@property (nonatomic) int16_t selection;
@property (nonatomic) BOOL twoPageSpread;
@property (nonatomic) float zoomLevel;
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
