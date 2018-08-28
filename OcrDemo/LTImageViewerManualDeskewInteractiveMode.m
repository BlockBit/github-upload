//
//  LTImageViewerManualDeskewInteractiveMode.m
//  OcrDemo
//
//  Created by lead on 9/22/16.
//  Copyright © 2017 LEAD Technologies, Inc. All rights reserved.
//

#import "LTImageViewerManualDeskewInteractiveMode.h"
#import <Leadtools.Controls/LTImageViewerInteractiveModeSubClassing.h>

#pragma mark - Preprocessor Macros

#define manualDeskewHitTest                (CGFloat)50.0
#define manualDeskewDeltaThreshold         (CGFloat)20.0
#define manualDeskewMinimumPointSeparation (CGFloat)20.0
#define manualDeskewThumbWidth             (CGFloat)5.0

#pragma mark - Private Function Declarations

static inline CGFloat distanceBetweenPoints(CGPoint point1, CGPoint point2) {
    const CGFloat dx = point2.x - point1.x;
    const CGFloat dy = point2.y - point1.y;
    
    return sqrt((dx * dx) + (dy * dy));
}

#pragma mark - Private Type Declarations

typedef NS_ENUM(NSInteger, ManualDeskewActivePoint) {
    ManualDeskewActivePointNone,
    ManualDeskewActivePointTopLeft,
    ManualDeskewActivePointTopRight,
    ManualDeskewActivePointBottomLeft,
    ManualDeskewActivePointBottomRight,
    ManualDeskewActivePointTopMid,
    ManualDeskewActivePointLeftMid,
    ManualDeskewActivePointRightMid,
    ManualDeskewActivePointBottomMid
};

#pragma mark - Class (ManualDeskewView) Interface

@interface ManualDeskewView : UIView

@property (nonatomic, weak) LTImageViewerManualDeskewInteractiveMode *interactiveMode;

- (instancetype)initWithInteractiveMode:(LTImageViewerManualDeskewInteractiveMode *)interactiveMode;

@end

#pragma mark - Class (LTImageViewerManualDeskewInteractiveMode) Extension

@interface LTImageViewerManualDeskewInteractiveMode()

@property (nonatomic, assign) CGPoint topLeft;
@property (nonatomic, assign) CGPoint topRight;
@property (nonatomic, assign) CGPoint bottomLeft;
@property (nonatomic, assign) CGPoint bottomRight;

@property (nonatomic, assign) CGPoint topMid;
@property (nonatomic, assign) CGPoint bottomMid;
@property (nonatomic, assign) CGPoint leftMid;
@property (nonatomic, assign) CGPoint rightMid;

@property (nonatomic, strong) LTRasterImage *originalImage;

@property (nonatomic, assign) ManualDeskewActivePoint activePoint;
@property (nonatomic, strong) ManualDeskewView *overlayView;

@end

#pragma mark - Class (LTImageViewerManualDeskewInteractiveMode) Implementation

@implementation LTImageViewerManualDeskewInteractiveMode

#pragma mark - Property Synthesis

@synthesize topLeft = _topLeft, topRight = _topRight, bottomLeft = _bottomLeft, bottomRight = _bottomRight, lineColor = _lineColor, lineWidth = _lineWidth, thumbColor = _thumbColor, backgroundColor = _backgroundColor, originalImage = _originalImage, activePoint = _activePoint, overlayView = _overlayView;
@dynamic topMid, bottomMid, leftMid, rightMid;

- (void)setTopLeft:(CGPoint)point {
    BOOL changeX = NO, changeY = NO;
    
    if (point.x + manualDeskewMinimumPointSeparation < _topRight.x)   changeX = YES;
    if (point.y + manualDeskewMinimumPointSeparation < _bottomLeft.y) changeY = YES;
    
    if (changeX && [self isValidX:point.x]) _topLeft.x = point.x;
    if (changeY && [self isValidY:point.y]) _topLeft.y = point.y;
}

- (void)setTopRight:(CGPoint)point {
    BOOL changeX = NO, changeY = NO;
    
    if (point.x - manualDeskewMinimumPointSeparation > _topLeft.x)     changeX = YES;
    if (point.y - manualDeskewMinimumPointSeparation < _bottomRight.y) changeY = YES;
    
    if (changeX && [self isValidX:point.x]) _topRight.x = point.x;
    if (changeY && [self isValidY:point.y]) _topRight.y = point.y;
}

- (void)setBottomLeft:(CGPoint)point {
    BOOL changeX = NO, changeY = NO;
    
    if (point.x + manualDeskewMinimumPointSeparation < _bottomRight.x) changeX = YES;
    if (point.y - manualDeskewMinimumPointSeparation > _topLeft.y)     changeY = YES;
    
    if (changeX && [self isValidX:point.x]) _bottomLeft.x = point.x;
    if (changeY && [self isValidY:point.y]) _bottomLeft.y = point.y;
}

- (void)setBottomRight:(CGPoint)point {
    BOOL changeX = NO, changeY = NO;
    
    if (point.x - manualDeskewMinimumPointSeparation > _bottomLeft.x) changeX = YES;
    if (point.y - manualDeskewMinimumPointSeparation > _topRight.y)   changeY = YES;
    
    if (changeX && [self isValidX:point.x]) _bottomRight.x = point.x;
    if (changeY && [self isValidY:point.y]) _bottomRight.y = point.y;
}

- (CGPoint)topMid {
    return CGPointMake((_topLeft.x + _topRight.x) * 0.5, (_topLeft.y + _topRight.y) * 0.5);
}

- (void)setTopMid:(CGPoint)point {
    const CGFloat dX = point.x - (_topLeft.x + _topRight.x) * 0.5;
    const CGFloat dY = point.y - (_topLeft.y + _topRight.y) * 0.5;
    
    if ([self isValidX:_topRight.x + dX] && [self isValidX:_topLeft.x + dX]) {
        _topRight.x += dX;
        _topLeft.x  += dX;
    }
    
    if ((_bottomLeft.y - _topLeft.y - dY) > manualDeskewDeltaThreshold && (_bottomRight.y - _topRight.y - dY) > manualDeskewDeltaThreshold && [self isValidY:_topRight.y + dY] && [self isValidY:_topLeft.y + dY]) {
        _topRight.y += dY;
        _topLeft.y  += dY;
    }
}

- (CGPoint)bottomMid {
    return CGPointMake((_bottomLeft.x + _bottomRight.x) * 0.5, (_bottomLeft.y + _bottomRight.y) * 0.5);
}

- (void)setBottomMid:(CGPoint)point {
    const CGFloat dX = point.x - (_bottomLeft.x + _bottomRight.x) * 0.5;
    const CGFloat dY = point.y - (_bottomLeft.y + _bottomRight.y) * 0.5;
    
    if ([self isValidX:_bottomRight.x + dX] && [self isValidX:_bottomLeft.x + dX]) {
        _bottomRight.x += dX;
        _bottomLeft.x  += dX;
    }
    
    if ((_bottomLeft.y - _topLeft.y + dY) > manualDeskewDeltaThreshold && (_bottomRight.y - _topRight.y + dY) > manualDeskewDeltaThreshold && [self isValidY:_bottomRight.y + dY] && [self isValidY:_bottomLeft.y + dY]) {
        _bottomRight.y += dY;
        _bottomLeft.y  += dY;
    }
}

- (CGPoint)leftMid {
    return CGPointMake((_topLeft.x + _bottomLeft.x) * 0.5, (_topLeft.y + _bottomLeft.y) * 0.5);
}

- (void)setLeftMid:(CGPoint)point {
    const CGFloat dX = point.x - (_topLeft.x + _bottomLeft.x) * 0.5;
    const CGFloat dY = point.y - (_topLeft.y + _bottomLeft.y) * 0.5;
    
    if ([self isValidY:_topLeft.y + dY] && [self isValidY:_bottomLeft.y + dY]) {
        _topLeft.y    += dY;
        _bottomLeft.y += dY;
    }
    
    if ((_topRight.x - _topLeft.x - dX) > manualDeskewDeltaThreshold && (_bottomRight.x - _bottomLeft.x - dX) > manualDeskewDeltaThreshold && [self isValidX:_bottomLeft.x + dX] && [self isValidX:_topLeft.x + dX]) {
        _topLeft.x    += dX;
        _bottomLeft.x += dX;
    }
}

- (CGPoint)rightMid {
    return CGPointMake((_topRight.x + _bottomRight.x) * 0.5, (_topRight.y + _bottomRight.y) * 0.5);
}

- (void)setRightMid:(CGPoint)point {
    const CGFloat dX = point.x - (_topRight.x + _bottomRight.x) * 0.5;
    const CGFloat dY = point.y - (_topRight.y + _bottomRight.y) * 0.5;
    
    if ([self isValidY:_topRight.y + dY] && [self isValidY:_bottomRight.y + dY]) {
        _topRight.y    += dY;
        _bottomRight.y += dY;
    }
    
    if ((_bottomRight.x - _bottomLeft.x + dX) > manualDeskewDeltaThreshold && (_topRight.x - _topLeft.x + dX) > manualDeskewDeltaThreshold && [self isValidX:_bottomRight.x + dX] && [self isValidX:_topRight.x + dX]) {
        _topRight.x    += dX;
        _bottomRight.x += dX;
    }
}

- (NSString *)name {
    return @"Manual Deskew";
}

- (BOOL)restartOnImageChange {
    return NO;
}

#pragma mark - Initialization

- (instancetype)init {
    if (self = [super init]) {
        self.workOnImageRectangle = NO;
        self.overlayView          = [[ManualDeskewView alloc] initWithInteractiveMode:self];
        self.lineColor            = [UIColor colorWithRed:0.2235 green:0.2275 blue:0.4235 alpha:1.0];
        self.lineWidth            = 2.0;
        self.thumbColor           = [UIColor colorWithRed:0.5529 green:0.6392 blue:1.0 alpha:1.0];
        self.backgroundColor      = [UIColor colorWithWhite:1.0 alpha:0.0];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

#pragma mark - KVO Methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"internalTransform"])
        [self resetThumbs];
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark - LTImageViewerInteractiveMode Method Overrides

- (BOOL)canStartWork:(UIGestureRecognizer *)gestureRecognizer {
    if (![super canStartWork:gestureRecognizer]) return NO;
    
    const ManualDeskewActivePoint activePoint = [self findActivePoint:[gestureRecognizer locationInView:self.imageViewer]];
    if (activePoint != ManualDeskewActivePointNone) {
        self.activePoint = activePoint;
        return YES;
    }
    
    return NO;
}

- (void)start:(LTImageViewer *)viewer {
    [super start:viewer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deskewPointerDown:) name:LTInteractiveServicePointerDownNotification object:self.interactiveService];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deskewPointerDrag:) name:LTInteractiveServicePointerDragNotification object:self.interactiveService];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deskewPointerUp:) name:LTInteractiveServicePointerUpNotification object:self.interactiveService];
    
    [viewer addObserver:self forKeyPath:@"internalTransform" options:NSKeyValueObservingOptionNew context:NULL];
    
    if (viewer.rasterImage == nil) return;
    
    [viewer beginUpdate];
    
    viewer.scrollMode               = LTImageViewerScrollModeHidden;
    viewer.imageHorizontalAlignment = LTControlAlignmentCenter;
    viewer.imageVerticalAlignment   = LTControlAlignmentCenter;
    viewer.rotateAngle              = 0.0;
    
    [viewer endUpdate];
    
    self.originalImage = viewer.rasterImage;
    
    [self setAndFitImage];
    [self resetThumbs];
    
    self.overlayView.frame = CGRectMake(0.0, 0.0, viewer.bounds.size.width, viewer.bounds.size.height);
    [viewer addSubview:self.overlayView];
}

- (void)stop:(LTImageViewer *)viewer {
    if (self.isStarted) {
        [self.overlayView removeFromSuperview];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:LTInteractiveServicePointerDownNotification object:self.interactiveService];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:LTInteractiveServicePointerDragNotification object:self.interactiveService];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:LTInteractiveServicePointerUpNotification object:self.interactiveService];
        
        [viewer removeObserver:self forKeyPath:@"internalTransform"];
        
        [viewer beginUpdate];
        
        viewer.scrollMode               = LTImageViewerScrollModeAuto;
        viewer.imageHorizontalAlignment = LTControlAlignmentCenter;
        viewer.imageVerticalAlignment   = LTControlAlignmentCenter;
        viewer.scaleFactor              = 1.0;
        viewer.aspectRatioCorrection    = 1.0;
        viewer.sizeMode                 = LTImageViewerSizeModeFitAlways;
        
        [viewer endUpdate];
        
        [super stop:viewer];
    }
}

#pragma mark - Public Methods

- (BOOL)applyDeskew:(NSError *__autoreleasing *)error {
    if (self.imageViewer != nil && self.originalImage != nil) {
        NSMutableArray<NSValue *> * const points = [NSMutableArray arrayWithCapacity:4];
        
        [points addObject:[NSValue valueWithLeadPoint:LeadPointFromCGPoint([self.imageViewer convertPoint:self.topLeft sourceType:LTCoordinateTypeControl destType:LTCoordinateTypeImage])]];
        [points addObject:[NSValue valueWithLeadPoint:LeadPointFromCGPoint([self.imageViewer convertPoint:self.topRight sourceType:LTCoordinateTypeControl destType:LTCoordinateTypeImage])]];
        [points addObject:[NSValue valueWithLeadPoint:LeadPointFromCGPoint([self.imageViewer convertPoint:self.bottomRight sourceType:LTCoordinateTypeControl destType:LTCoordinateTypeImage])]];
        [points addObject:[NSValue valueWithLeadPoint:LeadPointFromCGPoint([self.imageViewer convertPoint:self.bottomLeft sourceType:LTCoordinateTypeControl destType:LTCoordinateTypeImage])]];
        
        LTKeyStoneCommand * const keystoneCommand = [[LTKeyStoneCommand alloc] initWithPolygonPoints:points];
        if (![keystoneCommand run:self.originalImage error:error])
            return NO;
        
        self.imageViewer.rasterImage = keystoneCommand.transformedImage;
        [self resetThumbs];
    }
    
    return YES;
}

- (void)resetThumbs {
    if (self.imageViewer != nil) {
        const CGFloat value = self.imageViewer.rasterImage.width / 20.0;
        
        _topLeft     = [self.imageViewer convertPoint:CGPointMake(value, value) sourceType:LTCoordinateTypeImage destType:LTCoordinateTypeControl];
        _topRight    = [self.imageViewer convertPoint:CGPointMake(self.imageViewer.rasterImage.width - value, value) sourceType:LTCoordinateTypeImage destType:LTCoordinateTypeControl];
        _bottomRight = [self.imageViewer convertPoint:CGPointMake(self.imageViewer.rasterImage.width - value, self.imageViewer.rasterImage.height - value) sourceType:LTCoordinateTypeImage destType:LTCoordinateTypeControl];
        _bottomLeft  = [self.imageViewer convertPoint:CGPointMake(value, self.imageViewer.rasterImage.height - value) sourceType:LTCoordinateTypeImage destType:LTCoordinateTypeControl];
        
        [self.overlayView setNeedsDisplay];
    }
}

#pragma mark - Private Methods

- (void)deskewPointerDown:(NSNotification *)notification {
    UIGestureRecognizer * const gestureRecognizer = (UIGestureRecognizer *)notification.userInfo[LTInteractiveServiceGestureRecognizerKey];
    if (![self canStartWork:gestureRecognizer] || self.imageViewer.rasterImage == nil || self.isWorking)
        return;
    
    [self onWorkStarted:gestureRecognizer];
}

- (void)deskewPointerDrag:(NSNotification *)notification {
    if (self.isWorking) {
        UIGestureRecognizer * const gestureRecognizer = (UIGestureRecognizer *)notification.userInfo[LTInteractiveServiceGestureRecognizerKey];
        const CGPoint point = [gestureRecognizer locationInView:self.imageViewer];
        
        if (self.activePoint != ManualDeskewActivePointNone) {
            switch (self.activePoint) {
                case ManualDeskewActivePointTopLeft:     self.topLeft = point; break;
                case ManualDeskewActivePointTopRight:    self.topRight = point; break;
                case ManualDeskewActivePointBottomLeft:  self.bottomLeft = point; break;
                case ManualDeskewActivePointBottomRight: self.bottomRight = point; break;
                case ManualDeskewActivePointTopMid:      self.topMid = point; break;
                case ManualDeskewActivePointBottomMid:   self.bottomMid = point; break;
                case ManualDeskewActivePointLeftMid:     self.leftMid = point; break;
                case ManualDeskewActivePointRightMid:    self.rightMid = point; break;
                default:                                 break;
            }
        }
        
        [self.overlayView setNeedsDisplay];
    }
}

- (void)deskewPointerUp:(NSNotification *)notification {
    if (self.isWorking) {
        UIGestureRecognizer * const gestureRecognizer = (UIGestureRecognizer *)notification.userInfo[LTInteractiveServiceGestureRecognizerKey];
        
        self.activePoint = ManualDeskewActivePointNone;
        
        [self onWorkCompleted:gestureRecognizer];
        [self.overlayView setNeedsDisplay];
    }
}

- (ManualDeskewActivePoint)findActivePoint:(CGPoint)point {
    if (distanceBetweenPoints(point, self.topLeft)     < manualDeskewHitTest) return ManualDeskewActivePointTopLeft;
    if (distanceBetweenPoints(point, self.topRight)    < manualDeskewHitTest) return ManualDeskewActivePointTopRight;
    if (distanceBetweenPoints(point, self.bottomLeft)  < manualDeskewHitTest) return ManualDeskewActivePointBottomLeft;
    if (distanceBetweenPoints(point, self.bottomRight) < manualDeskewHitTest) return ManualDeskewActivePointBottomRight;
    if (distanceBetweenPoints(point, self.topMid)      < manualDeskewHitTest) return ManualDeskewActivePointTopMid;
    if (distanceBetweenPoints(point, self.leftMid)     < manualDeskewHitTest) return ManualDeskewActivePointLeftMid;
    if (distanceBetweenPoints(point, self.rightMid)    < manualDeskewHitTest) return ManualDeskewActivePointRightMid;
    if (distanceBetweenPoints(point, self.bottomMid)   < manualDeskewHitTest) return ManualDeskewActivePointBottomMid;
    
    return ManualDeskewActivePointNone;
}

- (void)setAndFitImage {
    if (self.imageViewer != nil) {
        self.imageViewer.rasterImage = self.originalImage;
        
        [self.imageViewer beginUpdate];
        
        self.imageViewer.sizeMode                 = LTImageViewerSizeModeFitAlways;
        self.imageViewer.scaleFactor              = 1.0;
        self.imageViewer.restrictHiddenScrollMode = NO;
        
        [self.imageViewer endUpdate];
    }
}

- (BOOL)isValidX:(CGFloat)x {
    return x >= 0.0 && x <= _overlayView.bounds.size.width;
}

- (BOOL)isValidY:(CGFloat)y {
    return y >= 0.0 && y <= _overlayView.bounds.size.height;
}

@end

#pragma mark - Class (ManualDeskewView) Implementation

@implementation ManualDeskewView

#pragma mark - Property Synthesis

@synthesize interactiveMode = _interactiveMode;

#pragma Initialization

- (instancetype)initWithInteractiveMode:(LTImageViewerManualDeskewInteractiveMode *)interactiveMode {
    if (self = [super initWithFrame:CGRectZero]) {
        self.interactiveMode = interactiveMode;
        self.backgroundColor = [UIColor clearColor];
    }
    
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)init {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

#pragma mark - Drawing Methods

- (void)drawRect:(CGRect)rect {
    const CGContextRef context = UIGraphicsGetCurrentContext();
    
    if (_interactiveMode != nil) {
        CGPoint points[5]  = {_interactiveMode.topLeft, _interactiveMode.topRight, _interactiveMode.bottomRight, _interactiveMode.bottomLeft, _interactiveMode.topLeft};
        CGFloat thumbWidth = manualDeskewThumbWidth;
        
        UIGraphicsPushContext(context);
        CGContextSaveGState(context);
        
        CGContextAddLines(context, points, 5);
        CGContextSetStrokeColorWithColor(context, _interactiveMode.lineColor.CGColor);
        CGContextSetLineWidth(context, _interactiveMode.lineWidth);
        CGContextStrokePath(context);
        
        CGContextRestoreGState(context);
        CGContextSaveGState(context);
        
        for (NSUInteger i = 0; i < 4; i++) {
            const CGRect rect = CGRectMake(points[i].x - thumbWidth, points[i].y - thumbWidth, thumbWidth * 2.0, thumbWidth * 2.0);
            
            CGContextSetFillColorWithColor(context, _interactiveMode.thumbColor.CGColor);
            CGContextFillRect(context, rect);
            CGContextSetStrokeColorWithColor(context, _interactiveMode.thumbColor.CGColor);
            CGContextStrokeRect(context, rect);
        }
        
        CGContextRestoreGState(context);
        CGContextSaveGState(context);
        
        points[0] = _interactiveMode.topMid;
        points[1] = _interactiveMode.bottomMid;
        points[2] = _interactiveMode.leftMid;
        points[3] = _interactiveMode.rightMid;
        
        for (NSUInteger i = 0; i < 4; i++) {
            const CGRect rect = CGRectMake(points[i].x - thumbWidth, points[i].y - thumbWidth, thumbWidth * 2.0, thumbWidth * 2.0);
            
            CGContextSetFillColorWithColor(context, _interactiveMode.thumbColor.CGColor);
            CGContextFillEllipseInRect(context, rect);
            CGContextSetStrokeColorWithColor(context, _interactiveMode.thumbColor.CGColor);
            CGContextStrokeEllipseInRect(context, rect);
        }
        
        CGContextRestoreGState(context);
        CGContextSaveGState(context);
        
        if (_interactiveMode.activePoint != ManualDeskewActivePointNone) {
            CGPoint point = CGPointZero;
            
            switch (_interactiveMode.activePoint) {
                case ManualDeskewActivePointTopLeft:
                    point = _interactiveMode.topLeft;
                    break;
                    
                case ManualDeskewActivePointTopRight:
                    point = _interactiveMode.topRight;
                    break;
                    
                case ManualDeskewActivePointBottomLeft:
                    point = _interactiveMode.bottomLeft;
                    break;
                    
                case ManualDeskewActivePointBottomRight:
                    point = _interactiveMode.bottomRight;
                    break;
                    
                case ManualDeskewActivePointTopMid:
                    point = _interactiveMode.topMid;
                    break;
                    
                case ManualDeskewActivePointBottomMid:
                    point = _interactiveMode.bottomMid;
                    break;
                    
                case ManualDeskewActivePointLeftMid:
                    point = _interactiveMode.leftMid;
                    break;
                    
                case ManualDeskewActivePointRightMid:
                    point = _interactiveMode.rightMid;
                    break;
                    
                default: break;
            }
            
            if (!CGPointEqualToPoint(point, CGPointZero)) {
                CGContextSetLineWidth(context, 2.0);
                CGContextSetStrokeColorWithColor(context, _interactiveMode.thumbColor.CGColor);
                
                thumbWidth += 5;
                CGContextStrokeEllipseInRect(context, CGRectMake(point.x - thumbWidth, point.y - thumbWidth, thumbWidth * 2.0, thumbWidth * 2.0));
                thumbWidth += 5;
                CGContextStrokeEllipseInRect(context, CGRectMake(point.x - thumbWidth, point.y - thumbWidth, thumbWidth * 2.0, thumbWidth * 2.0));
            }
        }
        
        CGContextRestoreGState(context);
        UIGraphicsPopContext();
    }
}

@end
