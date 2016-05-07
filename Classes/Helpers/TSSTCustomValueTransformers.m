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

	TSSTCustomValueTransformers.m
*/

#import "TSSTCustomValueTransformers.h"
#import <QuartzCore/QuartzCore.h>


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
//+ (Class)transformedValueClass
//{
//    return [NSNumber class];
//}
//
//+ (BOOL)allowsReverseTransformation
//{
//    return NO;
//}
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
//@end
