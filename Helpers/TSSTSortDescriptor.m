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
 
    TSSTSortDescriptor.m
*/


#import "TSSTSortDescriptor.h"


@implementation TSSTSortDescriptor


- (NSComparisonResult)compareObject:(id)object1 toObject:(id)object2
{
	NSString * stringOne = [object1 valueForKeyPath: [self key]];
	NSString * stringTwo = [object2 valueForKeyPath: [self key]];
//	if ([[stringOne pathComponents] count] == 1 && [[stringTwo pathComponents] count] > 1)
//	{
//		return NSOrderedDescending;
//	}
//	else if ([[stringTwo pathComponents] count] == 1 && [[stringOne pathComponents] count] > 1)
//	{
//		return NSOrderedAscending;
//	}
	
	NSStringCompareOptions comparisonOptions = NSCaseInsensitiveSearch | NSNumericSearch | NSWidthInsensitiveSearch | NSForcedOrderingSearch;
    return [stringOne compare: stringTwo options: comparisonOptions];
}


@end

