#include "ios_video_capture_interface.h"

#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

typedef NS_ENUM( NSInteger, AVCamSetupResult ) {
    AVCamSetupResultSuccess,
    AVCamSetupResultCameraNotAuthorized,
    AVCamSetupResultSessionConfigurationFailed
};

@interface IosVideoAVFoundationCapture : NSObject<AVCaptureVideoDataOutputSampleBufferDelegate>
{
@private
    dispatch_queue_t sessionQueue;
	AVCaptureDeviceInput *videoDeviceInput;
	AVCaptureVideoDataOutput *videoDataOutput;
    
    AVCamSetupResult setupResult;
    AVCaptureDevicePosition position;
    UIBackgroundTaskIdentifier backgroundRecordingID;
    
    NSDictionary *pixelBufferOptions;

	oppvs::frame_callback callback_frame;
    oppvs::PixelBuffer pixel_buffer;
    void* callback_user;

    int is_pixel_buffer_set;
    int pixel_format;
    oppvs::VideoActiveSource sourceInfo;
    oppvs::VideoActiveSource* pSourceInfo;
}

@property (nonatomic, strong) AVCaptureSession* session;

- (id)init;
- (void) openCaptureDevice: (CGRect) rect : (int) pixelformat : (int) fps;
- (void) setSource: (oppvs::VideoActiveSource*) source;
- (void) setCallback: (oppvs::frame_callback) fc fromuser: (void*) u;
- (int) startRecording;
- (void) stopRecording;
- (void) updateConfiguration: (const oppvs::VideoActiveSource&) source;
@end

@implementation IosVideoAVFoundationCapture {
    
}

- (id)init
{
    self = [super init];
    if (self)
    {
        is_pixel_buffer_set = 0;
    }
    
    self.session = nil;
    videoDeviceInput = nil;
    videoDataOutput = nil;
    return self;
}

- (void)openCaptureDevice:(CGRect)rect :(int)pixelformat :(int)fps
{
    // Create session
    self.session = [[AVCaptureSession alloc] init];
    if(self.session == nil) {
        printf("Error: cannot create the capture session.\n");
        return;
    }
    
    sessionQueue = dispatch_queue_create( "session queue", DISPATCH_QUEUE_SERIAL );
    setupResult = AVCamSetupResultSuccess;
    
    // Check video authorization status. Video access is required and audio access is optional.
    // If audio access is denied, audio is not recorded during movie recording.
    switch ( [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] )
    {
        case AVAuthorizationStatusAuthorized:
        {
            // The user has previously granted access to the camera.
            break;
        }
        case AVAuthorizationStatusNotDetermined:
        {
            // The user has not yet been presented with the option to grant video access.
            // We suspend the session queue to delay session setup until the access request has completed to avoid
            // asking the user for audio access if video access is denied.
            // Note that audio access will be implicitly requested when we create an AVCaptureDeviceInput for audio during session setup.
            dispatch_suspend( sessionQueue );
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^( BOOL granted ) {
                if ( ! granted ) {
                    setupResult = AVCamSetupResultCameraNotAuthorized;
                }
                dispatch_resume( sessionQueue );
            }];
            break;
        }
        default:
        {
            // The user has previously denied access.
            setupResult = AVCamSetupResultCameraNotAuthorized;
            break;
        }
    }
    
    dispatch_async( sessionQueue, ^{
        if ( setupResult != AVCamSetupResultSuccess ) {
            return;
        }
                
        if (sourceInfo.video_source_id.compare("1"))
        {
            position = AVCaptureDevicePositionBack;
        }
        else
            position = AVCaptureDevicePositionFront;
        
        backgroundRecordingID = UIBackgroundTaskInvalid;
        NSError *error = nil;
        
        AVCaptureDevice *device = [IosVideoAVFoundationCapture deviceWithMediaType:AVMediaTypeVideo preferringPosition:position];
        AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
        
        if ( ! input ) {
            NSLog( @"Could not create video device input: %@", error );
        }
        
        [self.session beginConfiguration];
        
        if ( [self.session canAddInput:input] ) {
            [self.session addInput:input];
            videoDeviceInput = input;

        }
        else {
            NSLog( @"Could not add video device input to the session" );
            setupResult = AVCamSetupResultSessionConfigurationFailed;
        }

        AVCaptureVideoDataOutput *output = [[AVCaptureVideoDataOutput alloc] init];
        output.alwaysDiscardsLateVideoFrames = YES;
        if ([self.session canAddOutput:output])
        {
            pixelBufferOptions = [NSDictionary dictionaryWithObjectsAndKeys:
                                  [NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA], (id)kCVPixelBufferPixelFormatTypeKey,
                                  nil];
            
            [output setVideoSettings:pixelBufferOptions];
            [self.session addOutput:output];
            AVCaptureConnection *connection = [output connectionWithMediaType:AVMediaTypeVideo];
            if ([connection isVideoStabilizationSupported])
                connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
            
            if ([connection isVideoOrientationSupported])
            {
                AVCaptureVideoOrientation orientation = AVCaptureVideoOrientationLandscapeRight;
                [connection setVideoOrientation:orientation];
            }

            videoDataOutput = output;
            
            dispatch_queue_t queue = dispatch_queue_create("oppvs.videocapture.queue", DISPATCH_QUEUE_SERIAL);
            [videoDataOutput setSampleBufferDelegate:self queue:queue];
            dispatch_release(queue);
        }
        
        [self.session setSessionPreset:AVCaptureSessionPresetMedium];
        [self.session commitConfiguration];
    } );
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    CVPixelBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    if (imageBuffer == NULL)
    {
        printf("Return null image buffer \n");
        return;
    }
    
    /* Fill the pixel_buffer member with some info that won't change per frame. */
    if (0 == is_pixel_buffer_set) {
        
        if (true == CVPixelBufferIsPlanar(imageBuffer)) {
            size_t plane_count = CVPixelBufferGetPlaneCount(imageBuffer);
            if (plane_count > 3) {
                printf("Error: we got a plane count bigger then 3, not supported yet. Stopping.\n");
                exit(EXIT_FAILURE);
            }
            for (size_t i = 0; i < plane_count; ++i) {
                pixel_buffer.width[i] = CVPixelBufferGetWidthOfPlane(imageBuffer, i);
                pixel_buffer.height[i] = CVPixelBufferGetHeightOfPlane(imageBuffer, i);
                pixel_buffer.stride[i] = CVPixelBufferGetBytesPerRowOfPlane(imageBuffer, i);
                pixel_buffer.nbytes += pixel_buffer.stride[i] * pixel_buffer.height[i];
                
                
                printf("width: %hu, height: %hu, stride: %hu, nbytes: %lu, plane_count: %lu\n",
                       pixel_buffer.width[i],
                       pixel_buffer.height[i],
                       pixel_buffer.stride[i],
                       pixel_buffer.nbytes,
                       plane_count);
            }
        }
        else {
            pixel_buffer.width[0] = CVPixelBufferGetWidth(imageBuffer);
            pixel_buffer.height[0] = CVPixelBufferGetHeight(imageBuffer);
            pixel_buffer.stride[0] = CVPixelBufferGetBytesPerRow(imageBuffer);
            pixel_buffer.nbytes = pixel_buffer.stride[0] * pixel_buffer.height[0];
            pixel_buffer.format = PF_BGRA32;
            
            //Update VideoActiveSource
            pSourceInfo->rect.right = pSourceInfo->rect.left + pixel_buffer.width[0];
            pSourceInfo->rect.top = pSourceInfo->rect.bottom + pixel_buffer.height[0];
            pSourceInfo->stride = pixel_buffer.stride[0];
        }
        is_pixel_buffer_set = 1;
    }
    
    //Lock before processing pixel data with CPU
    CVPixelBufferLockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
    
    CGSize imageSize = CVImageBufferGetEncodedSize(imageBuffer);
    pixel_format = PF_BGRA32;
    if (PF_YUYV422 == pixel_format     /* kCVPixelFormatType_422YpCbCr8_yuvs */
        || PF_UYVY422 == pixel_format  /* kCVPixelFormatType_422YpCbCr8 */
        || PF_BGRA32 == pixel_format   /* kCVPixelFormatType_32BGRA */
        )
    {
        pixel_buffer.plane[0] = (uint8_t*)CVPixelBufferGetBaseAddress(imageBuffer);
    }
    else if (PF_YUVJ420BP == pixel_format     /* kCVPixelFormatType_420YpCbCr8BiPlanarFullRange */
             || PF_YUV420BP == pixel_format) /* kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange */
    {
        pixel_buffer.plane[0] = (uint8_t*)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 0);
        pixel_buffer.plane[1] = (uint8_t*)CVPixelBufferGetBaseAddressOfPlane(imageBuffer, 1);
    }
    else {
        printf("Error: unhandled or unknown pixel format: %d.\n", pixel_format);
    }
    
    pixel_buffer.format = PF_BGRA32;
    
    callback_frame(pixel_buffer);
    
    CVPixelBufferUnlockBaseAddress(imageBuffer, kCVPixelBufferLock_ReadOnly);
}

- (int)startRecording
{
    dispatch_async( sessionQueue, ^{
        switch ( setupResult )
        {
            case AVCamSetupResultSuccess:
            {
                [self.session startRunning];
                
            }
            case AVCamSetupResultCameraNotAuthorized:
            {

                break;
            }
            case AVCamSetupResultSessionConfigurationFailed:
            {

                break;
            }
        }
    } );
    return setupResult;
}

- (void)stopRecording
{
    if ([self.session isRunning] == YES)
    {
        [self.session stopRunning];
        return;
    }
}

- (void) setSource: (oppvs::VideoActiveSource*) source;
{
    sourceInfo = *source;
    pSourceInfo = source;
    pixel_buffer.source = source->id;
}

- (void) setCallback: (oppvs::frame_callback) fc fromuser: (void*) u {
    callback_frame = fc;
    callback_user = u;
    pixel_buffer.user = u;
}

- (void)updateConfiguration:(const oppvs::VideoActiveSource &)source
{
    if (self.session)
    {
        
        if (sourceInfo.video_source_id.compare(source.video_source_id) != 0)
        {
            dispatch_async( sessionQueue, ^{
                AVCaptureDevice *currentVideoDevice = videoDeviceInput.device;
                AVCaptureDevicePosition preferredPosition = AVCaptureDevicePositionUnspecified;
                AVCaptureDevicePosition currentPosition = currentVideoDevice.position;
                
                switch ( currentPosition )
                {
                    case AVCaptureDevicePositionUnspecified:
                    case AVCaptureDevicePositionFront:
                        preferredPosition = AVCaptureDevicePositionBack;
                        break;
                    case AVCaptureDevicePositionBack:
                        preferredPosition = AVCaptureDevicePositionFront;
                        break;
                }
                
                AVCaptureDevice *device = [IosVideoAVFoundationCapture deviceWithMediaType:AVMediaTypeVideo preferringPosition:preferredPosition];
                AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:nil];
                
                [self.session beginConfiguration];
                // Remove the existing device input first, since using the front and back camera simultaneously is not supported.
                [self.session removeInput:videoDeviceInput];
                
                if ( [self.session canAddInput:input] ) {
                    [self.session addInput:input];
                    videoDeviceInput = input;
                }
                else
                {
                    [self.session addInput:videoDeviceInput];
                }
                
                AVCaptureConnection *connection = [videoDataOutput connectionWithMediaType:AVMediaTypeVideo];
                if ( connection.isVideoStabilizationSupported ) {
                    connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
                }
                [self.session commitConfiguration];
                
                is_pixel_buffer_set = 0;
            } );
        }
        
    }
    
    sourceInfo = source;
}

+ (AVCaptureDevice *)deviceWithMediaType:(NSString *)mediaType preferringPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:mediaType];
    AVCaptureDevice *captureDevice = devices.firstObject;
    
    for ( AVCaptureDevice *device in devices ) {
        if ( device.position == position ) {
            captureDevice = device;
            break;
        }
    }
    
    return captureDevice;
}

#pragma mark Wrapper Interfaces Implementation

void* oppvs_vc_av_alloc() {
    return (void*)[[IosVideoAVFoundationCapture alloc] init];
}

void oppvs_av_set_callback(void* cap, oppvs::frame_callback fc, void* user) {
    return [(id)cap setCallback : fc fromuser: user];
}

int oppvs_setup_capture_session(void* cap, oppvs::VideoActiveSource* source) {
    CGRect rect = CGRectMake(source->rect.left, source->rect.bottom,
                             source->rect.right - source->rect.left, source->rect.top - source->rect.bottom);
    
    [(id)cap setSource: source];
    [(id)cap openCaptureDevice: rect : source->pixel_format : source->fps];
    return 0;
}

int oppvs_start_video_recording(void* cap) {
    return [(id)cap startRecording];
}

void oppvs_stop_video_recording(void* cap) {
    return [(id)cap stopRecording];
}

void oppvs_update_configuration(void* cap, const oppvs::VideoActiveSource& source) {
    return [(id)cap updateConfiguration:source];
}

@end

