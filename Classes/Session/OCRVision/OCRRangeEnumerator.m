//  OCRRangeEnumerator.m
//
//  Created by David Phillip Oster on 7/02/2022.  license.txt applies.
//

#import "OCRRangeEnumerator.h"

@implementation OCRRangeEnumerator {
  NSInteger current;
  NSInteger end;
  NSInteger increment;
}

- (instancetype)initWithStart:(NSInteger)start end:(NSInteger)xend increment:(NSInteger)xincrement {
	self = [super init];
	if (self) {
		if (xincrement == 0) {
			start = NSNotFound;
		}
		current = start;
		end = xend;
		increment = xincrement;
	}
	return self;
}

- (NSUInteger)next {
	NSUInteger result = current;
	if (current != NSNotFound) {
		current += increment;
		if (increment < 0) {
			if (current < end) {
				current = NSNotFound;
			}
		} else {
			if (end < current) {
				current = NSNotFound;
			}
		}
	}
	return result;
}

@end
