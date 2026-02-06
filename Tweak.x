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
    
    // Detect and write camera resolution to file once
    static dispatch_once_t resolutionOnce;
    dispatch_once(&resolutionOnce, ^{
        size_t width = CVPixelBufferGetWidth(originalImageBuffer);
        size_t height = CVPixelBufferGetHeight(originalImageBuffer);
        
        NSString *resolutionInfo = [NSString stringWithFormat:@"Camera Resolution: %zu x %zu\n", width, height];
        [resolutionInfo writeToFile:@"/tmp/vcam_resolution.txt" 
                         atomically:YES 
                           encoding:NSUTF8StringEncoding 
                              error:nil];
        
        NSLog(@"[vcam] Camera resolution: %zu x %zu - written to /tmp/vcam_resolution.txt", width, height);
    });

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