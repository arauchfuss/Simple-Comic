#import <Cocoa/Cocoa.h>
#import "SS_PreferencePaneProtocol.h"


@interface GeneralPrefController : NSObject <SS_PreferencePaneProtocol> 
{
    IBOutlet NSView * prefsView;
}


@end
