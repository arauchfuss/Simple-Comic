//
//  ManagedSmartFolder+CoreDataProperties.h
//  Simple Comic
//
//  Created by C.W. Betts on 6/23/20.
//  Copyright © 2020 Dancing Tortoise Software. All rights reserved.
//
//

#import "ManagedSmartFolder+CoreDataClass.h"


NS_ASSUME_NONNULL_BEGIN

@interface ManagedSmartFolder (CoreDataProperties)

+ (NSFetchRequest<ManagedSmartFolder *> *)fetchRequest;


@end

NS_ASSUME_NONNULL_END
