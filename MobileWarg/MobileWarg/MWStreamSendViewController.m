//
//  MWStreamSendViewController.m
//  MobileWarg
//
//  Created by David Jeong on 2015-06-14.
//  Copyright (c) 2015 MobileWarg. All rights reserved.
//

#import "MWMultipeerManager.h"
#import "MWStreamSendViewController.h"

@interface MWStreamSendViewController ()
@property (strong, nonatomic) IBOutlet UIView *imageView;
@property (strong, nonatomic) AVCaptureDevice *videoCaptureDevice;
@property (strong, nonatomic) AVCaptureDeviceInput *videoInput;
@property (strong, nonatomic) AVCaptureVideoDataOutput *outputData;
@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@property (strong, nonatomic) NSOutputStream *outputStream;
@property (strong, nonatomic) dispatch_queue_t videoQueue;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *scanBtn;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *shareBtn;

@end

@implementation MWStreamSendViewController

- (void)viewDidLoad {
    self.title = @"Sending feed";
    [super viewDidLoad];
    [self setupCamera];
    [self.outputData setSampleBufferDelegate:self queue:self.videoQueue];
    MWMultipeerManager * manager = [MWMultipeerManager sharedManager];
    self.outputStream = [manager.session startStreamWithName:@"mobilewarg" toPeer:manager.connectedPeerID error:nil];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setupCamera {
    if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Sorry, this application won't work because camera does not exist." delegate:nil cancelButtonTitle:@"Confirm" otherButtonTitles:nil];
        [alert show];
    } else {
        // Create a capture session.
        self.captureSession = [[AVCaptureSession alloc] init];
        self.captureSession.sessionPreset = AVCaptureSessionPresetMedium;
        
        // Add capture device.
        self.videoCaptureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        self.videoInput = [AVCaptureDeviceInput deviceInputWithDevice:self.videoCaptureDevice error:nil];
        
        if (self.videoInput) {
            // If capture device exists.
            self.outputData = [[AVCaptureVideoDataOutput alloc] init];
            self.outputData.videoSettings = @{(NSString *)kCVPixelBufferPixelFormatTypeKey:@(kCVPixelFormatType_32BGRA)};
            
            // Add input and output.
            [self.captureSession addInput:self.videoInput];
            [self.captureSession addOutput:self.outputData];
            
            // Create preview layer.
            self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
            self.previewLayer.frame = self.imageView.bounds;
            self.previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
            
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(changedOrientation)
                                                         name:UIDeviceOrientationDidChangeNotification
                                                       object:nil];
            
            [self.imageView.layer addSublayer:self.previewLayer];
            
            // Start running the capture session.
            [self.captureSession startRunning];
            
            self.videoQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0);
        } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Sorry, video input does not exist." delegate:nil cancelButtonTitle:@"Confirm" otherButtonTitles:nil];
            [alert show];
        }
    }
}

-(void) changedOrientation
{
    // Change the fit of the UI element.
    self.previewLayer.frame = self.imageView.bounds;
    
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    
    // Switch statement
    switch (deviceOrientation) {
        case UIInterfaceOrientationLandscapeLeft: {
            [self.previewLayer.connection setVideoOrientation:AVCaptureVideoOrientationLandscapeLeft];
        } break;
        case UIInterfaceOrientationLandscapeRight: {
            [self.previewLayer.connection setVideoOrientation:AVCaptureVideoOrientationLandscapeRight];
        } break;
        case UIInterfaceOrientationPortrait:{
            [self.previewLayer.connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
        } break;
        default:
            break;
    }
}


- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection {
    NSLog(@"Sampled");
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(imageBuffer,0);
    
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);
    void *src_buff = CVPixelBufferGetBaseAddress(imageBuffer);
    
    NSData *data = [NSData dataWithBytes:src_buff length:bytesPerRow * height];
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);
    
    MWMultipeerManager *manager = [MWMultipeerManager sharedManager];
    NSArray *allPeers = manager.session.connectedPeers;
    [manager.session sendData:data
                      toPeers:allPeers
                     withMode:MCSessionSendDataReliable
                        error:nil];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
