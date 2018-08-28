//
//  Switch.h
//  OcrDemo
//
//  Copyright © 1991-2017 LEAD Technologies, Inc. All rights reserved.
//

IB_DESIGNABLE
@interface Switch : UIControl

@property (nonatomic, assign) IBInspectable BOOL on;

@property (nonatomic, strong) IBInspectable UIColor *offTintColor;
@property (nonatomic, strong) IBInspectable UIColor *onTintColor;
@property (nonatomic, strong) IBInspectable UIColor *borderColor;

@property (nonatomic, strong) IBInspectable UIColor *onThumbTintColor;
@property (nonatomic, strong) IBInspectable UIColor *offThumbTintColor;

@property (nonatomic, assign) IBInspectable CGFloat borderWidth;
@property (nonatomic, assign) IBInspectable CGFloat thumbInset;

@end
