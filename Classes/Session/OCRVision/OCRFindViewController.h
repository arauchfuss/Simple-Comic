//  OCRFindViewController.h
//
//  Created by David Phillip Oster on 6/9/22. license.txt applies.

#import <Cocoa/Cocoa.h>

#import "OCR_NSString.h"

NS_ASSUME_NONNULL_BEGIN

@protocol OCRFindEngine;

/// UI for \c OCRFind
@interface OCRFindViewController : NSViewController

/// Provides requirements of the \c OCRFindViewController
@property (nullable, weak) id <OCRFindEngine> engine;

/// setting findPageIndex shows it in the find progress panel.
@property (nonatomic) NSUInteger findProgressPageIndex;

/// Show this viewController.
- (IBAction)showFind:(nullable id)sender;

/// Hide this viewController.
- (IBAction)cancelOperation:(nullable id)sender;

/// Update the shown selection and the next/previous buttons.
- (void)updateFindString;

/// Update the enable state: disable changes while a find is in progress.
- (void)updateFindState;

@end

typedef NS_OPTIONS(NSUInteger, OCRFindState) {
	OCRFindStateIdle,
	OCRFindStateInProgress,
	OCRFindStateCanceling
};

/// Provides requirements of the OCRFindViewController
@protocol OCRFindEngine <NSObject>

/// Search options, shown in the OCRFindViewController's popup menu on the magnifying glass.
@property(nonatomic) OCRStringCompareOptions options;

/// YES, then the search wrap around the whole document. (In the OCRFindViewController's popup menu)
@property(nonatomic) BOOL wrap;

/// OCRFindStateInProgress, then already doing one find operation. Changes must wait. Calls OCRFindViewController's updateFindState
@property(nonatomic) OCRFindState findState;

/// The view that will hold the OCRFindViewController's view. (NSScrollViews implement this protocol)
@property(readonly) id <NSTextFinderBarContainer> findBarContainer;

/// The string that we'll find. OCRFindViewController both gets and sets this
@property(nonatomic) NSString *findString;

/// The selected text in the current page.
@property(readonly) NSString *selection;

/// Does all the actual finding.
- (void)find:(NSString *)findString options:(OCRStringCompareOptions)options wrap:(BOOL)wrap;

/// OCRFindViewController calls this to let it know the find view is hidden.
- (void)didHideFindBar;

@end

NS_ASSUME_NONNULL_END
