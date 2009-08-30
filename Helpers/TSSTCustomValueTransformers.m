/*	
	Copyright (c) 2006-2009 Dancing Tortoise Software
 
	Permission is hereby granted, free of charge, to any person 
	obtaining a copy of this software and associated documentation
	files (the "Software"), to deal in the Software without 
	restriction, including without limitation the rights to use, 
	copy, modify, merge, publish, distribute, sublicense, and/or 
	sell copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following 
	conditions:
 
	The above copyright notice and this permission notice shall be
	included in all copies or substantial portions of the Software.
 
	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, 
	EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES 
	OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND 
	NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT 
	HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, 
	WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING 
	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR 
	OTHER DEALINGS IN THE SOFTWARE.
 
	Simple Comic
	TSSTCustomValueTransformers.m
 */


#import "TSSTCustomValueTransformers.h"
#import <QuartzCore/QuartzCore.h>

/*	This function formats modifier flags so that they can be displayed
	for the user to see. */
//static NSString * modifierAsString(unsigned modifiers)
//{
//	NSString * modifierString = @"";
//	
//	if(modifiers & NSCommandKeyMask)
//	{
//		modifierString = [modifierString stringByAppendingFormat: @"%C", 0x2318];
//	}
//	
//	if(modifiers & NSAlternateKeyMask)
//	{
//		modifierString = [modifierString stringByAppendingFormat: @"%C", 0x2325];
//	}
//	
//	if(modifiers & NSControlKeyMask)
//	{
//		modifierString = [modifierString stringByAppendingFormat: @"%C", 0x2303];
//	} 
//	
//	if((modifiers & NSShiftKeyMask))
//	{
//		modifierString = [modifierString stringByAppendingFormat: @"%C", 0x21e7];
//	}
//	
//
//	return modifierString;
//}
//
//
//
//static NSString * prettyKeyboardGlyph(NSString * character)
//{
//	if([character length] < 1)
//	{
//		return @"";
//	}
//	
//	unsigned firstCharacter = [character characterAtIndex: 0];
//	NSString * prettyString;
//	switch(firstCharacter)
//	{
//		case NSEnterCharacter: 
//			prettyString = [NSString stringWithFormat: @"%C", 0x2305]; 
//			break;
//		case NSBackspaceCharacter: 
//			prettyString = [NSString stringWithFormat: @"%C", 0x232b];
//			break;
//		case NSTabCharacter:
//			prettyString = [NSString stringWithFormat: @"%C", 0x21e5];
//			break;
//		case NSCarriageReturnCharacter: 
//			prettyString = [NSString stringWithFormat: @"%C", 0x21a9];
//			break;
//		case NSBackTabCharacter: 
//			prettyString = [NSString stringWithFormat: @"%C", 0x21e4];
//			break;
//		case 27:
//			prettyString = [NSString stringWithFormat: @"%C", 0x238b];	// Escape
//			break;
//		case 32: 			
//			prettyString = [NSString stringWithFormat: @"%C", 0x2420];	// Space
//			break;
//		case NSDeleteCharacter: 
//			prettyString = [NSString stringWithFormat:@"%C", 0x2326];
//			break;
//		case NSUpArrowFunctionKey: 
//			prettyString = [NSString stringWithFormat:@"%C", 0x2191];
//			break;
//		case NSDownArrowFunctionKey: 
//			prettyString = [NSString stringWithFormat:@"%C", 0x2193];
//			break;
//		case NSLeftArrowFunctionKey: 
//			prettyString = [NSString stringWithFormat:@"%C", 0x2190];
//			break;
//		case NSRightArrowFunctionKey: 
//			prettyString = [NSString stringWithFormat:@"%C", 0x2192];
//			break;
//		case NSF1FunctionKey: 
//			prettyString = @"F1";
//			break;
//		case NSF2FunctionKey: 
//			prettyString = @"F2";
//			break;
//		case NSF3FunctionKey: 
//			prettyString = @"F3";
//			break;
//		case NSF4FunctionKey: 
//			prettyString = @"F4";
//			break;
//		case NSF5FunctionKey: 
//			prettyString = @"F5";
//			break;
//		case NSF6FunctionKey: 
//			prettyString = @"F6";
//			break;
//		case NSF7FunctionKey: 
//			prettyString = @"F7";
//			break;
//		case NSF8FunctionKey: 
//			prettyString = @"F8";
//			break;
//		case NSF9FunctionKey: 
//			prettyString = @"F9";
//			break;
//		case NSF10FunctionKey: 
//			prettyString = @"F10";
//			break;
//		case NSF11FunctionKey: 
//			prettyString = @"F11";
//			break;
//		case NSF12FunctionKey: 
//			prettyString = @"F12";
//			break;
//		case NSF13FunctionKey: 
//			prettyString = @"F13";
//			break;
//		case NSF14FunctionKey: 
//			prettyString = @"F14";
//			break;
//		case NSF15FunctionKey: 
//			prettyString = @"F15";
//			break;
//		case NSInsertFunctionKey: 
//			prettyString = [NSString stringWithFormat: @"%C", 0x2380];
//			break;
//		case NSDeleteFunctionKey:
//			prettyString = [NSString stringWithFormat:@"%C", 0x2326];
//			break;
//		case NSHomeFunctionKey: 
//			prettyString = [NSString stringWithFormat:@"%C", 0x2196];
//			break;
//		case NSEndFunctionKey: 
//			prettyString = [NSString stringWithFormat:@"%C", 0x2198];
//			break;
//		case NSPageUpFunctionKey: 
//			prettyString = [NSString stringWithFormat:@"%C", 0x21de];
//			break;
//		case NSPageDownFunctionKey: 
//			prettyString = [NSString stringWithFormat:@"%C", 0x21df];
//			break;
//		default: 
//			prettyString = [character uppercaseString];
//			break;
//	}
//	
//	return prettyString;
//}
//

@implementation TSSTLastPathComponent



+ (Class)transformedValueClass
{
    return [NSString class];
}



+ (BOOL)allowsReverseTransformation
{
    return NO;
}


- (id)transformedValue:(NSString*)beforeObject
{
	if(!beforeObject)
		return nil;

    return [beforeObject lastPathComponent];
}

@end



//@implementation TSSTHumanReadableIndex
//
//
//+ (Class)transformedValueClass
//{
//    return [NSNumber class];
//}
//
//
//
//+ (BOOL)allowsReverseTransformation
//{
//    return NO;
//}
//
//
//- (id)transformedValue:(NSNumber *)rawValue
//{
//	if(!rawValue)
//	{
//		return nil;
//	}
//    
//    NSInteger index = [rawValue intValue];
//    index = (index == NSNotFound) ? 0 : index + 1;
//
//    return [NSNumber numberWithInt: index];
//}
//
//
//@end
//
//
//
//@implementation TSSTFormattedKeyEquivalent
//
//
//+ (Class)transformedValueClass
//{
//    return [NSDictionary class];
//}
//
//
//+ (BOOL)allowsReverseTransformation
//{
//    return NO;
//}
//
//
//- (id)transformedValue:(NSDictionary *)beforeObject
//{
//	if(!beforeObject)
//	{
//		return nil;
//	}
//    
//	NSDictionary * defaultValues = [[NSUserDefaultsController sharedUserDefaultsController] values];
//	NSString * preferenceKey = [beforeObject objectForKey: @"preferenceKey"];
//	NSDictionary * keyDefaults = [defaultValues valueForKey: preferenceKey];
//	
//	unsigned modifier = [[keyDefaults objectForKey: @"menuModifierKey"] unsignedIntValue];
//	NSString * textValue = modifierAsString(modifier);
//	
//	NSString * keyString = [keyDefaults objectForKey: @"menuKeyEquivalent"];
//	textValue = [textValue stringByAppendingString: prettyKeyboardGlyph(keyString)];
//
//    return textValue;
//}
//
//
//@end
//


