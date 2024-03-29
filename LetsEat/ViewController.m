//
//  ViewController.m
//  LetsEat
//
//  Created by Monte's Pro 13" on 10/9/15.
//  Copyright © 2015 Monte Thakkar. All rights reserved.
//

#import "ViewController.h"
#import "SCShapeView.h"
@import AVFoundation;

@interface ViewController () <AVCaptureMetadataOutputObjectsDelegate> {
   AVCaptureVideoPreviewLayer *_previewLayer;
   SCShapeView *_boundingBox;
   NSTimer *_boxHideTimer;
   UILabel *_decodedMessage;
   BOOL stopScanningQR;
}


@end

@implementation ViewController

- (NSUInteger)supportedInterfaceOrientations
{
   return UIInterfaceOrientationMaskPortrait;
}

- (void)viewDidLoad
{
   [super viewDidLoad];
   stopScanningQR = true;
   // Do any additional setup after loading the view, typically from a nib.
   
   // Create a new AVCaptureSession
   AVCaptureSession *session = [[AVCaptureSession alloc] init];
   AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
   NSError *error = nil;
   
   // Want the normal device
   AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:device error:&error];
   
   if(input) {
      // Add the input to the session
      [session addInput:input];
   } else {
      NSLog(@"error: %@", error);
      return;
   }
   
   AVCaptureMetadataOutput *output = [[AVCaptureMetadataOutput alloc] init];
   // Have to add the output before setting metadata types
   [session addOutput:output];
   // What different things can we register to recognise?
   NSLog(@"%@", [output availableMetadataObjectTypes]);
   // We're only interested in QR Codes
   [output setMetadataObjectTypes:@[AVMetadataObjectTypeQRCode]];
   // This VC is the delegate. Please call us on the main queue
   [output setMetadataObjectsDelegate:self queue:dispatch_get_main_queue()];
   
   // Display on screen
   _previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:session];
   _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
   _previewLayer.bounds = self.view.bounds;
   _previewLayer.position = CGPointMake(CGRectGetMidX(self.view.bounds), CGRectGetMidY(self.view.bounds));
   [self.view.layer addSublayer:_previewLayer];
   
   
   // Add the view to draw the bounding box for the UIView
   _boundingBox = [[SCShapeView alloc] initWithFrame:self.view.bounds];
   _boundingBox.backgroundColor = [UIColor clearColor];
   _boundingBox.hidden = YES;
   [self.view addSubview:_boundingBox];
   
   // Add a label to display the resultant message
   _decodedMessage = [[UILabel alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.bounds) - 75, CGRectGetWidth(self.view.bounds), 75)];
   _decodedMessage.numberOfLines = 0;
   _decodedMessage.backgroundColor = [UIColor colorWithWhite:0.8 alpha:0.9];
   _decodedMessage.textColor = [UIColor darkGrayColor];
   _decodedMessage.textAlignment = NSTextAlignmentCenter;
   [self.view addSubview:_decodedMessage];
   
   // Start the AVSession running
   [session startRunning];
}

#pragma mark - AVCaptureMetadataOutputObjectsDelegate
- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
   
   if (!stopScanningQR) {
      return;
   }
   else{
      stopScanningQR = NO;
      for (AVMetadataObject *metadata in metadataObjects) {
         if ([metadata.type isEqualToString:AVMetadataObjectTypeQRCode]) {
            // Transform the meta-data coordinates to screen coords
            AVMetadataMachineReadableCodeObject *transformed = (AVMetadataMachineReadableCodeObject *)[_previewLayer transformedMetadataObjectForMetadataObject:metadata];
            // Update the frame on the _boundingBox view, and show it
            _boundingBox.frame = transformed.bounds;
            _boundingBox.hidden = NO;
            // Now convert the corners array into CGPoints in the coordinate system
            //  of the bounding box itself
            NSArray *translatedCorners = [self translatePoints:transformed.corners
                                                      fromView:self.view
                                                        toView:_boundingBox];
            
            // Set the corners array
            _boundingBox.corners = translatedCorners;
            
            NSLog(@"%@", [transformed stringValue]);
            // Update the view with the decoded text
            _decodedMessage.text = [transformed stringValue];
            
            // Start the timer which will hide the overlay
            [self startOverlayHideTimer];
            
            
            //_theURL = [transformed stringValue];
            /*FormViewController *formViewController = [[FormViewController alloc]init];
             formViewController.urlString = _theURL;*/
            //LoadingViewController *loadVC = [[LoadingViewController alloc]init];
            //loadVC.getURL = _theURL;
            // Push it onto the top of the navigation controller's stack
            //[self.navigationController pushViewController:loadVC animated:YES];*/
            NSLog(@"DOne");
         }
         
      }
   }
}

#pragma mark - Utility Methods
- (void)startOverlayHideTimer
{
   // Cancel it if we're already running
   if(_boxHideTimer) {
      [_boxHideTimer invalidate];
   }
   
   // Restart it to hide the overlay when it fires
   _boxHideTimer = [NSTimer scheduledTimerWithTimeInterval:0.2
                                                    target:self
                                                  selector:@selector(removeBoundingBox:)
                                                  userInfo:nil
                                                   repeats:NO];
}

- (void)removeBoundingBox:(id)sender
{
   // Hide the box and remove the decoded text
   _boundingBox.hidden = YES;
   _decodedMessage.text = @"";
}

- (NSArray *)translatePoints:(NSArray *)points fromView:(UIView *)fromView toView:(UIView *)toView
{
   NSMutableArray *translatedPoints = [NSMutableArray new];
   
   // The points are provided in a dictionary with keys X and Y
   for (NSDictionary *point in points) {
      // Let's turn them into CGPoints
      CGPoint pointValue = CGPointMake([point[@"X"] floatValue], [point[@"Y"] floatValue]);
      // Now translate from one view to the other
      CGPoint translatedPoint = [fromView convertPoint:pointValue toView:toView];
      // Box them up and add to the array
      [translatedPoints addObject:[NSValue valueWithCGPoint:translatedPoint]];
   }
   
   return [translatedPoints copy];
}


@end
