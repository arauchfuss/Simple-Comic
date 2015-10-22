#import <Cocoa/Cocoa.h>


@protocol SS_PreferencePaneProtocol


    //	preferencePanes is called whenever the calling application wants to instantiate preference panes.
    //	This method returns an array of preference pane instances. This array is autoreleased,
    //	so the calling application needs to retain whatever it wants to keep.
    //	If no instances were generated, this returns nil.

+ (NSArray *)preferencePanes;


    //	paneView returns a preference pane's view. This must not be nil.

- (NSView *)paneView;


    //	paneName returns the name associated with a preference pane's view.
    //	This is used as the label of the pane's toolbar item in the Preferences window,
    //	and as the title of the Preferences window when the pane is selected.
    //	This must not be nil or an empty string.

- (NSString *)paneName;

- (NSString *)paneIdentifier;

    //  paneIcon returns a preference pane's icon as an NSImage.
    //	The icon will be scaled to the default size for a toolbar icon (if necessary),
    //	and shown in the toolbar in the Preferences window.

- (NSImage *)paneIcon;


    //  paneToolTip returns the ToolTip to be used for a preference pane's icon in the
    //	Preferences window's toolbar. You can return nil or an empty string to disable
    //	the ToolTip for this preference pane.

- (NSString *)paneToolTip;


    //  allowsHorizontalResizing and allowsVerticalResizing determine whether the Preferences window
    //	will be resizable in the respective directions when the receiver is the visible preference
    //	pane. The initial size of the receiver's view will be used as the minimum size of the
    //	Preferences window.

- (BOOL)allowsHorizontalResizing;
- (BOOL)allowsVerticalResizing;

@end
