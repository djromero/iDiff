//
//  GTMNSObject+UnitTesting.m
//  
//  An informal protocol for doing advanced unittesting with objects.
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

#import "GTMImageComparison.h"
#import "GTMGarbageCollection.h"
#import "GTMGeometryUtils.h"
#import <AppKit/AppKit.h>

CGContextRef GTMCreateUnitTestBitmapContextOfSizeWithData(CGSize size,
                                                          unsigned char **data) {
  CGContextRef context = NULL;
  size_t height = size.height;
  size_t width = size.width;
  size_t bytesPerRow = width * 4;
  size_t bitsPerComponent = 8;
  CGColorSpaceRef cs = NULL;
  cs = CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB);
  _GTMDevAssert(cs, @"Couldn't create colorspace");
  CGBitmapInfo info 
    = kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault;
  if (data) {
    *data = (unsigned char*)calloc(bytesPerRow, height);
    _GTMDevAssert(*data, @"Couldn't create bitmap");
  }
  context = CGBitmapContextCreate(data ? *data : NULL, width, height, 
                                  bitsPerComponent, bytesPerRow, cs, info);
  _GTMDevAssert(context, @"Couldn't create an context");
  if (!data) {
    CGContextClearRect(context, CGRectMake(0, 0, size.width, size.height));
  }
  CGContextSetRenderingIntent(context, kCGRenderingIntentRelativeColorimetric);
  CGContextSetInterpolationQuality(context, kCGInterpolationNone);
  CGContextSetShouldAntialias(context, NO);
  CGContextSetAllowsAntialiasing(context, NO);
  CGContextSetShouldSmoothFonts(context, NO);
  CGColorSpaceRelease(cs);
  return context;  
}

// Small utility function for checking to see if a is b +/- 1.
GTM_INLINE BOOL almostEqual(unsigned char a, unsigned char b) {
  unsigned char diff = a > b ? a - b : b - a;
  BOOL notEqual = diff < 2;
  return notEqual;
}

@implementation NSObject (GTMAdditions)
- (CFStringRef)gtm_imageUTI {
  return kUTTypeTIFF;
}

- (NSData*)gtm_imageDataForImage:(CGImageRef)image {
  NSData *data = nil;
  data = [NSMutableData data];
  CGImageDestinationRef dest 
    = CGImageDestinationCreateWithData((CFMutableDataRef)data,
                                       [self gtm_imageUTI],
                                       1,
                                       NULL);
  // LZW Compression for TIFF
  NSDictionary *tiffDict 
    = [NSDictionary dictionaryWithObjectsAndKeys:
       [NSNumber numberWithInt:NSTIFFCompressionLZW],
       (const NSString*)kCGImagePropertyTIFFCompression,
       nil];
  NSDictionary *destProps 
    = [NSDictionary dictionaryWithObjectsAndKeys:
       [NSNumber numberWithFloat:1.0f], 
       (const NSString*)kCGImageDestinationLossyCompressionQuality,
       tiffDict,
       (const NSString*)kCGImagePropertyTIFFDictionary,
       nil];
  CGImageDestinationAddImage(dest, image, (CFDictionaryRef)destProps);
  CGImageDestinationFinalize(dest);
  CFRelease(dest);
  return data;
  
}

- (CGImageRef)gtm_imageWithContentsOfFile:(NSString*)path {
  CGImageRef imageRef = nil;
  CFURLRef url = CFURLCreateWithFileSystemPath(NULL, (CFStringRef)path, 
                                               kCFURLPOSIXPathStyle, NO);
  if (url) {
    CGImageSourceRef imageSource = CGImageSourceCreateWithURL(url, NULL);
    CFRelease(url);
    if (imageSource) {
      imageRef = CGImageSourceCreateImageAtIndex(imageSource, 0, NULL);
      CFRelease(imageSource);
    }
  }
  return (CGImageRef)GTMCFAutorelease(imageRef);
}

- (BOOL)gtm_compareWithImageAt:(NSString*)path diffImage:(CGImageRef*)diff {
  BOOL answer = NO;
  if (diff) {
    *diff = nil;
  }
  CGImageRef fileRep = [self gtm_imageWithContentsOfFile:path];
  _GTMDevAssert(fileRep, @"Unable to create imagerep from %@", path);
  
  CGImageRef imageRep = [(NSImage*)self gtm_unitTestImage];
  _GTMDevAssert(imageRep, @"Unable to create imagerep for %@", self);

  size_t fileHeight = CGImageGetHeight(fileRep);
  size_t fileWidth = CGImageGetWidth(fileRep);
  size_t imageHeight = CGImageGetHeight(imageRep);
  size_t imageWidth = CGImageGetWidth(imageRep);
  if (fileHeight == imageHeight && fileWidth == imageWidth) {
    // if all the sizes are equal, run through the bytes and compare
    // them for equality.
    // Do an initial fast check, if this fails and the caller wants a 
    // diff, we'll do the slow path and create the diff. The diff path
    // could be optimized, but probably not necessary at this point.
    answer = YES;
    
    CGSize imageSize = CGSizeMake(fileWidth, fileHeight);
    CGRect imageRect = CGRectMake(0, 0, fileWidth, fileHeight);
    unsigned char *fileData;
    unsigned char *imageData;
    CGContextRef fileContext 
      = GTMCreateUnitTestBitmapContextOfSizeWithData(imageSize, &fileData);
    _GTMDevAssert(fileContext, @"Unable to create filecontext");
    CGContextDrawImage(fileContext, imageRect, fileRep);
    CGContextRef imageContext
      = GTMCreateUnitTestBitmapContextOfSizeWithData(imageSize, &imageData);
    _GTMDevAssert(imageContext, @"Unable to create imageContext");
    CGContextDrawImage(imageContext, imageRect, imageRep);
    
    size_t fileBytesPerRow = CGBitmapContextGetBytesPerRow(fileContext);
    size_t imageBytesPerRow = CGBitmapContextGetBytesPerRow(imageContext);
    size_t row, col;
    
    _GTMDevAssert(imageWidth * 4 <= imageBytesPerRow, 
                  @"We expect image data to be 32bit RGBA");
    
    for (row = 0; row < fileHeight && answer; row++) {
      answer = memcmp(fileData + fileBytesPerRow * row,
                      imageData + imageBytesPerRow * row,
                      imageWidth * 4) == 0;
    }
    if (!answer && diff) {
      answer = YES;
      unsigned char *diffData;
      CGContextRef diffContext 
        = GTMCreateUnitTestBitmapContextOfSizeWithData(imageSize, &diffData);
      _GTMDevAssert(diffContext, @"Can't make diff context");
      size_t diffRowBytes = CGBitmapContextGetBytesPerRow(diffContext);
      for (row = 0; row < imageHeight; row++) {
        uint32_t *imageRow = (uint32_t*)(imageData + imageBytesPerRow * row);
        uint32_t *fileRow = (uint32_t*)(fileData + fileBytesPerRow * row);
        uint32_t* diffRow = (uint32_t*)(diffData + diffRowBytes * row);
        for (col = 0; col < imageWidth; col++) {
          uint32_t imageColor = imageRow[col];
          uint32_t fileColor = fileRow[col];
          
          unsigned char imageAlpha = imageColor & 0xF;
          unsigned char imageBlue = imageColor >> 8 & 0xF;
          unsigned char imageGreen = imageColor >> 16 & 0xF;
          unsigned char imageRed = imageColor >> 24 & 0xF;
          unsigned char fileAlpha = fileColor & 0xF;
          unsigned char fileBlue = fileColor >> 8 & 0xF;
          unsigned char fileGreen = fileColor >> 16 & 0xF;
          unsigned char fileRed = fileColor >> 24 & 0xF;
          
          // Check to see if color is almost right.
          // No matter how hard I've tried, I've still gotten occasionally
          // screwed over by colorspaces not mapping correctly, and small
          // sampling errors coming in. This appears to work for most cases.
          // Almost equal is defined to check within 1% on all components.
          BOOL equal = almostEqual(imageRed, fileRed) &&
          almostEqual(imageGreen, fileGreen) &&
          almostEqual(imageBlue, fileBlue) &&
          almostEqual(imageAlpha, fileAlpha);
          answer &= equal;
          if (diff) {
            uint32_t newColor;
            if (equal) {
              newColor = (((uint32_t)imageRed) << 24) + 
              (((uint32_t)imageGreen) << 16) + 
              (((uint32_t)imageBlue) << 8) + 
              (((uint32_t)imageAlpha) / 2);
            } else {
              newColor = 0xFF0000FF;
            }
            diffRow[col] = newColor;
          }
        }
      }
      *diff = CGBitmapContextCreateImage(diffContext);
      free(diffData);
      CFRelease(diffContext);
    }       
    free(fileData);
    CFRelease(fileContext);
    free(imageData);
    CFRelease(imageContext);
  }
  return answer;
}
@end

@implementation NSImage (GTMAdditions) 
- (CGImageRef)gtm_unitTestImage {
    // Create up a context
    NSSize size = [self size];
    NSRect rect = GTMNSRectOfSize(size);
    CGSize cgSize = GTMNSSizeToCGSize(size);
    CGContextRef contextRef = GTMCreateUnitTestBitmapContextOfSizeWithData(cgSize,
                                                                           NULL);
    NSGraphicsContext *bitmapContext 
    = [NSGraphicsContext graphicsContextWithGraphicsPort:contextRef flipped:NO];
    _GTMDevAssert(bitmapContext, @"Couldn't create ns bitmap context");
    
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext:bitmapContext];
    [self drawInRect:rect fromRect:rect operation:NSCompositeCopy fraction:1.0];
    
    CGImageRef image = CGBitmapContextCreateImage(contextRef);
    CFRelease(contextRef);
    [NSGraphicsContext restoreGraphicsState];
    return (CGImageRef)GTMCFAutorelease(image);
}

@end
