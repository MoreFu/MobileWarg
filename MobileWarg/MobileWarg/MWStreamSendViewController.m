//
//  StreamSendViewController.m
//  MobileWarg
//
//  Created by David Jeong on 2015. 6. 8..
//  Copyright (c) 2015 MobileWarg. All rights reserved.
//

@import AVFoundation;
#import "AppDelegate.h"
#import "MWStreamSendViewController.h"
#import "AppDelegate.h"

@interface MWStreamSendViewController ()

@property (weak, nonatomic) AppDelegate *appDelegate;
@property (strong, nonatomic) IBOutlet UIView *imageView;
@property (strong, nonatomic) AVCaptureDevice *videoCaptureDevice;
@property (strong, nonatomic) AVCaptureDeviceInput *videoInput;
@property (strong, nonatomic) AVCaptureVideoDataOutput *outputData;
@property (strong, nonatomic) AVCaptureSession *captureSession;
@property (strong, nonatomic) AVCaptureVideoPreviewLayer *previewLayer;
@property (strong, nonatomic) NSOutputStream *outputStream;
@property BOOL isConnectionEstablished;
- (IBAction)sendMessage:(id)sender;


@end

@implementation MWStreamSendViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [self setupMultipeerConnectivity];
    
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
            
                    } else {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Error" message:@"Sorry, video input does not exist." delegate:nil cancelButtonTitle:@"Confirm" otherButtonTitles:nil];
            [alert show];
        }
    }
}

- (void) setupMultipeerConnectivity {
    MWMultipeerManager * manager = [MWMultipeerManager sharedManager];
    [manager setupPeerWithDisplayName:[UIDevice currentDevice].name];
    [manager setupSession];
    [manager advertiseSelf:true];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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

- (IBAction)searchForPeers:(id)sender {
    
    MWMultipeerManager * manager = [MWMultipeerManager sharedManager];
    
    if (manager.session != nil) {
        [manager setupBrowser];
        manager.browser.delegate = self;
        
        [self presentViewController:manager.browser
                           animated:YES
                         completion:nil];
    }
}

#pragma mark MCBrowserViewController Delegates
- (void)browserViewControllerDidFinish:(MCBrowserViewController *)browserViewController {
    MWMultipeerManager * manager = [MWMultipeerManager sharedManager];
    [manager.browser dismissViewControllerAnimated:YES completion:nil];
}

- (void)browserViewControllerWasCancelled:(MCBrowserViewController *)browserViewController {
    MWMultipeerManager * manager = [MWMultipeerManager sharedManager];
    [manager.browser dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)sendMessage:(id)sender {
    if (self.isConnectionEstablished) {
        MWMultipeerManager * manager = [MWMultipeerManager sharedManager];
        
        NSData *dataToSend = [@"This is sample text." dataUsingEncoding:NSUTF8StringEncoding];
        NSArray *allPeers = manager.session.connectedPeers;
        NSError *error;
        
        [manager.session sendData:dataToSend
                                              toPeers:allPeers
                                             withMode:MCSessionSendDataReliable
                                                error:&error];
        
    }
}
@end