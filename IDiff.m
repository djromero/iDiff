#include <unistd.h>
#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import "GTMImageComparison.h"

int main (int argc, char * const argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    int dflag = 0;
    int c;
    
    opterr = 0;
    
    while ((c = getopt (argc, argv, "d")) != -1) {
        switch (c) {
            case 'd':
                dflag = 1;
                break;
            default:
                // Ignore unknown options
                break;
        }
    }
    if (argc - optind < 2) {
        printf("Usage: %s [-d] <image A> <image B>\n -d will write the diff image to disk in <image A> directory\n", argv[0]);
        return 2;
    }
    NSString *pathOfImageA = [NSString stringWithCString:argv[optind] encoding:NSUTF8StringEncoding];
    NSString *pathOfImageB = [NSString stringWithCString:argv[optind + 1] encoding:NSUTF8StringEncoding];

    NSImage *imgA = [[NSImage alloc] initWithContentsOfFile:pathOfImageA];
    CGImageRef imgDiff = nil;    
    BOOL aIsEqToB = [imgA gtm_compareWithImageAt:pathOfImageB diffImage:&imgDiff];
    if (!aIsEqToB) {
        NSLog(@"Images are NOT equal.");
        if (1 == dflag && imgDiff) {
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