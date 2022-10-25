//  OCRFind.m
//
//  Created by David Phillip Oster on 6/10/22. license.txt applies.
//

#import "OCRFind.h"
#import "OCRFindViewController.h"
#import "OCRRangeEnumerator.h"
#import "OCRTracker.h"
#import <Vision/Vision.h>

// Use same keys as NSTextFinder.
static NSString *const OCRIgnoreCaseKey = @"canIgnoreCase";
static NSString *const OCRWrapAroundKey = @"canWrapAround";
static NSString *const OCRSearchKindKey = @"searchKind";

// Keep this in sync with the enum definition.
static OCRStringCompareOptions CompareOptionsFromInteger(NSInteger i) {
	switch (i) {
		case 2: return OCRStartWith;
		case 1: return OCRStartWith | OCREndWith;
		default:  return 0;
	}
}

static NSInteger IntegerFromCompareOptions(OCRStringCompareOptions options) {
	if ((options & (OCRStartWith|OCREndWith)) == (OCRStartWith | OCREndWith)){ return 1; }
	if ((options & (OCRStartWith|OCREndWith)) == (OCRStartWith)){ return 2; }
	return 0;
}

typedef NS_OPTIONS(NSUInteger, OCRIndicator) {
	OCRIndicatorNotFound,
	OCRIndicatorWrap,
	OCRIndicatorBackWrap,
};

@interface OCRFind() <OCRFindEngine>

@property(nonatomic) OCRFindViewController *findVC;

@end

@implementation OCRFind
@synthesize findString = _findString;
@synthesize options = _options;
@synthesize wrap = _wrap;
@synthesize findState = _findState;

+ (void)initialize
{
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		[[NSUserDefaults standardUserDefaults] registerDefaults:  @{
			OCRIgnoreCaseKey : @YES,
			OCRWrapAroundKey : @YES,
		}];
	});
}

- (instancetype)init
{
	self = [super init];
	if (self) {
		[self readFindBoard];
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(becameActive:) name:NSApplicationDidBecomeActiveNotification object:NSApp];
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		self.options = CompareOptionsFromInteger([defaults integerForKey:OCRSearchKindKey]);
		self.options |= OCRCaseInsensitiveSearch;	// Always case insensitive.
		self.wrap = [defaults boolForKey:OCRWrapAroundKey];
	}
	return self;
}

- (void)becameActive:(NSNotification *)notify {
	[self readFindBoard];
}

- (void)setWrap:(BOOL)wrap {
	if (_wrap != wrap) {
		_wrap = wrap;
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setBool:wrap forKey:OCRWrapAroundKey];
	}
}

- (void)setOptions:(OCRStringCompareOptions)options
{
	if (_options != options) {
		options |= OCRCaseInsensitiveSearch;	// Always case insensitive.
		_options = options;

		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		[defaults setBool:0 != (OCRCaseInsensitiveSearch & options) forKey:OCRIgnoreCaseKey];
		[defaults setInteger:IntegerFromCompareOptions(self.options) forKey:OCRSearchKindKey];
	}
}

- (void)setFindState:(OCRFindState)findState
{
	if (_findState != findState) {
		_findState = findState;
		if (findState == OCRFindStateCanceling) {
			[self.delegate cancelObservations];
		}
		[_findVC updateFindState];
	}
}

- (OCRFindViewController *)findVC
{
	if (_findVC == nil)
	{
		_findVC = [[OCRFindViewController alloc] initWithNibName:@"OCRFindViewController" bundle:nil];
		_findVC.engine = self;
	}
	return _findVC;
}

- (OCRTracker *)tracker
{
	return self.delegate.tracker;
}

- (id<NSTextFinderBarContainer>)findBarContainer
{
	return self.delegate.findBarContainer;
}


- (void)scrollRangeToVisible:(NSRange)range
{
	if (@available(macOS 10.15, *))
	{
		[self.tracker scrollFindRangeToVisible:range];
	}
}

- (NSString *)expanded
{
	return [self.tracker allTextJoinedBy:@" "];
}

- (NSString *)selection
{
	return [self.tracker selectionJoinedBy:@" "];
}

- (NSString *)expandPieces:(NSArray<VNRecognizedTextObservation *> *)pieces API_AVAILABLE(macos(10.15))
{
	NSMutableArray *a = [NSMutableArray array];
	for (VNRecognizedTextObservation *piece in pieces) {
		NSArray<VNRecognizedText *> *text1 = [piece topCandidates:1];
		[a addObject:text1.firstObject.string];
	}
	return [a componentsJoinedByString:@" "];
}

- (BOOL)range:(NSRange)r inRanges:(NSArray<NSValue *> *)ranges
{
	if (r.length == 0 || r.location == NSNotFound) {
		return NO;
	}
	for (NSValue *v in ranges) {
		NSRange candidate = [v rangeValue];
		if (NSLocationInRange(r.location, candidate) || NSLocationInRange(r.location + r.length -1, candidate)) {
			return YES;
		}
	}
	return NO;
}


- (void)find:(NSString *)findString
	 options:(OCRStringCompareOptions)options
  enumerator:(OCRRangeEnumerator *)rangeEnumerator
findCompletion:(void (^)(NSInteger index, NSRange r, NSArray<VNRecognizedTextObservation *> *pieces))findCompletion API_AVAILABLE(macos(10.15))
{
	NSUInteger current = [rangeEnumerator next];
	if (current != NSNotFound && self.findState == OCRFindStateInProgress) {
		[self.findVC setFindProgressPageIndex:current];
		[self.delegate observationsForFindIndex:current completion:^(NSArray<VNRecognizedTextObservation *> *pieces) {
			NSString *s = [self expandPieces:pieces];
			NSRange findRange = NSMakeRange(0, s.length);
			NSRange r = [s ocr_rangeOfString:findString options:options range:findRange];
			if (r.location != NSNotFound) {
				findCompletion(current, r, pieces);
			} else {
				dispatch_async(dispatch_get_main_queue(), ^{
					[self find:findString options:options enumerator:rangeEnumerator findCompletion:findCompletion];
				});
			}
		}];
	} else {
		findCompletion(current, NSMakeRange(NSNotFound, 0), @[]);
	}
}

- (void)didHideFindBar
{
	NSView *view = self.tracker.view;
	if ([view acceptsFirstResponder]) {
		[view.window makeFirstResponder:view];
	}
}

- (void)didNotFind
{
	self.findState = OCRFindStateIdle;
	[self flashImage:@"OCRNotFound"];
}

- (void)didFindIndex:(NSUInteger)index range:(NSRange)r API_AVAILABLE(macos(10.15))
{
	if (self.findState == OCRFindStateInProgress) {
		[self.delegate setFindIndex:index];
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.15 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[self.tracker setSelectedFindRange:r];
			[self.tracker scrollFindRangeToVisible:r];
		});
	}
	self.findState = OCRFindStateIdle;
}

- (void)find:(NSString *)findString
	 options:(OCRStringCompareOptions)options
 anchorIndex:(NSInteger)anchorIndex
anchorRanges:(NSArray<NSValue *> *)anchorRanges
	   start:(NSInteger)start
		 end:(NSInteger)end
		wrap:(BOOL)wrap
{
	NSInteger count = self.delegate.findCount;

	if (wrap) {
		NSInteger findCount = self.delegate.findCount;
		// if search should wrap, but we are already at the extreme, treat as no-wrap from other extreme.
		if (start == -1 && end == 0 && anchorIndex == 0 && (options & OCRBackwardSearch)) {
			start = findCount - 1;
			wrap = NO;
		} else if (start == findCount && end == findCount - 1 && anchorIndex == findCount - 1 && !(options & OCRBackwardSearch)) {
			start = 0;
			wrap = NO;
		}
	}
	if (start < 0 || end < 0 || count <= start || count <= end) {
		[self didNotFind];
		return;
	}
	if (@available(macOS 10.15, *)) {
		NSInteger increment = ((options & OCRBackwardSearch) ? -1 : 1);
		OCRRangeEnumerator *rangeEnumerator = [[OCRRangeEnumerator alloc] initWithStart:start end:end increment:increment];
		__weak typeof(self) weakSelf = self;
		[weakSelf find:findString options:options enumerator:rangeEnumerator findCompletion:
			 ^(NSInteger index, NSRange r, NSArray<VNRecognizedTextObservation *> *pieces)
		 {
			if (index != NSNotFound) {
				[weakSelf didFindIndex:index range:r];
			} else if (wrap) {
				NSInteger start1 = (options & OCRBackwardSearch) ? self.delegate.findCount - 1 : 0;
				NSInteger end1 = anchorIndex;
				[self flashImage:(options & OCRBackwardSearch) ? @"OCRBackWrap" : @"OCRWrap"];
				OCRRangeEnumerator *rangeEnumerator1 = [[OCRRangeEnumerator alloc] initWithStart:start1 end:end1 increment:increment];
				[weakSelf find:findString options:options enumerator:rangeEnumerator1 findCompletion:
					 ^(NSInteger index, NSRange r, NSArray<VNRecognizedTextObservation *> *pieces)
				 {
					if (index != NSNotFound) {
						[weakSelf didFindIndex:index range:r];
					} else {
						[weakSelf didNotFind];
					}
				}
				];
			} else {
				[weakSelf didNotFind];
			}
		}
		];
	}
}


- (void)find:(NSString *)findString options:(OCRStringCompareOptions)options wrap:(BOOL)wrap
{
	if ([[NSUserDefaults standardUserDefaults] boolForKey:OCRDisableKey]) {
		return;
	}
	if (findString.length == 0) {
		return;
	}
	if (@available(macOS 10.15, *)) {
		self.findState = OCRFindStateInProgress;
		NSString *expanded = self.expanded;
		NSRange findRange = NSMakeRange(0, expanded.length);
		NSInteger anchorIndex = self.delegate.findIndex;
		NSArray<NSValue *> *anchorRanges = self.tracker.selectedFindRanges;
		if (anchorRanges.count) {
			if (options & OCRBackwardSearch) {
				findRange.length = MIN(findRange.length, anchorRanges.firstObject.rangeValue.location);
			} else {
				NSRange last = anchorRanges.lastObject.rangeValue;
				NSInteger prefixLength = last.location + last.length;
				findRange.location += prefixLength;
				findRange.length -= MIN(findRange.length, prefixLength);
			}
		}
		// Sanity check:
		NSRange r = findRange.length ?
			[expanded ocr_rangeOfString:findString options:options range:findRange] :
			NSMakeRange(NSNotFound, 0);
		// result is in expanded units. Convert to compressed units. Set the selection.
		if (r.location != NSNotFound) {
			if (self.findState == OCRFindStateInProgress) {
				[self.tracker setSelectedFindRange:r];
				[self.tracker scrollFindRangeToVisible:r];
			}
			self.findState = OCRFindStateIdle;
		} else {
			NSInteger start = anchorIndex + ((options & OCRBackwardSearch) ? -1 : 1);
			NSInteger end = (options & OCRBackwardSearch) ? 0 : self.delegate.findCount - 1;
			[self find:findString options:options anchorIndex:anchorIndex anchorRanges:anchorRanges start:start end:end wrap:wrap];
		}
	}
}

- (void)flashImage:(NSString *)name
{
	NSView *scrollView = (NSView *)self.findBarContainer;
	if ([scrollView isKindOfClass:[NSView class]]) {
		NSImageView *wrapView = [[NSImageView alloc] initWithFrame:CGRectMake(0, 0, 128, 128)];
		[wrapView setImage:[NSImage imageNamed:name]];
		CGRect bounds = scrollView.bounds;
		CGPoint center = CGPointMake(bounds.origin.x + bounds.size.width/2, bounds.origin.y + bounds.size.height/2);
		wrapView.frame = CGRectMake(center.x - 128/2, center.y - 128/2, 128, 128);
		wrapView.alphaValue = 0;
		[scrollView addSubview:wrapView];
		[[wrapView animator] setAlphaValue:0.8];
		dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
			[[wrapView animator] setAlphaValue:0.];
			dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
				[wrapView removeFromSuperview];
			});
		});
	}
}

- (void)readFindBoard {
	NSPasteboard *findBoard = [NSPasteboard pasteboardWithName:NSFindPboard];
	NSString *bestType = [findBoard availableTypeFromArray:@[NSStringPboardType]];
	if ([bestType isEqual:NSStringPboardType]) {
		[self setFindString:[findBoard stringForType:NSStringPboardType]];
	}
}

- (void)setFindString:(NSString *)findString {
	if (![self.findString isEqual:findString]) {
		_findString = [findString copy];
		if (findString.length != 0) {
			NSPasteboard *findBoard = [NSPasteboard pasteboardWithName:NSFindPboard];
			[findBoard clearContents];
			[findBoard declareTypes:[NSArray arrayWithObject:NSStringPboardType] owner:nil];
			[findBoard setString:findString forType:NSStringPboardType];
		}
		[self.findVC updateFindString];
	}
}

- (void)setFindStringFromSelection:(NSString *)findString
{
	if (512 < findString.length) {
		findString = [findString substringToIndex:512];
	}
	self.findString = findString;
}

- (void)performAction:(NSTextFinderAction)op {
	switch (op) {
		case NSTextFinderActionShowFindInterface:
			[self.findVC showFind:nil];
			break;
		case NSTextFinderActionNextMatch:
			[self find:self.findString options:self.options wrap:self.wrap];
			break;
		case NSTextFinderActionPreviousMatch:
			[self find:self.findString options:self.options | OCRBackwardSearch wrap:self.wrap];
			break;
		case NSTextFinderActionSetSearchString:
			[self setFindStringFromSelection:self.selection];
			break;
		case NSTextFinderActionHideFindInterface:
			[self.findVC cancelOperation:nil];
			break;
		default:
			break;
	}
}

- (BOOL)validateAction:(NSTextFinderAction)op {
	switch (op) {
		case NSTextFinderActionShowFindInterface:
			return YES;
		case NSTextFinderActionNextMatch:
		case NSTextFinderActionPreviousMatch:
			return self.findVC != nil && self.findString.length != 0;
		case NSTextFinderActionSetSearchString:
			return self.selection.length != 0;
		case NSTextFinderActionHideFindInterface:
			return YES;
		default:
			return NO;
	}
}

@end
