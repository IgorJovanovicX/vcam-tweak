// Frida script to trace camera resolution usage

console.log("[*] Camera Resolution Tracer loaded");

// Hook AVCaptureSession to see session presets
if (ObjC.available) {
    var AVCaptureSession = ObjC.classes.AVCaptureSession;
    
    if (AVCaptureSession) {
        Interceptor.attach(AVCaptureSession['- setSessionPreset:'].implementation, {
            onEnter: function(args) {
                var preset = new ObjC.Object(args[2]);
                console.log("\n[AVCaptureSession] Session Preset: " + preset.toString());
                
                // Map presets to resolutions
                var presetMap = {
                    "AVCaptureSessionPresetPhoto": "Full photo resolution",
                    "AVCaptureSessionPresetHigh": "Highest available",
                    "AVCaptureSessionPresetMedium": "Medium quality",
                    "AVCaptureSessionPresetLow": "Low quality",
                    "AVCaptureSessionPreset352x288": "352x288",
                    "AVCaptureSessionPreset640x480": "640x480 (VGA)",
                    "AVCaptureSessionPreset1280x720": "1280x720 (720p)",
                    "AVCaptureSessionPreset1920x1080": "1920x1080 (1080p)",
                    "AVCaptureSessionPreset3840x2160": "3840x2160 (4K)",
                    "AVCaptureSessionPresetiFrame960x540": "960x540",
                    "AVCaptureSessionPresetiFrame1280x720": "1280x720"
                };
                
                var resolution = presetMap[preset.toString()] || "Unknown preset";
                console.log("[Resolution] " + resolution);
            }
        });
    }
    
    // Hook CMSampleBuffer to see actual buffer dimensions
    Interceptor.attach(Module.findExportByName("CoreMedia", "CMSampleBufferGetImageBuffer"), {
        onLeave: function(retval) {
            if (retval.isNull()) return;
            
            var CVPixelBufferGetWidth = new NativeFunction(
                Module.findExportByName("CoreVideo", "CVPixelBufferGetWidth"),
                'size_t', ['pointer']
            );
            var CVPixelBufferGetHeight = new NativeFunction(
                Module.findExportByName("CoreVideo", "CVPixelBufferGetHeight"),
                'size_t', ['pointer']
            );
            
            var width = CVPixelBufferGetWidth(retval);
            var height = CVPixelBufferGetHeight(retval);
            
            if (width > 0 && height > 0) {
                console.log("[CMSampleBuffer] Actual buffer size: " + width + "x" + height);
            }
        }
    });
    
    console.log("[*] Hooks installed. Start using the camera in the app...");
} else {
    console.log("[!] Objective-C Runtime not available");
}
