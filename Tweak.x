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
    
    // Detect and show camera resolution once
    static dispatch_once_t resolutionOnce;
    dispatch_once(&resolutionOnce, ^{
        size_t width = CVPixelBufferGetWidth(originalImageBuffer);
        size_t height = CVPixelBufferGetHeight(originalImageBuffer);
        
        NSString *message = [NSString stringWithFormat:@"Camera Resolution: %zux%zu", width, height];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"VCam Debug" 
                                                                           message:message 
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
            
            UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
            UIViewController *rootVC = keyWindow.rootViewController;
            while (rootVC.presentedViewController) {
                rootVC = rootVC.presentedViewController;
            }
            [rootVC presentViewController:alert animated:YES completion:nil];
        });
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