//
//  XADMaster.h
//  XADMaster
//
//  Created by C.W. Betts on 10/25/15.
//
//

#import <Cocoa/Cocoa.h>

//! Project version number for XADMaster.
FOUNDATION_EXPORT double XADMasterVersionNumber;

//! Project version string for XADMaster.
FOUNDATION_EXPORT const unsigned char XADMasterVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <XADMaster/PublicHeader.h>

#import <XADMaster/XADArchive.h>
#import <XADMaster/CRC.h>

#import <XADMaster/XADAppleDouble.h>
#import <XADMaster/XADDeltaHandle.h>
#import <XADMaster/XADArchiveParserDescriptions.h>
#import <XADMaster/XADCRCHandle.h>
#import <XADMaster/XADMacArchiveParser.h>

//CSHandle
#import <XADMaster/CSBlockStreamHandle.h>
#import <XADMaster/CSByteStreamHandle.h>
#import <XADMaster/CSFileHandle.h>
#import <XADMaster/CSBzip2Handle.h>
#import <XADMaster/CSMemoryHandle.h>
#import <XADMaster/CSMultiHandle.h>
#import <XADMaster/CSZlibHandle.h>
