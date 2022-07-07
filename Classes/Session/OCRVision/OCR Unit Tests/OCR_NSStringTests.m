//
//  OCR_NSStringTests.m
//  Created by David Phillip Oster on 6/14/2022.

#import <XCTest/XCTest.h>
#import "OCR_NSString.h"

@interface OCR_NSStringTests : XCTestCase
@end


@implementation OCR_NSStringTests

// If the search string is empty and the body string is empty, return not found.
- (void) testEmptyEmpty {
	NSRange r = [@"" ocr_rangeOfString:@"" options:OCRCaseInsensitiveSearch range:NSMakeRange(0,0)];
	NSRange rNotFound = NSMakeRange(NSNotFound, 0);
	XCTAssertTrue(NSEqualRanges(r, rNotFound), @"");
}

// If the search string is empty return not found, even if the body is not empty.
// Although it is logically true that the search string matches anything, I choose correct behavior here to mean: not found
- (void) testSearchEmpty {
	NSRange r = [@"Hello world line two" ocr_rangeOfString:@"" options:OCRCaseInsensitiveSearch range:NSMakeRange(0, 19)];
	NSRange rNotFound = NSMakeRange(NSNotFound, 0);
	XCTAssertTrue(NSEqualRanges(r, rNotFound), @"");
}

// If the body is empty return not found, no matter the search string.
- (void) testBodyEmpty {
	NSRange r = [@"" ocr_rangeOfString:@"world" options:OCRCaseInsensitiveSearch range:NSMakeRange(0,0)];
	NSRange rNotFound = NSMakeRange(NSNotFound, 0);
	XCTAssertTrue(NSEqualRanges(r, rNotFound), @"");
}

// If the match is entirely in the first piece, then return the match range.
- (void) testSimpleMatchForward {
	NSRange r = [@"in the world!" ocr_rangeOfString:@"world" options:OCRCaseInsensitiveSearch range:NSMakeRange(0, 13)];
	XCTAssertTrue(NSEqualRanges(NSMakeRange(7, 5), r), @"got loc:%d len:%d", (int)r.location, (int)r.length);
}

// If the backward match is entirely in the first piece, then return the match range.
- (void) testSimpleMatchBackward {
	NSRange r = [@"in the world!" ocr_rangeOfString:@"world" options:OCRCaseInsensitiveSearch|OCRBackwardSearch range:NSMakeRange(0, 13)];
	XCTAssertTrue(NSEqualRanges(NSMakeRange(7, 5), r), @"got loc:%d len:%d", (int)r.location, (int)r.length);
}

// If the match is the entire body, then return the match range.
- (void) testSimpleMatchContainsForward {
	NSRange r = [@"a" ocr_rangeOfString:@"a" options:OCRCaseInsensitiveSearch range:NSMakeRange(0,1)];
	XCTAssertTrue(NSEqualRanges(NSMakeRange(0, 1), r), @"got loc:%d len:%d", (int)r.location, (int)r.length);
}

- (void) testSimpleMatchStartsWithForward {
	NSRange r = [@"a" ocr_rangeOfString:@"a" options: OCRStartWith range:NSMakeRange(0,1)];
	XCTAssertTrue(NSEqualRanges(NSMakeRange(0, 1), r), @"got loc:%d len:%d", (int)r.location, (int)r.length);
}

- (void) testSimpleMatchEndsWithForward {
	NSRange r = [@"a" ocr_rangeOfString:@"a" options:OCREndWith range:NSMakeRange(0,1)];
	XCTAssertTrue(NSEqualRanges(NSMakeRange(0, 1), r), @"got loc:%d len:%d", (int)r.location, (int)r.length);
}

- (void) testSimpleMatchWordForward {
	NSRange r = [@"a" ocr_rangeOfString:@"a" options: OCRStartWith|OCREndWith range:NSMakeRange(0,1)];
	XCTAssertTrue(NSEqualRanges(NSMakeRange(0, 1), r), @"got loc:%d len:%d", (int)r.location, (int)r.length);
}

- (void) testMatchStartsWithForward {
	NSRange r = [@"aa a" ocr_rangeOfString:@"a" options: OCRStartWith range:NSMakeRange(0,1)];
	XCTAssertTrue(NSEqualRanges(NSMakeRange(0, 1), r), @"got loc:%d len:%d", (int)r.location, (int)r.length);
}

- (void) testMatchEndsWithForward {
	NSRange r = [@"aaaa a" ocr_rangeOfString:@"a" options:OCREndWith range:NSMakeRange(0,6)];
	XCTAssertTrue(NSEqualRanges(NSMakeRange(3, 1), r), @"got loc:%d len:%d", (int)r.location, (int)r.length);
}

- (void) testMatchWordBackward {
	NSRange r = [@"aa a" ocr_rangeOfString:@"a" options:OCRBackwardSearch|OCRStartWith|OCREndWith range:NSMakeRange(0,4)];
	XCTAssertTrue(NSEqualRanges(NSMakeRange(3, 1), r), @"got loc:%d len:%d", (int)r.location, (int)r.length);
}

- (void)testSimpleMatchStartsWithBackward {
	NSRange r = [@"a" ocr_rangeOfString:@"a" options:OCRBackwardSearch|OCRStartWith range:NSMakeRange(0,1)];
	XCTAssertTrue(NSEqualRanges(NSMakeRange(0, 1), r), @"got loc:%d len:%d", (int)r.location, (int)r.length);
}

- (void)testSimpleMatchEndsWithBackward {
	NSRange r = [@"a" ocr_rangeOfString:@"a" options:OCRBackwardSearch|OCREndWith range:NSMakeRange(0,1)];
	XCTAssertTrue(NSEqualRanges(NSMakeRange(0, 1), r), @"got loc:%d len:%d", (int)r.location, (int)r.length);
}

- (void)testSimpleMatchWordBackward {
	NSRange r = [@"a" ocr_rangeOfString:@"a" options:OCRBackwardSearch|OCRStartWith|OCREndWith range:NSMakeRange(0,1)];
	XCTAssertTrue(NSEqualRanges(NSMakeRange(0, 1), r), @"got loc:%d len:%d", (int)r.location, (int)r.length);
}

- (void)testMatchStartsWithBackward {
	NSRange r = [@"a aaaa" ocr_rangeOfString:@"a" options:OCRBackwardSearch|OCRStartWith range:NSMakeRange(0, 6)];
	XCTAssertTrue(NSEqualRanges(NSMakeRange(2, 1), r), @"got loc:%d len:%d", (int)r.location, (int)r.length);
}

- (void)testMatchEndsWithBackward {
	NSRange r = [@"aa a" ocr_rangeOfString:@"a" options:OCRBackwardSearch|OCREndWith range:NSMakeRange(0, 4)];
	XCTAssertTrue(NSEqualRanges(NSMakeRange(3, 1), r), @"got loc:%d len:%d", (int)r.location, (int)r.length);
}

// If the match is entirely in the first piece, then return the match range. diacriticals count as case insensitive.
// Note search World hasbody world have two different diacritical mark
- (void) testSimpleCaseInsensitiveMatchForward {
	NSRange r = [@"in the wörld!" ocr_rangeOfString:@"Wòrld" options:OCRCaseInsensitiveSearch|OCRDiacriticInsensitiveSearch range:NSMakeRange(0, 13)];
	XCTAssertTrue(NSEqualRanges(NSMakeRange(7, 5), r), @"got loc:%d len:%d", (int)r.location, (int)r.length);
}


// If the case-sensitive match is entirely in the first piece, then return the match range.
- (void) testSimpleCaseSensitiveMatchForward {
	NSRange r = [@"in the world!" ocr_rangeOfString:@"World" options:0 range:NSMakeRange(0, 13)];
	NSRange rNotFound = NSMakeRange(NSNotFound, 0);
	XCTAssertTrue(NSEqualRanges(r, rNotFound), @"got loc:%d len:%d", (int)r.location, (int)r.length);
	NSRange r2 = [@"in the worldWorld!" ocr_rangeOfString:@"World" options:OCRBackwardSearch range:NSMakeRange(0, 18)];
	XCTAssertTrue(NSEqualRanges(NSMakeRange(12, 5), r2), @"got loc:%d len:%d", (int)r2.location, (int)r2.length);
}

// If the case-sensitive backward match is entirely in the first piece, then return the match range.
- (void) testSimpleCaseSensitiveMatchBackward {
	NSRange r = [@"in the world!" ocr_rangeOfString:@"World" options:OCRBackwardSearch range:NSMakeRange(0, 13)];
	NSRange rNotFound = NSMakeRange(NSNotFound, 0);
	XCTAssertTrue(NSEqualRanges(rNotFound, r), @"got loc:%d len:%d", (int)r.location, (int)r.length);
	NSRange r2 = [@"in the Worldworld!" ocr_rangeOfString:@"World" options:OCRBackwardSearch range:NSMakeRange(0, 13)];
	XCTAssertTrue(NSEqualRanges(NSMakeRange(7, 5), r2), @"got loc:%d len:%d", (int)r2.location, (int)r2.length);
}

@end
