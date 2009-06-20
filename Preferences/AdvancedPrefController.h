
#import <Cocoa/Cocoa.h>
#import "SS_PreferencePaneProtocol.h"

@interface AdvancedPrefController : NSObject <SS_PreferencePaneProtocol> {

    IBOutlet NSView * prefsView;
    
}

@end
