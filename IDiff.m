#include <unistd.h>
#import <Cocoa/Cocoa.h>
#import <Foundation/Foundation.h>
#import "GTMImageComparison.h"

int main (int argc, char * const argv[]) {
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    int dflag = 0; // save diff image 
    int vflag = 0; // verbose output
    int c;
    
    opterr = 0;
    
    // Flags: -d -v
    while ((c = getopt (argc, argv, "dv")) != -1) {
        switch (c) {
            case 'd':
                dflag = 1;
                break;
            case 'v':
                vflag = 1;
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
    int numberOfDiffs = [imgA gtm_compareWithImageAt:pathOfImageB diffImage:&imgDiff];
    if (numberOfDiffs > 0) {
        NSLog(@"Images are NOT equal. Found %i diffs.", numberOfDiffs);
        NSData *data = nil;
        NSString *imgDiffPath = @"-";
        if (1 == dflag && imgDiff) {
            imgDiffPath = [NSString stringWithFormat:@"%@.diff.tiff", pathOfImageA];
            data = [imgA gtm_imageDataForImage:imgDiff];
            if ([data writeToFile:imgDiffPath atomically:YES]) {
                NSLog(@"Saved diff to %@", imgDiffPath);
            }
        }
        if (1 == vflag) {
            printf("%i\t%s\n", numberOfDiffs, [imgDiffPath cStringUsingEncoding:NSUTF8StringEncoding]);
        }
        return 1;
    }
    [pool drain];
    NSLog(@"Images are equal.");
    return 0;
}