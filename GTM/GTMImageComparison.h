//
//  Extracted from GTMNSObject+UnitTesting.h
//
//  Utilities for doing advanced unittesting with objects.
//
//  Copyright 2006-2008 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License"); you may not
//  use this file except in compliance with the License.  You may obtain a copy
//  of the License at
// 
//  http://www.apache.org/licenses/LICENSE-2.0
// 
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
//  WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.  See the
//  License for the specific language governing permissions and limitations under
//  the License.
//

#import "GTMDefines.h"
#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

#import <ApplicationServices/ApplicationServices.h>

#define ALMOST_EQUAL_THRESHOLD (2)

CGContextRef GTMCreateUnitTestBitmapContextOfSizeWithData(CGSize size, unsigned char **data);

@interface NSObject (GTMAdditions)
- (CFStringRef)gtm_imageUTI;
- (NSData*)gtm_imageDataForImage:(CGImageRef)image;
- (CGImageRef)gtm_imageWithContentsOfFile:(NSString*)path;
- (BOOL)gtm_compareWithImageAt:(NSString*)path diffImage:(CGImageRef*)diff;
@end

@interface NSImage (GTMAdditions)
- (CGImageRef)gtm_unitTestImage;
@end