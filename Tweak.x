#import "image_utils.h"

%ctor {
    NSLog(@"[vcam] ========== VCAM TWEAK LOADED ==========");
    NSLog(@"[vcam] Process: %s", getprogname());
    NSLog(@"[vcam] PID: %d", getpid());
    [@"VCAM LOADED\n" writeToFile:@"/tmp/vcam_loaded.txt" atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

%hook BWNodeOutput

- (void)emitSampleBuffer:(CMSampleBufferRef)sampleBuffer {
    NSLog(@"[vcam] ========== emitSampleBuffer CALLED ==========");
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