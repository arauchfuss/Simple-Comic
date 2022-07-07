//  OCRFindViewController.m
//
//  Created by David Phillip Oster on 6/9/22. license.txt applies.
//

#import "OCRFindViewController.h"

#import "OCRTracker.h" // for OCRDisableKey


@interface OCRFindViewController () <NSSearchFieldDelegate>

@property (weak) IBOutlet NSSearchField *searchField;
@property (weak) IBOutlet NSSegmentedControl *forwardBack;
@property (weak) NSMenu *findOptionsMenu;
@property (weak) IBOutlet NSPanel *cancelPanel;
@property (weak) IBOutlet NSTextField *progressField;
@property BOOL showingCancelPanel;

- (void)findOption:(NSMenuItem *)sender;

@end

/// Sits on top of the magnifiying glass icon to serve as the root of the Find Options menu.
@interface OCRFindMenuRoot : NSView
@property(weak) OCRFindViewController *textFinder;
@end

@implementation OCRFindMenuRoot

- (void)drawRect:(NSRect)dirtyRect
{
	CGRect r = self.bounds;
	r.origin.x = 18;
	r.origin.y = 12;
	r.size.width = 6;
	r.size.height = 6;
	NSImage *down = [NSImage imageNamed:@"OCRDown"];
	[down drawInRect:r];
}

- (void)findOption:(NSMenuItem *)sender
{
	[self.textFinder findOption:sender];
}

- (void)mouseDown:(NSEvent *)theEvent
{
	[NSMenu popUpContextMenu:self.menu withEvent:theEvent forView:self];
}

- (void)resetCursorRects
{
	[self addCursorRect: [self bounds] cursor:[NSCursor arrowCursor]];
}

@end



@implementation OCRFindViewController

- (void)awakeFromNib {
	[super awakeFromNib];
	self.searchField.nextResponder = self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	NSVisualEffectView *effectView = [[NSVisualEffectView alloc] initWithFrame:self.view.bounds];
	[effectView addSubview:self.view];
	effectView.autoresizingMask = NSViewWidthSizable | NSViewHeightSizable;
	effectView.blendingMode = NSVisualEffectBlendingModeWithinWindow;
	if (@available(macOS 10.14, *)) {
		effectView.material = NSVisualEffectMaterialHeaderView;
	} else {
		effectView.material = NSVisualEffectMaterialSelection;
	}
	self.view = effectView;
	[self.searchField addSubview:[self constructMenuRoot]];
	if (self.engine.findString) {
		self.searchField.stringValue = self.engine.findString;
	}

	[self updateFindOptionsMenu];
	[self updateForwardBack];
}

- (NSView *)constructMenuRoot
{
	CGRect frame = self.searchField.bounds;
	frame.size.width = frame.size.height + 4;
	OCRFindMenuRoot *menuRoot = [[OCRFindMenuRoot alloc] initWithFrame:frame];
	menuRoot.textFinder = self;
	NSMenu *findOptionsMenu = [[NSMenu alloc] initWithTitle:@""];
	NSArray *items = @[
		[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Ignore Case", @"") action:@selector(findOption:) keyEquivalent:@""],
		[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Wrap around", @"") action:@selector(findOption:) keyEquivalent:@""],
		[NSMenuItem separatorItem],
		[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Contains", @"") action:@selector(findOption:) keyEquivalent:@""],
		[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Starts with", @"") action:@selector(findOption:) keyEquivalent:@""],
		[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Full Word", @"") action:@selector(findOption:) keyEquivalent:@""],
	];
	NSInteger tag = 1;
	for (NSMenuItem *item in items) {
		if (![item.title isEqual:@""]) {
			item.tag = tag++;
		}
	}
	for (NSMenuItem *item in items) {
		[findOptionsMenu addItem:item];
	}
	findOptionsMenu.font = [NSFont systemFontOfSize:[NSFont smallSystemFontSize]];
	menuRoot.menu = findOptionsMenu;
	self.findOptionsMenu = findOptionsMenu;
	return menuRoot;
}

- (void)updateFindOptionsMenu {
	NSMenuItem *ignoreCase = [self.findOptionsMenu itemWithTag:1];
	ignoreCase.state = (self.engine.options & OCRCaseInsensitiveSearch) ? NSControlStateValueOn : NSControlStateValueOff;
	NSMenuItem *wrap = [self.findOptionsMenu itemWithTag:2];
	wrap.state = self.engine.wrap ? NSControlStateValueOn : NSControlStateValueOff;
	NSMenuItem *contains = [self.findOptionsMenu itemWithTag:3];
	contains.state = ((self.engine.options & (OCRStartWith | OCREndWith)) == 0) ? NSControlStateValueOn : NSControlStateValueOff;
	NSMenuItem *starts = [self.findOptionsMenu itemWithTag:4];
	starts.state = ((self.engine.options & (OCRStartWith | OCREndWith)) == OCRStartWith) ? NSControlStateValueOn : NSControlStateValueOff;
	NSMenuItem *full = [self.findOptionsMenu itemWithTag:5];
	full.state = ((self.engine.options & (OCRStartWith | OCREndWith)) == (OCRStartWith | OCREndWith)) ? NSControlStateValueOn : NSControlStateValueOff;
}

- (void)updateFindState
{
	OCRFindState findState = self.engine.findState;
	if (findState == OCRFindStateIdle) {
		if (self.showingCancelPanel) {
			self.showingCancelPanel = NO;
			NSView *container = (NSView *)self.engine.findBarContainer;
			[container.window endSheet: self.cancelPanel returnCode: NSModalResponseAbort];
		}
	}
	self.searchField.enabled = (findState == OCRFindStateIdle);
	[self updateFindString];
	[self updateForwardBack];
}

- (void)setFindProgressPageIndex:(NSUInteger)findPageIndex
{
	if (_findProgressPageIndex != findPageIndex) {
		self.progressField.integerValue = findPageIndex+1;
		NSView *container = (NSView *)self.engine.findBarContainer;
		if (!self.showingCancelPanel) {
			self.showingCancelPanel = YES;
			[container.window beginSheet:self.cancelPanel completionHandler:^(NSModalResponse returnCode) {
				[self.cancelPanel close];
			}];
		}
	}
}

- (IBAction)performOCRFindAction:(id)sender
{
	[self performAction:[sender tag]];
}

- (void)performAction:(NSTextFinderAction)op {
	switch (op) {
		case NSTextFinderActionShowFindInterface:
			[self showFind:nil];
			break;
		case NSTextFinderActionNextMatch:
			[self next:nil];
			break;
		case NSTextFinderActionPreviousMatch:
			[self previous:nil];
			break;
		case NSTextFinderActionSetSearchString: {
				NSString *selection = self.engine.selection;
				self.engine.findString = [selection substringToIndex:MIN(512, selection.length)];
			}
			break;
		case NSTextFinderActionHideFindInterface:
			[self cancelOperation:nil];
			break;
		default:
			break;
	}
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem
{
	if ([menuItem action] == @selector(performOCRFindAction:))
	{
		return [self validateAction:[menuItem tag]];
	}
	return NO;
}

- (BOOL)validateAction:(NSTextFinderAction)op {
	switch (op) {
		case NSTextFinderActionShowFindInterface:
			return YES;
		case NSTextFinderActionNextMatch:
		case NSTextFinderActionPreviousMatch:
			return self.engine.findState == OCRFindStateIdle && self.engine.findString.length != 0;
		case NSTextFinderActionSetSearchString:
			return self.engine.findState == OCRFindStateIdle && self.engine.selection.length != 0;
		case NSTextFinderActionHideFindInterface:
			return YES;
		default:
			return NO;
	}
}

- (void)controlTextDidChange:(NSNotification *)note {
	if (self.engine.findState == OCRFindStateIdle && note.object == self.searchField) {
		self.engine.findString = self.searchField.stringValue;
		[self updateForwardBack];
	}
}

- (void)updateFindString
{
	if (self.engine.findState == OCRFindStateIdle && ![self.searchField.stringValue isEqual:self.engine.findString])
	{
		self.searchField.stringValue = self.engine.findString;
		[self updateForwardBack];
	}
}


- (void)updateForwardBack
{
	self.forwardBack.enabled = ![[NSUserDefaults standardUserDefaults] boolForKey:OCRDisableKey] &&
		self.engine.findState == OCRFindStateIdle &&
		(self.searchField.stringValue.length != 0);
}

- (void)showFind:(id)sender
{
	self.engine.findBarContainer.findBarView = self.view;
	CGRect bounds = self.view.bounds;
	bounds.size.width = MAX(100, self.engine.findBarContainer.findBarView.bounds.size.width);
	self.view.bounds = bounds;
	self.engine.findBarContainer.findBarVisible = YES;
	[self.view.window makeFirstResponder:self.searchField];
}

- (IBAction)segmentedControlTapped:(id)sender
{
	switch([sender selectedSegment]){
		case 0:
			[self previous:nil];
			break;
		case 1:
			[self next:nil];
			break;
		default:
			break;
	}
}

- (void)findOption:(NSMenuItem *)sender
{
	if ([sender isKindOfClass:[NSMenuItem class]]) {
		switch([sender tag]){
			case 1: self.engine.options ^= OCRCaseInsensitiveSearch; break;
			case 2: self.engine.wrap = !self.engine.wrap; break;
			case 3: self.engine.options &= ~(OCRStartWith|OCREndWith); break;
			case 4: self.engine.options = (self.engine.options & ~OCREndWith) | OCRStartWith; break;
			case 5: self.engine.options |= (OCRStartWith|OCREndWith); break;
			default:
				break;
		}
		[self updateFindOptionsMenu];
	}
}

// NSResponder binds the 'Escape' key to cancelOperation:
- (IBAction)cancelOperation:(id)sender
{
	if (self.engine.findState == OCRFindStateIdle) {
		self.engine.findBarContainer.findBarVisible = NO;
		[self.engine didHideFindBar];
	} else if (self.engine.findState == OCRFindStateInProgress) {
		[self cancelFind:nil];
	}
}

- (IBAction)nextOnEnter:(id)sender
{
	if (self.searchField.stringValue.length) {
		[self next:sender];
	}
}

- (IBAction)next:(id)sender
{
	if (self.engine.findState == OCRFindStateIdle) {
		if (self.searchField) {
			self.engine.findString = self.searchField.stringValue;
		}
		[self.engine find:self.engine.findString options:self.engine.options wrap:self.engine.wrap];
	}
}

- (IBAction)previous:(id)sender
{
	if (self.engine.findState == OCRFindStateIdle) {
		if (self.searchField) {
			self.engine.findString = self.searchField.stringValue;
		}
		[self.engine find:self.engine.findString options:self.engine.options | OCRBackwardSearch  wrap:self.engine.wrap];
	}
}

- (IBAction)cancelFind:(id)sender
{
	if (self.engine.findState == OCRFindStateInProgress)
	{
		self.engine.findState = OCRFindStateCanceling;
	}
	NSView *container = (NSView *)self.engine.findBarContainer;
	if (self.showingCancelPanel) {
		self.showingCancelPanel = NO;
		[container.window endSheet: self.cancelPanel returnCode: NSModalResponseAbort];
	}
}

@end
