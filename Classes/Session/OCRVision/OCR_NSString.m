//  OCR_NSString.m
//
//  Created by David Phillip Oster on 6/16/22. license.txt applies.
//

#import "OCR_NSString.h"

@implementation  NSString (OCR)

- (NSRange)ocr_rangeOfString:(NSString *)searchString options:(OCRStringCompareOptions)options range:(NSRange)receiverRange
{
	if ((options & ( OCRStartWith | OCREndWith)) == 0) {
		return [self rangeOfString:searchString options:(NSStringCompareOptions)options range:receiverRange];
	}
	OCRStringCompareOptions cleanedMask = (options & ~( OCRStartWith | OCREndWith));
	NSRange candidateR;
	do {
		candidateR = [self rangeOfString:searchString options:(NSStringCompareOptions)cleanedMask range:receiverRange];
		if (candidateR.location != NSNotFound) {
			if ( (options &  ( OCRStartWith | OCREndWith)) ==  OCRStartWith) {
				if ([self ocr_atStart:candidateR]){ return candidateR; }
			} else if ( (options & ( OCRStartWith | OCREndWith)) == OCREndWith) {
				if ([self ocr_atEnd:candidateR]){ return candidateR; }
			} else if ( (options & ( OCRStartWith | OCREndWith)) == ( OCRStartWith | OCREndWith)) {
				if ([self ocr_atStart:candidateR] && [self ocr_atEnd:candidateR]){ return candidateR; }
			}

			// Change the region of interest by one to handle next match partially overlapping this match.
			if (cleanedMask & OCRBackwardSearch) {
				receiverRange.length -= 1;
			} else {
				NSInteger advance = MAX(0, (NSInteger)candidateR.location - (NSInteger)receiverRange.location)  + 1 ;
				receiverRange.location += advance;
				receiverRange.length -= MIN(receiverRange.length, advance);
			}

		}
	} while(candidateR.location != NSNotFound && 0 < receiverRange.length);
	return NSMakeRange(NSNotFound, 0);
}

// given a range r, of self, true if it represents the start of a non-alphanumeric delimited word.
- (BOOL)ocr_atStart:(NSRange) r
{
	if (r.length == 0) {
		return NO;
	}
	if (r.location == 0) {
		return YES;
	}
	return [[[NSCharacterSet letterCharacterSet] invertedSet] characterIsMember:[self characterAtIndex:r.location - 1]];
}

// given a range r, of self, true if it represents the end of a non-alphanumeric delimited word.
- (BOOL)ocr_atEnd:(NSRange) r
{
	if (r.length == 0) {
		return NO;
	}
	if (r.location + r.length == self.length) {
		return YES;
	}
	return [[[NSCharacterSet letterCharacterSet] invertedSet] characterIsMember:[self characterAtIndex:r.location + r.length]];
}

@end
