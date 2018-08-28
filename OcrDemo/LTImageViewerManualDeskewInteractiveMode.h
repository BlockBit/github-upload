//
//  LTImageViewerManualDeskewInteractiveMode.h
//  OcrDemo
//
//  Copyright © 1991-2017 LEAD Technologies, Inc. All rights reserved.
//

@interface LTImageViewerManualDeskewInteractiveMode : LTImageViewerInteractiveMode

@property (nonatomic, assign, readonly) CGPoint topLeft;
@property (nonatomic, assign, readonly) CGPoint topRight;
@property (nonatomic, assign, readonly) CGPoint bottomLeft;
@property (nonatomic, assign, readonly) CGPoint bottomRight;

@property (nonatomic, assign, readonly) CGPoint topMid;
@property (nonatomic, assign, readonly) CGPoint bottomMid;
@property (nonatomic, assign, readonly) CGPoint leftMid;
@property (nonatomic, assign, readonly) CGPoint rightMid;

@property (nonatomic, strong)           UIColor *lineColor;
@property (nonatomic, assign)           CGFloat lineWidth;

@property (nonatomic, strong)           UIColor *thumbColor;
@property (nonatomic, strong)           UIColor *backgroundColor;

@property (nonatomic, strong, readonly) LTRasterImage *originalImage;

- (BOOL)applyDeskew:(NSError **)error;
- (void)resetThumbs;

@end
