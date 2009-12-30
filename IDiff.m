#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import "GTMImageComparison.h"

int main (int argc, const char * argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];

    if (argc != 3) {
        printf("Usage: %s <image A> <image B>\n", argv[0]);
        return 2;
    }
    NSString *pathOfImageA = [NSString stringWithCString:argv[1] encoding:NSUTF8StringEncoding];
    NSString *pathOfImageB = [NSString stringWithCString:argv[2] encoding:NSUTF8StringEncoding];

    NSImage *imgA = [[NSImage alloc] initWithContentsOfFile:pathOfImageA];
    CGImageRef imgDiff = nil;    
    BOOL aIsEqToB = [imgA gtm_compareWithImageAt:pathOfImageB diffImage:&imgDiff];
    if (!aIsEqToB) {
        NSLog(@"Images are NOT equal.");
        if (imgDiff) {
            NSData *data = nil;
            NSString *imgDiffPath = [NSString stringWithFormat:@"%@.diff.tiff", pathOfImageA];
            data = [imgA gtm_imageDataForImage:imgDiff];
            if ([data writeToFile:imgDiffPath atomically:YES]) {
                NSLog(@"Saved diff to %@", imgDiffPath);
                printf("%s\n", [imgDiffPath cStringUsingEncoding:NSUTF8StringEncoding]);
            }
        }
        return 1;
    }
    [pool drain];
    NSLog(@"Images are equal.");
    return 0;
}