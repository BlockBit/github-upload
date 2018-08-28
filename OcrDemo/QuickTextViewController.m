//
//  QuickTextViewController.m
//  OcrDemo
//
//  Copyright © 1991-2017 LEAD Technologies, Inc. All rights reserved.
//

#import "QuickTextViewController.h"
#import "UI Controls/ToolbarView.h"
#import "UI Controls/ScrollableTextView.h"
//#import "UIImage+MDQRCode.h"
#import "CustomQRCode.h"
#pragma mark - Class Extension

/*
 // image view is an instance of UIImageView
 imageView.image = [UIImage mdQRCodeForString:@"Hello, world!" size:imageView.bounds.size.width fillColor:[UIColor darkGrayColor]];
 */


@interface QuickTextViewController()
@property (weak, nonatomic) IBOutlet UIImageView *sampleImageViewQR;

@property (nonatomic, strong) IBOutlet ScrollableTextView *textView;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UIButton *doneButton;
@property (nonatomic, strong) IBOutlet UIButton *selectAllButton;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *clearViewConstraint;

@end

#pragma mark - Class Implementation

@implementation QuickTextViewController

#pragma mark - Property Synthesis

@synthesize recognitionText = _recognitionText, constraint = _constraint, textView = _textView, titleLabel = _titleLabel, doneButton = _doneButton, selectAllButton = _selectAllButton, clearViewConstraint = _clearViewConstraint;

- (void)setRecognitionText:(NSString *)recognitionText {
    _recognitionText = recognitionText;
    _textView.text   = recognitionText;
    
    
    NSString *valueToSave = recognitionText;
    [[NSUserDefaults standardUserDefaults] setObject:valueToSave forKey:@"OCR_READ"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    // Do any additional setup after loading the view, typically from a nib.
    
    // Only one line
//    UIColor *customColor = [UIColor colorWithRed:60.f/255.f green:74.f/255.f blue:89.f/255.f alpha:1.f];
//    UIImage *customQrcode = [CustomQRCode generateCustomQRCode:@"JOBINS JOHN" andSize:250.f andColor:customColor];
//    UIImage *customQrcode = [CustomQRCode generateCustomQRCode:@"JOBINS JOHN" andSize:250.f andColor: [UIColor colorWithRed:255 green:11 blue:2 alpha:1]];
    //printf(customQrcode);
    
    // Old method
    //    CIImage *qrcodeCg = [CustomQRCode createQRForString:@"http://blog.yourtion.com"];
    //    UIImage *qrcode = [CustomQRCode createNonInterpolatedUIImageFormCIImage:qrcodeCg withSize:250.0f];
    //    UIImage *customQrcode = [CustomQRCode imageBlackToTransparent:qrcode withRed:60.0f andGreen:74.0f andBlue:89.0f];
    
    
    //rself.sampleImageViewQR.backgroundColor = [UIColor.brownColor];
    //self.sampleImageViewQR.image = customQrcode;
    //self.sampleImageViewQR.image = [UIImage imageNamed:@"coupon.png"];
    // set shadow
    //[CustomQRCode setImageViewShadow:self.qrcodeView];
    
    
//    _sampleImageViewQR.image =
    
}

- (void)setConstraint:(CGFloat)constraint {
    _constraint                   = constraint;
    _clearViewConstraint.constant = constraint;
}

- (void)setTextView:(ScrollableTextView *)textView {
    _textView = textView;
    
    _textView.text      = _recognitionText;
    
//    _sampleImageViewQR.image = [UIImage mdQRCodeForString:@"JOBINS JOHN" size:_sampleImageViewQR.bounds.size.width fillColor:[UIColor darkGrayColor]];
    _textView.inputView = [[UIView alloc] initWithFrame:CGRectZero];
}

- (void)setDoneButton:(UIButton *)doneButton {
    _doneButton = doneButton;
    _doneButton.hitTestEdgeInsets = UIEdgeInsetsMake(-10.0, -10.0, -10.0, -10.0);
}

- (void)setSelectAllButton:(UIButton *)selectAllButton {
    _selectAllButton = selectAllButton;
    _selectAllButton.hitTestEdgeInsets = UIEdgeInsetsMake(-10.0, -10.0, -10.0, -10.0);
}

- (void)setClearViewConstraint:(NSLayoutConstraint *)clearViewConstraint {
    _clearViewConstraint          = clearViewConstraint;
    _clearViewConstraint.constant = _constraint;
}

@end
