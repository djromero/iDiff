#!/usr/bin/python
# Simple image difference using PIL http://effbot.org/zone/pil-index.htm
# Useful to validate whether iDiff works properly
# 5th Jan 2010 by julian@wuonm.com
#
import ImageChops, Image
import sys
import getopt

if len(sys.argv) < 3:
    sys.stderr.write("Usage: %s -d <image A> <image B>\n -d will write the diff image to disk in <image A> directory\n" % sys.argv[0])
    sys.exit(2)

dflag = False
exitCode = 1
opts, arguments = getopt.getopt(sys.argv[1:], 'd')
for k, v in opts:
    if k == '-d':
        dflag = True

imageAPath = arguments[0]
imageBPath = arguments[1]
imageA = Image.open(imageAPath)
imageB = Image.open(imageBPath)

imageDiff = ImageChops.difference(imageA, imageB)

imagesAreTheSame = imageDiff.getbbox() is None
if imagesAreTheSame:
    exitCode = 0
else:
    if dflag:
        # set different pixels as red
        # TODO find a more PIL way to do this
        for x in range(0, imageDiff.size[0]):
            for y in range(0, imageDiff.size[1]):
                pixel = imageDiff.getpixel((x, y))
                if pixel != (0, 0, 0, 0):
                    imageDiff.putpixel((x, y), (255, 0, 0, 0))
        imageDiffPath = "%s.diff.tiff" % imageAPath
        sys.stderr.write("Bounding box: %s\n" % str(imageDiff.getbbox()))
        sys.stderr.write("%s\n" % imageDiffPath)
        imageDiff.save(imageDiffPath)

sys.exit(exitCode)