#!/usr/bin/python

import ImageChops, Image
import sys
import getopt

IMAGE_ALLOWED_DIFFS = 100

if len(sys.argv) < 3:
    sys.stderr.write("Usage: %s -d <image A> <image B>\n -d will write the diff image to disk in <image A> directory\n" % sys.argv[0])
    sys.exit(2)

dflag = False
vflag = False
exitCode = 1
imageDiffPath = "-"
numberOfDiffs = IMAGE_ALLOWED_DIFFS + 1

opts, arguments = getopt.getopt(sys.argv[1:], 'dv')
for k, v in opts:
    if k == '-d':
        dflag = True
    elif k == '-v':
        vflag = True

imageAPath = arguments[0]
imageBPath = arguments[1]
imageA = Image.open(imageAPath)
imageB = Image.open(imageBPath)

imageDiff = ImageChops.difference(imageA, imageB)

imagesAreTheSame = imageDiff.getbbox() is None
if imagesAreTheSame:
    exitCode = 0
else:
    if dflag or vflag:
        # set different pixels as red
        # TODO find a more PIL way to do this
        for x in range(0, imageDiff.size[0]):
            for y in range(0, imageDiff.size[1]):
                pixel = imageDiff.getpixel((x, y))
                if pixel != (0, 0, 0, 0):
                    numberOfDiffs += 1
                    imageDiff.putpixel((x, y), (255, 0, 0, 255))
        imageDiffPath = "%s.diff.tiff" % imageAPath
        if dflag:
            imageDiff.save(imageDiffPath)
if vflag:
    sys.stderr.write("%d\t%s\n" % (numberOfDiffs, imageDiffPath))

sys.exit(numberOfDiffs < IMAGE_ALLOWED_DIFFS and 0 or 1)
