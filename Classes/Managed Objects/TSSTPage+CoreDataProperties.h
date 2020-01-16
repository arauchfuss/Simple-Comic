//
//  TSSTPage+CoreDataProperties.h
//  SimpleComic
//
//  Created by C.W. Betts on 10/13/16.
//  Copyright © 2016 Dancing Tortoise Software. All rights reserved.
//

#import "TSSTPage.h"
#import "TSSTManagedGroup.h"
#import "TSSTManagedSession.h"


NS_ASSUME_NONNULL_BEGIN

@interface TSSTPage (CoreDataProperties)

+ (NSFetchRequest<TSSTPage *> *)fetchRequest;

@property (nonatomic) float aspectRatio;
@property (nonatomic) double height;
@property (nullable, nonatomic, copy) NSString *imagePath;
@property (nullable, nonatomic, copy) NSNumber *index;
@property (nonatomic) BOOL text;
@property (nullable, nonatomic, retain) NSData *thumbnailData;
@property (nonatomic) double width;
@property (nullable, nonatomic, retain) TSSTManagedGroup *group;
@property (nullable, nonatomic, retain) TSSTManagedSession *session;

@end

NS_ASSUME_NONNULL_END
