//
//  LTImageViewerSelectAreaInteractiveMode.h
//  OcrDemo
//
//  Copyright © 1991-2017 LEAD Technologies, Inc. All rights reserved.
//

@interface LTImageViewerSelectAreaInteractiveMode : LTImageViewerInteractiveMode

@property (nonatomic, strong) UIColor *lineColor;
@property (nonatomic, assign) CGFloat lineWidth;

@property (nonatomic, strong) UIColor *thumbColor;
@property (nonatomic, strong) UIColor *backgroundColor;

@property (nonatomic, assign) CGRect selectedArea;

- (void)resetThumbs;

@end
