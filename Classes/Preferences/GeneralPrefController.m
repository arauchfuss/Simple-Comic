#import "GeneralPrefController.h"
#import <QuartzCore/QuartzCore.h>

@implementation GeneralPrefController


+ (NSArray *)preferencePanes
{
    return [NSArray arrayWithObjects:[[[GeneralPrefController alloc] init] autorelease], nil];
}


- (NSView *)paneView
{
    BOOL loaded = YES;
    
    if (!prefsView) {
        loaded = [NSBundle loadNibNamed:@"GeneralPrefPaneView" owner:self];
    }
    
    if (loaded) {
        return prefsView;
    }
    
    return nil;
}


- (NSString *)paneIdentifier
{
    return @"General";
}


- (NSString *)paneName
{
    return NSLocalizedString(@"General", @"Main preferences tab");
}


- (NSImage *)paneIcon
{
    return [NSImage imageNamed: @"NSPreferencesGeneral"];
}


- (NSString *)paneToolTip
{
    return NSLocalizedString(@"General Preferences", @"General prefs tooltip");
}


- (BOOL)allowsHorizontalResizing
{
    return NO;
}


- (BOOL)allowsVerticalResizing
{
    return NO;
}


@end
