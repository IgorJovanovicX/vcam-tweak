#import "image_utils.h"

%hook BWNodeOutput

- (void)emitSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    unsigned int mediaType = ((unsigned int (*)(id, SEL))objc_msgSend)(self, sel_registerName("mediaType"));
    if (mediaType != 'vide') {
        %orig(sampleBuffer);
        return;
    }

    CVPixelBufferRef originalImageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    if (originalImageBuffer == NULL) {
        %orig(sampleBuffer);
        return;
    }
    
    // Log camera resolution
    size_t width = CVPixelBufferGetWidth(originalImageBuffer);
    size_t height = CVPixelBufferGetHeight(originalImageBuffer);
    NSLog(@"[VCam] Camera buffer resolution: %zux%zu", width, height);

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        loadReplacementMedia();
    });

    @try {
        CVPixelBufferLockBaseAddress(originalImageBuffer, 0);
        drawReplacementOntoBuffer(originalImageBuffer);
    }
    @finally {
        CVPixelBufferUnlockBaseAddress(originalImageBuffer, 0);
    }

    %orig(sampleBuffer);
}

%end