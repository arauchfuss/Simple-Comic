//  OCRRangeEnumerator.h
//
//  Created by David Phillip Oster on 7/02/2022. license.txt applies.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

/// Holds for loop state for iterating over a range of the document for dispatching async.
/// 
/// Modeled after a C for loop, but inclusive: start..end
@interface OCRRangeEnumerator : NSObject

- (instancetype)initWithStart:(NSInteger)start end:(NSInteger)end increment:(NSInteger)increment;

- (instancetype)init NS_UNAVAILABLE;

/// returns \c NSNotFound when exhausted
- (NSUInteger)next;

@end

NS_ASSUME_NONNULL_END

