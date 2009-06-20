
#import "AdvancedPrefController.h"


@implementation AdvancedPrefController


+ (NSArray *)preferencePanes
{
    return [NSArray arrayWithObjects: [[[AdvancedPrefController alloc] init] autorelease], nil];
}


- (NSView *)paneView
{
    BOOL loaded = YES;
    
    if (!prefsView) {
        loaded = [NSBundle loadNibNamed: @"AdvancedPrefPaneView" owner: self];
    }
    
    if (loaded) {
        return prefsView;
    }
    
    return nil;
}


- (NSString *)paneIdentifier
{
    return @"Advanced";
}


- (NSString *)paneName
{
    return NSLocalizedString(@"Advanced", @"Advanced Preferences Tab");
}


- (NSImage *)paneIcon
{
    
    return [NSImage imageNamed: @"NSAdvanced"];
}


- (NSString *)paneToolTip
{
    return NSLocalizedString(@"Advanced Preferences", @"Tooltip for Advanced Preferences");
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
