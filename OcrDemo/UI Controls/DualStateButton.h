//
//  DualStateButton.h
//  OcrDemo
//
//  Copyright © 1991-2017 LEAD Technologies, Inc. All rights reserved.
//

IB_DESIGNABLE
@interface DualStateButton : UIControl

@property (nonatomic, assign) IBInspectable BOOL on;

@property (nonatomic, strong) IBInspectable UIColor *onBackgroundColor;
@property (nonatomic, strong) IBInspectable UIColor *offBackgroundColor;
@property (nonatomic, strong) IBInspectable UIColor *onForegroundColor;
@property (nonatomic, strong) IBInspectable UIColor *offForegroundColor;
@property (nonatomic, strong) IBInspectable UIColor *borderColor;

@property (nonatomic, assign) IBInspectable CGFloat cornerRadius;

@property (nonatomic, assign) IBInspectable BOOL canTurnOnWithTouch;
@property (nonatomic, assign) IBInspectable BOOL canTurnOffWithTouch;

@property (nonatomic, copy)   IBInspectable NSString *text;

@property (nonatomic, strong) UILabel *textLabel;

@end
