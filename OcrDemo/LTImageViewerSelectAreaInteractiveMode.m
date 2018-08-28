//
//  LTImageViewerSelectAreaInteractiveMode.m
//  OcrDemo
//
//  Created by lead on 5/25/16.
//  Copyright © 2017 LEAD Technologies, Inc. All rights reserved.
//

#import "LTImageViewerSelectAreaInteractiveMode.h"
#import <Leadtools.Controls/LTImageViewerInteractiveModeSubClassing.h>

#pragma mark - Preprocessor Macros

#define selectAreaHitTest    (CGFloat)40.0
#define selectAreaThumbWidth (CGFloat)5.0

#pragma mark - Private Function Declarations

static inline CGFloat distanceBetweenPoints(CGPoint point1, CGPoint point2);

static inline CGFloat CGRectGetLeft(CGRect rect);
static inline CGFloat CGRectGetRight(CGRect rect);
static inline CGFloat CGRectGetTop(CGRect rect);
static inline CGFloat CGRectGetBottom(CGRect rect);
static inline CGPoint CGRectGetTopLeft(CGRect rect);
static inline CGPoint CGRectGetTopRight(CGRect rect);
static inline CGPoint CGRectGetBottomLeft(CGRect rect);
static inline CGPoint CGRectGetBottomRight(CGRect rect);

static inline CGRect CGRectSetLeft(CGRect rect, CGFloat left);
static inline CGRect CGRectSetRight(CGRect rect, CGFloat right);
static inline CGRect CGRectSetTop(CGRect rect, CGFloat top);
static inline CGRect CGRectSetBottom(CGRect rect, CGFloat bottom);
static inline CGRect CGRectSetTopLeft(CGRect rect, CGPoint point);
static inline CGRect CGRectSetTopRight(CGRect rect, CGPoint point);
static inline CGRect CGRectSetBottomLeft(CGRect rect, CGPoint point);
static inline CGRect CGRectSetBottomRight(CGRect rect, CGPoint point);

#pragma mark - Private Type Declarations

typedef NS_ENUM(NSInteger, SelectAreaActivePoint) {
    SelectAreaActivePointNone,
    SelectAreaActivePointTopLeft,
    SelectAreaActivePointTopRight,
    SelectAreaActivePointBottomLeft,
    SelectAreaActivePointBottomRight,
    SelectAreaActivePointBody
};

#pragma mark - Class (SelectAreaView) Interface

@interface SelectAreaView : UIView

@property (nonatomic, weak) LTImageViewerSelectAreaInteractiveMode *interactiveMode;

- (instancetype)initWithInteractiveMode:(LTImageViewerSelectAreaInteractiveMode *)interactiveMode;

@end

#pragma mark - Class (LTImageViewerSelectAreaInteractiveMode) Extension

@interface LTImageViewerSelectAreaInteractiveMode()

@property (nonatomic, assign) CGPoint topLeft;
@property (nonatomic, assign) CGPoint topRight;
@property (nonatomic, assign) CGPoint bottomLeft;
@property (nonatomic, assign) CGPoint bottomRight;

@property (nonatomic, assign) CGPoint previousPoint;

@property (nonatomic, assign) SelectAreaActivePoint activePoint;
@property (nonatomic, strong) SelectAreaView *overlayView;

@end

#pragma mark - Class (LTImageViewerSelectAreaInteractiveMode) Implementation

@implementation LTImageViewerSelectAreaInteractiveMode

#pragma mark - Property Synthesis

@synthesize lineColor = _lineColor, lineWidth = _lineWidth, thumbColor = _thumbColor, backgroundColor = _backgroundColor, selectedArea = _selectedArea, topLeft = _topLeft, topRight = _topRight, bottomLeft = _bottomLeft, bottomRight = _bottomRight, previousPoint = _previousPoint, activePoint = _activePoint, overlayView = _overlayView;

- (void)setSelectedArea:(CGRect)selectedArea {
    _selectedArea = selectedArea;
    
    _topLeft     = CGPointMake(CGRectGetLeft(selectedArea), CGRectGetTop(selectedArea));
    _topRight    = CGPointMake(CGRectGetRight(selectedArea), CGRectGetTop(selectedArea));
    _bottomLeft  = CGPointMake(CGRectGetLeft(selectedArea), CGRectGetBottom(selectedArea));
    _bottomRight = CGPointMake(CGRectGetRight(selectedArea), CGRectGetBottom(selectedArea));
    
//    [_overlayView setNeedsDisplay];
}

- (NSString *)name {
    return @"Select Area";
}

#pragma mark - Initialization

- (instancetype)init {
    if (self = [super init]) {
        self.workOnImageRectangle = NO;
        self.overlayView          = [[SelectAreaView alloc] initWithInteractiveMode:self];
        self.lineColor            = [UIColor colorWithRed:0.2235 green:0.2275 blue:0.4235 alpha:1.0];
        self.lineWidth            = 2.0;
        self.thumbColor           = [UIColor colorWithRed:0.5529 green:0.6392 blue:1.0 alpha:1.0];
        self.backgroundColor      = [UIColor colorWithWhite:0.5 alpha:0.5];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

#pragma mark - KVO Methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"internalTransform"]) {
        const CGRect imageCoordinates = CGRectApplyAffineTransform(self.selectedArea, CGAffineTransformInvert(((NSValue *)change[NSKeyValueChangeOldKey]).CGAffineTransformValue));
        self.selectedArea = [self.imageViewer convertRect:imageCoordinates sourceType:LTCoordinateTypeImage destType:LTCoordinateTypeControl];
        
        self.overlayView.frame = CGRectMake(0.0, 0.0, self.imageViewer.bounds.size.width, self.imageViewer.bounds.size.height);
        [self.overlayView setNeedsDisplay];
    }
    else if ([keyPath isEqualToString:@"rasterImage"] || [keyPath isEqualToString:@"image"])
        [self resetThumbs];
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark - LTImageViewerInteractiveMode Method Overrides

- (BOOL)canStartWork:(UIGestureRecognizer *)gestureRecognizer {
    if (![super canStartWork:gestureRecognizer]) return NO;
    if (self.imageViewer.rasterImage == nil)     return NO;
    
    const SelectAreaActivePoint activePoint = [self findActivePoint:[gestureRecognizer locationInView:self.imageViewer]];
    if (activePoint != SelectAreaActivePointNone) {
        self.activePoint = activePoint;
        return YES;
    }
    
    return NO;
}

- (void)start:(LTImageViewer *)viewer {
    [super start:viewer];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectAreaPointerDown:) name:LTInteractiveServicePointerDownNotification object:self.interactiveService];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectAreaPointerDrag:) name:LTInteractiveServicePointerDragNotification object:self.interactiveService];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectAreaPointerUp:) name:LTInteractiveServicePointerUpNotification object:self.interactiveService];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectAreaPointerUp:) name:LTInteractiveServiceDoubleTapNotification object:self.interactiveService];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(imageDidChange:) name:LTRasterImageDidChangeNotification object:nil];
    
    [viewer addObserver:self forKeyPath:@"internalTransform" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:NULL];
    [viewer addObserver:self forKeyPath:@"rasterImage" options:NSKeyValueObservingOptionNew context:NULL];
    [viewer addObserver:self forKeyPath:@"image" options:NSKeyValueObservingOptionNew context:NULL];
    
    if (viewer.rasterImage == nil) return;
    
    if (CGRectEqualToRect(self.selectedArea, CGRectZero))
        [self resetThumbs];
    else {
        self.overlayView.frame = CGRectMake(0.0, 0.0, self.imageViewer.bounds.size.width, self.imageViewer.bounds.size.height);
        [self.overlayView setNeedsDisplay];
    }
    
    [viewer addSubview:self.overlayView];
}

- (void)stop:(LTImageViewer *)viewer {
    if (self.isStarted) {
        [self.overlayView removeFromSuperview];
        
        [[NSNotificationCenter defaultCenter] removeObserver:self name:LTInteractiveServicePointerDownNotification object:self.interactiveService];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:LTInteractiveServicePointerDragNotification object:self.interactiveService];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:LTInteractiveServicePointerUpNotification object:self.interactiveService];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:LTInteractiveServiceDoubleTapNotification object:self.interactiveService];
        [[NSNotificationCenter defaultCenter] removeObserver:self name:LTRasterImageDidChangeNotification object:nil];
        
        [viewer removeObserver:self forKeyPath:@"internalTransform"];
        [viewer removeObserver:self forKeyPath:@"rasterImage"];
        [viewer removeObserver:self forKeyPath:@"image"];
        
        [super stop:viewer];
    }
}

#pragma mark - Public Methods

- (void)resetThumbs {
    const CGRect imageSelectedArea   = [self.imageViewer convertRect:CGRectMake(self.imageViewer.imageSize.width * 0.25, self.imageViewer.imageSize.height * 0.25, self.imageViewer.imageSize.width * 0.5, self.imageViewer.imageSize.height * 0.5) sourceType:LTCoordinateTypeImage destType:LTCoordinateTypeControl];
    const CGRect controlSelectedArea = CGRectMake(self.imageViewer.bounds.size.width * 0.25, self.imageViewer.bounds.size.height * 0.25, self.imageViewer.bounds.size.width * 0.5, self.imageViewer.bounds.size.height * 0.5);
    
    self.selectedArea = CGRectMake(imageSelectedArea.size.width < controlSelectedArea.size.width ? imageSelectedArea.origin.x : controlSelectedArea.origin.x, imageSelectedArea.size.height < controlSelectedArea.size.height ? imageSelectedArea.origin.y : controlSelectedArea.origin.y, MIN(imageSelectedArea.size.width, controlSelectedArea.size.width), MIN(imageSelectedArea.size.height, controlSelectedArea.size.height));
    
    self.overlayView.frame = CGRectMake(0.0, 0.0, self.imageViewer.bounds.size.width, self.imageViewer.bounds.size.height);
    [self.overlayView setNeedsDisplay];
}

#pragma mark - Private Methods

- (void)selectAreaPointerDown:(NSNotification *)notification {
    UIGestureRecognizer * const gestureRecognizer = (UIGestureRecognizer *)notification.userInfo[LTInteractiveServiceGestureRecognizerKey];
    
    if (![self canStartWork:gestureRecognizer] || self.imageViewer.rasterImage == nil)
        return;
    
    if (!self.isWorking)
        [self onWorkStarted:gestureRecognizer];
    
    self.previousPoint = [gestureRecognizer locationInView:self.imageViewer];
}

- (void)selectAreaPointerDrag:(NSNotification *)notification {
    if (self.isWorking) {
        UIGestureRecognizer * const gestureRecognizer = (UIGestureRecognizer *)notification.userInfo[LTInteractiveServiceGestureRecognizerKey];
        const CGPoint point = [gestureRecognizer locationInView:self.imageViewer];
        
        const CGSize size   = self.imageViewer.imageSize;
        const CGRect rect   = [self.imageViewer convertRect:CGRectMake(0.0, 0.0, size.width, size.height) sourceType:LTCoordinateTypeImage destType:LTCoordinateTypeControl];
        
        CGRect newSelectedArea = self.selectedArea;
        
        switch (self.activePoint) {
            case SelectAreaActivePointTopLeft:
                newSelectedArea = CGRectSetTopLeft(newSelectedArea, point);
                break;
                
            case SelectAreaActivePointTopRight:
                newSelectedArea = CGRectSetTopRight(newSelectedArea, point);
                break;
                
            case SelectAreaActivePointBottomLeft:
                newSelectedArea = CGRectSetBottomLeft(newSelectedArea, point);
                break;
                
            case SelectAreaActivePointBottomRight:
                newSelectedArea = CGRectSetBottomRight(newSelectedArea, point);
                break;
                
            case SelectAreaActivePointBody:
                newSelectedArea.origin.x += point.x - self.previousPoint.x;
                newSelectedArea.origin.y += point.y - self.previousPoint.y;
                
            default: break;
        }
        
        if (CGRectGetTop(newSelectedArea) > CGRectGetTop(rect) && CGRectGetBottom(newSelectedArea) < CGRectGetBottom(rect) && CGRectGetTop(newSelectedArea) < CGRectGetBottom(newSelectedArea))
            self.selectedArea = CGRectSetTop(CGRectSetBottom(self.selectedArea, CGRectGetBottom(newSelectedArea)), CGRectGetTop(newSelectedArea));
        if (CGRectGetLeft(newSelectedArea) > CGRectGetLeft(rect) && CGRectGetRight(newSelectedArea) < CGRectGetRight(rect) && CGRectGetLeft(newSelectedArea) < CGRectGetRight(newSelectedArea))
            self.selectedArea = CGRectSetLeft(CGRectSetRight(self.selectedArea, CGRectGetRight(newSelectedArea)), CGRectGetLeft(newSelectedArea));
        
        self.previousPoint = point;
        [self.overlayView setNeedsDisplay];
    }
}

- (void)selectAreaPointerUp:(NSNotification *)notification {
    if (self.isWorking) {
        UIGestureRecognizer * const gestureRecognizer = (UIGestureRecognizer *)notification.userInfo[LTInteractiveServiceGestureRecognizerKey];
        
        [self onWorkCompleted:gestureRecognizer];
        self.activePoint = SelectAreaActivePointNone;
        
        [self.overlayView setNeedsDisplay];
    }
}

- (void)imageDidChange:(NSNotification *)notification {
    if (notification.object == self.imageViewer.rasterImage) {
        if (notification.userInfo != nil && notification.userInfo[LTRasterImageChangedNotificationFlags] != nil && [notification.userInfo[LTRasterImageChangedNotificationFlags] isKindOfClass:[NSNumber class]]) {
            const NSUInteger value = ((NSNumber *)notification.userInfo[LTRasterImageChangedNotificationFlags]).unsignedIntegerValue;
            const NSUInteger mask  = (LTRasterImageChangedFlagsSize | LTRasterImageChangedFlagsViewPerspective | LTRasterImageChangedFlagsPage | LTRasterImageChangedFlagsPageCount);
            
            if ((value & mask) != (NSUInteger)LTRasterImageChangedFlagsNone)
                [self resetThumbs];
        }
        else
            [self resetThumbs];
    }
}



- (SelectAreaActivePoint)findActivePoint:(CGPoint)point {
    const CGPoint centerPoint = CGPointMake((self.topLeft.x + self.bottomRight.x) * 0.5, (self.topLeft.y + self.bottomRight.y) * 0.5);
    NSDictionary<NSNumber *, NSNumber *> * const distances = @{ @(SelectAreaActivePointTopLeft) : @(distanceBetweenPoints(point, self.topLeft)), @(SelectAreaActivePointTopRight) : @(distanceBetweenPoints(point, self.topRight)), @(SelectAreaActivePointBottomLeft) : @(distanceBetweenPoints(point, self.bottomLeft)), @(SelectAreaActivePointBottomRight) : @(distanceBetweenPoints(point, self.bottomRight)), @(SelectAreaActivePointBody) : @(distanceBetweenPoints(point, centerPoint)) };
    NSArray<NSNumber *> * const sortedKeys = [distances keysSortedByValueUsingComparator:^NSComparisonResult (NSNumber *d1, NSNumber *d2) {
        return d1.doubleValue < d2.doubleValue ? NSOrderedAscending : d1.doubleValue > d2.doubleValue ? NSOrderedDescending : NSOrderedSame;
    }];
    
    for (NSNumber *key in sortedKeys) {
        const SelectAreaActivePoint activePoint = key.integerValue;
        const CGFloat distance                  = (CGFloat)distances[key].doubleValue;
        
        if (distance <= selectAreaHitTest) {
            switch (activePoint) {
                case SelectAreaActivePointBody:
                    if (CGRectContainsPoint(self.selectedArea, point)) return activePoint;
                    break;
                    
                default:
                    return activePoint;
            }
        }
        else if (activePoint == SelectAreaActivePointBody && CGRectContainsPoint(self.selectedArea, point))
            return activePoint;
    }
    
    return SelectAreaActivePointNone;
}

@end

#pragma mark - Class (SelectAreaView) Implementation

@implementation SelectAreaView

#pragma mark - Property Synthesis

@synthesize interactiveMode = _interactiveMode;

#pragma mark - Initialization

- (instancetype)initWithInteractiveMode:(LTImageViewerSelectAreaInteractiveMode *)interactiveMode {
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
    [super drawRect:rect];
    
    const CGFloat thumbWidth   = selectAreaThumbWidth;
    const CGContextRef context = UIGraphicsGetCurrentContext();
    
    CGContextSaveGState(context);
    
    UIBezierPath * const path = [UIBezierPath bezierPathWithRect:CGRectInfinite];
    [path appendPath:[UIBezierPath bezierPathWithRect:_interactiveMode.selectedArea]];
    path.usesEvenOddFillRule = YES;
    [path addClip];
    
    [_interactiveMode.backgroundColor setFill];
    [[UIBezierPath bezierPathWithRect:rect] fill];
    
    CGContextRestoreGState(context);
    CGContextSaveGState(context);
    
    CGContextSetStrokeColorWithColor(context, _interactiveMode.lineColor.CGColor);
    CGContextSetFillColorWithColor(context, [UIColor clearColor].CGColor);
    CGContextSetLineWidth(context, _interactiveMode.lineWidth);
    CGContextStrokeRect(context, _interactiveMode.selectedArea);
    
    CGContextRestoreGState(context);
    CGContextSaveGState(context);
    
    const CGPoint points[4] = { _interactiveMode.topLeft, _interactiveMode.topRight, _interactiveMode.bottomRight, _interactiveMode.bottomLeft };
    for (NSUInteger i = 0; i < 4; i++) {
        const CGRect bounds = CGRectMake(points[i].x - thumbWidth, points[i].y - thumbWidth, thumbWidth * 2.0, thumbWidth * 2.0);
        
        CGContextSetFillColorWithColor(context, _interactiveMode.thumbColor.CGColor);
        CGContextFillRect(context, bounds);
        CGContextSetStrokeColorWithColor(context, _interactiveMode.thumbColor.CGColor);
        CGContextStrokeRect(context, bounds);
    }
    
    CGContextRestoreGState(context);
}

#pragma mark - Private Methods

- (CGPathRef)pathForBackgroundMask:(CGRect)outerFrame innerFrame:(CGRect)innerFrame {
    CGMutablePathRef path = CGPathCreateMutable();
    
    CGPathMoveToPoint(path, NULL, CGRectGetLeft(outerFrame), CGRectGetTop(outerFrame));
    CGPathAddLineToPoint(path, NULL, CGRectGetRight(outerFrame), CGRectGetTop(outerFrame));
    CGPathAddLineToPoint(path, NULL, CGRectGetRight(outerFrame), CGRectGetBottom(outerFrame));
    CGPathAddLineToPoint(path, NULL, CGRectGetLeft(outerFrame), CGRectGetBottom(outerFrame));
    
    CGPathMoveToPoint(path, NULL, CGRectGetLeft(innerFrame), CGRectGetTop(innerFrame));
    CGPathAddLineToPoint(path, NULL, CGRectGetRight(innerFrame), CGRectGetTop(innerFrame));
    CGPathAddLineToPoint(path, NULL, CGRectGetRight(innerFrame), CGRectGetBottom(innerFrame));
    CGPathAddLineToPoint(path, NULL, CGRectGetLeft(innerFrame), CGRectGetBottom(innerFrame));
    
    return path;
}

@end

#pragma mark - Private Function Defintions

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-function"

static inline CGFloat distanceBetweenPoints(CGPoint point1, CGPoint point2) {
    const CGFloat dx = point2.x - point1.x;
    const CGFloat dy = point2.y - point1.y;
    
    return sqrt((dx * dx) + (dy * dy));
}

static inline CGFloat CGRectGetLeft(CGRect rect) {
    return rect.origin.x;
}

static inline CGFloat CGRectGetRight(CGRect rect) {
    return rect.origin.x + rect.size.width;
}

static inline CGFloat CGRectGetTop(CGRect rect) {
    return rect.origin.y;
}

static inline CGFloat CGRectGetBottom(CGRect rect) {
    return rect.origin.y + rect.size.height;
}

static inline CGPoint CGRectGetTopLeft(CGRect rect) {
    return CGPointMake(CGRectGetLeft(rect), CGRectGetTop(rect));
}

static inline CGPoint CGRectGetTopRight(CGRect rect) {
    return CGPointMake(CGRectGetRight(rect), CGRectGetTop(rect));
}

static inline CGPoint CGRectGetBottomLeft(CGRect rect) {
    return CGPointMake(CGRectGetLeft(rect), CGRectGetBottom(rect));
}

static inline CGPoint CGRectGetBottomRight(CGRect rect) {
    return CGPointMake(CGRectGetRight(rect), CGRectGetBottom(rect));
}

static inline CGRect CGRectSetLeft(CGRect rect, CGFloat left) {
    rect.size.width -= (left - rect.origin.x);
    rect.origin.x    = left;
    return rect;
}

static inline CGRect CGRectSetRight(CGRect rect, CGFloat right) {
    rect.size.width = right - rect.origin.x;
    return rect;
}

static inline CGRect CGRectSetTop(CGRect rect, CGFloat top) {
    rect.size.height -= (top - rect.origin.y);
    rect.origin.y     = top;
    return rect;
}

static inline CGRect CGRectSetBottom(CGRect rect, CGFloat bottom) {
    rect.size.height = bottom - rect.origin.y;
    return rect;
}

static inline CGRect CGRectSetTopLeft(CGRect rect, CGPoint point) {
    return CGRectSetLeft(CGRectSetTop(rect, point.y), point.x);
}

static inline CGRect CGRectSetTopRight(CGRect rect, CGPoint point) {
    return CGRectSetRight(CGRectSetTop(rect, point.y), point.x);
}

static inline CGRect CGRectSetBottomLeft(CGRect rect, CGPoint point) {
    return CGRectSetLeft(CGRectSetBottom(rect, point.y), point.x);
}

static inline CGRect CGRectSetBottomRight(CGRect rect, CGPoint point) {
    return CGRectSetRight(CGRectSetBottom(rect, point.y), point.x);
}

#pragma clang diagnostic pop
