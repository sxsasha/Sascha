/*
     File: PaintingViewController.m
 Abstract: The central controller of the application.
  Version: 1.13
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2014 Apple Inc. All Rights Reserved.
 
 */

#import "PaintingViewController.h"
#import "PaintingView.h"

//CONSTANTS:

#define kBrightness             1.0
#define kSaturation             0.45

#define kPaletteHeight			30
#define kPaletteSize			5
#define kMinEraseInterval		0.5

// Padding for margins
#define kLeftMargin				10.0
#define kTopMargin				10.0
#define kRightMargin			10.0

//CLASS IMPLEMENTATIONS:

@interface PaintingViewController()
{
	CFTimeInterval		lastTime;
}

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet PaintingView *paintView;

@end

@implementation PaintingViewController

#pragma mark - Main overriden methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupImage];
    self.paintView.alpha = 0.6f;
    
    [self initControl];
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    [self becomeFirstResponder];
    self.navigationController.hidesBarsOnTap = YES;
    
    UISwipeGestureRecognizer *swipe = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeRight:)];
    swipe.direction = UISwipeGestureRecognizerDirectionRight;
    [self.view addGestureRecognizer:swipe];
}

// Release resources when they are no longer needed,
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (BOOL)canBecomeFirstResponder {
    return YES;
}

#pragma mark - Init All

- (void)setupImage {
    
    UIImage *grayscaleImage = [self convertToGreyscale:self.image];
    
    self.imageView.image = grayscaleImage;
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [super viewDidLoad];
}

- (void)initControl {
    // Create a segmented control so that the user can choose the brush color.
    // Create the UIImages with the UIImageRenderingModeAlwaysOriginal rendering mode. This allows us to show the actual image colors in the segmented control.
    UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:
                                            [NSArray arrayWithObjects:
                                             [[UIImage imageNamed:@"Red"]       imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal],
                                             [[UIImage imageNamed:@"Yellow"]    imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal],
                                             [[UIImage imageNamed:@"Green"]     imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal],
                                             [[UIImage imageNamed:@"Blue"]      imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal],
                                             [[UIImage imageNamed:@"Purple"]    imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal],
                                             nil]];
    
    // Compute a rectangle that is positioned correctly for the segmented control you'll use as a brush color palette
    CGRect rect = [[UIScreen mainScreen] bounds];
    CGRect frame = CGRectMake(rect.origin.x + kLeftMargin, rect.size.height - kPaletteHeight - kTopMargin, rect.size.width - (kLeftMargin + kRightMargin), kPaletteHeight);
    segmentedControl.frame = frame;
    // When the user chooses a color, the method changeBrushColor: is called.
    [segmentedControl addTarget:self action:@selector(changeBrushColor:) forControlEvents:UIControlEventValueChanged];
    // Make sure the color of the color complements the black background
    segmentedControl.tintColor = [UIColor darkGrayColor];
    // Set the third color (index values start at 0)
    segmentedControl.selectedSegmentIndex = 2;
    
    // Add the control to the window
    [self.paintView addSubview:segmentedControl];
    // Now that the control is added, you can release it
    
    // Define a starting color
    CGColorRef color = [UIColor colorWithHue:(CGFloat)2.0 / (CGFloat)kPaletteSize
                                  saturation:kSaturation
                                  brightness:kBrightness
                                       alpha:1.0].CGColor;
    const CGFloat *components = CGColorGetComponents(color);
    
    // Defer to the OpenGL view to set the brush color
    [(PaintingView *)self.paintView setBrushColorWithRed:components[0] green:components[1] blue:components[2]];
    
    // Erase the view when recieving a notification named "shake" from the NSNotificationCenter object
    // The "shake" nofification is posted by the PaintingWindow object when user shakes the device
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(eraseView) name:@"shake" object:nil];
}

#pragma mark - Actions

- (void) swipeRight: (UITapGestureRecognizer*)sender {
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark Paint actions

// Change the brush color
- (void)changeBrushColor:(id)sender {
    // Play sound
    // Define a new brush color
    CGColorRef color = [UIColor colorWithHue:(CGFloat)[sender selectedSegmentIndex] / (CGFloat)kPaletteSize
                                  saturation:kSaturation
                                  brightness:kBrightness
                                       alpha:1.0].CGColor;
    const CGFloat *components = CGColorGetComponents(color);
    
    // Defer to the OpenGL view to set the brush color
    [(PaintingView *)self.paintView setBrushColorWithRed:components[0] green:components[1] blue:components[2]];
}

// Called when receiving the "shake" notification; plays the erase sound and redraws the view
- (void)eraseView {
	if(CFAbsoluteTimeGetCurrent() > lastTime + kMinEraseInterval) {
		[(PaintingView *)self.paintView erase];
		lastTime = CFAbsoluteTimeGetCurrent();
	}
}

// We do not support auto-rotation in this sample

#pragma mark Motion

- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event
{
	if (motion == UIEventSubtypeMotionShake)
	{
		// User was shaking the device. Post a notification named "shake".
		[[NSNotificationCenter defaultCenter] postNotificationName:@"shake" object:self];
	}
}

#pragma mark - Convert to Grayscale

- (UIImage *)convertToGreyscale:(UIImage *)i {
    int kRed = 1;  
    int kGreen = 2;
    int kBlue = 4;
    
    int colors = kGreen | kBlue | kRed;
    int m_width = i.size.width;
    int m_height = i.size.height;
    
    uint32_t *rgbImage = (uint32_t *) malloc(m_width * m_height * sizeof(uint32_t));
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(rgbImage, m_width, m_height, 8, m_width * 4, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextSetShouldAntialias(context, NO);
    CGContextDrawImage(context, CGRectMake(0, 0, m_width, m_height), [i CGImage]);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    
    // now convert to grayscale
    uint8_t *m_imageData = (uint8_t *) malloc(m_width * m_height);
    for(int y = 0; y < m_height; y++) {
        for(int x = 0; x < m_width; x++) {
            uint32_t rgbPixel=rgbImage[y*m_width+x];
            uint32_t sum=0,count=0;
            if (colors & kRed) {sum += (rgbPixel>>24)&255; count++;}
            if (colors & kGreen) {sum += (rgbPixel>>16)&255; count++;}
            if (colors & kBlue) {sum += (rgbPixel>>8)&255; count++;}
            m_imageData[y*m_width+x]=sum/count;
        }
    }
    free(rgbImage);
    
    // convert from a gray scale image back into a UIImage
    uint8_t *result = (uint8_t *) calloc(m_width * m_height *sizeof(uint32_t), 1);
    
    // process the image back to rgb
    for(int i = 0; i < m_height * m_width; i++) {
        result[i*4]=0;
        int val=m_imageData[i];
        result[i*4+1]=val;
        result[i*4+2]=val;
        result[i*4+3]=val;
    }
    
    // create a UIImage
    colorSpace = CGColorSpaceCreateDeviceRGB();
    context = CGBitmapContextCreate(result, m_width, m_height, 8, m_width * sizeof(uint32_t), colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);
    CGImageRef image = CGBitmapContextCreateImage(context);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);
    UIImage *resultUIImage = [UIImage imageWithCGImage:image];
    CGImageRelease(image);
    
    free(m_imageData);
    
    // make sure the data will be released by giving it to an autoreleased NSData
    [NSData dataWithBytesNoCopy:result length:m_width * m_height];
    
    return resultUIImage;
}

@end
