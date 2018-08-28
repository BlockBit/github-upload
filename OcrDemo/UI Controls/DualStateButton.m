//
//  DualStateButton.m
//  OcrDemo
//
//  Copyright © 1991-2017 LEAD Technologies, Inc. All rights reserved.
//

#import "DualStateButton.h"

#pragma mark - Private Functions

static BOOL XOR(BOOL lhs, BOOL rhs) {
    return lhs ? !rhs : rhs;
}

#pragma mark - Class Extension

@interface DualStateButton()

@property (nonatomic, strong)           UIView *backgroundView;

@property (nonatomic, assign)           CGPoint lastTouchLocation;
@property (nonatomic, assign, readonly) CGFloat labelWidth;

@property (nonatomic, assign)           BOOL buttonValue;
@property (nonatomic, assign)           BOOL valueAtBeginTracking;
@property (nonatomic, assign)           BOOL currentVisualValue;
@property (nonatomic, assign)           BOOL didChangeWhileTracking;
@property (nonatomic, assign, readonly) BOOL canDisplayUpdates;

@end

#pragma mark - Class Implementation

@implementation DualStateButton

#pragma mark - Property Synthesis

@synthesize onBackgroundColor = _onBackgroundColor, offBackgroundColor = _offBackgroundColor, onForegroundColor = _onForegroundColor, offForegroundColor = _offForegroundColor, borderColor = _borderColor, cornerRadius = _cornerRadius, canTurnOnWithTouch = _canTurnOnWithTouch, canTurnOffWithTouch = _canTurnOffWithTouch, text = _text, textLabel = _textLabel, backgroundView = _backgroundView, lastTouchLocation = _lastTouchLocation, buttonValue = _buttonValue, valueAtBeginTracking = _valueAtBeginTracking, currentVisualValue = _currentVisualValue, didChangeWhileTracking = _didChangeWhileTracking, canDisplayUpdates = _canDisplayUpdates;
@dynamic on, labelWidth;

- (BOOL)on {
    return _buttonValue;
}

- (void)setOn:(BOOL)on {
    _buttonValue = on;
    [self showOn:on];
}

- (void)setOnBackgroundColor:(UIColor *)onBackgroundColor {
    if (self.on && !self.tracking) {
        _backgroundView.backgroundColor   = onBackgroundColor;
        _backgroundView.layer.borderColor = onBackgroundColor.CGColor;
    }
    
    _onBackgroundColor = onBackgroundColor;
}

- (void)setOffBackgroundColor:(UIColor *)offBackgroundColor {
    if (!self.on && !self.tracking)
        _backgroundView.backgroundColor = offBackgroundColor;
    
    _offBackgroundColor = offBackgroundColor;
}

- (void)setOnForegroundColor:(UIColor *)onForegroundColor {
    if (self.on && !self.tracking)
        _textLabel.textColor = onForegroundColor;
    
    _onForegroundColor = onForegroundColor;
}

- (void)setOffForegroundColor:(UIColor *)offForegroundColor {
    if (!self.on && !self.tracking)
        _textLabel.textColor = offForegroundColor;
    
    _offForegroundColor = offForegroundColor;
}

- (void)setBorderColor:(UIColor *)borderColor {
    if (!self.on)
        _backgroundView.layer.borderColor = borderColor.CGColor;
    
    _borderColor = borderColor;
}

- (void)setCornerRadius:(CGFloat)cornerRadius {
    _backgroundView.layer.cornerRadius = cornerRadius;
    _cornerRadius                      = cornerRadius;
}

- (void)setText:(NSString *)text {
    _textLabel.text = text;
    _text           = text;
}

- (void)setCanDisplayUpdates:(BOOL)canDisplayUpdates {
    _canDisplayUpdates = canDisplayUpdates;
    
    if (self.tracking)
        [self showOn:XOR(_valueAtBeginTracking, self.isTouchInside)];
}

- (CGFloat)labelWidth {
    return self.frame.size.width * 0.75;
}

#pragma mark - Initialization

- (instancetype)init {
    return [self initWithFrame:CGRectMake(0.0, 0.0, 50.0, 25.0)];
}

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self setup];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        [self setup];
    }
    
    return self;
}

#pragma mark - Custom Methods

- (void)showOn:(BOOL)on {
    if (on) {
        self.backgroundView.backgroundColor   = self.onBackgroundColor;
        self.backgroundView.layer.borderColor = self.borderColor.CGColor;
        self.textLabel.textColor              = self.onForegroundColor;
    }
    else {
        self.backgroundView.backgroundColor   = self.offBackgroundColor;
        self.backgroundView.layer.borderColor = self.borderColor.CGColor;
        self.textLabel.textColor              = self.offForegroundColor;
    }
    
    self.currentVisualValue = on;
}

- (void)setup {
    self.backgroundColor = [UIColor clearColor];
    
    _onBackgroundColor   = [UIColor colorWithRed:0.4667 green:0.5490 blue:0.9137 alpha:1.0];
    _offBackgroundColor  = [UIColor colorWithRed:0.1569 green:0.1647 blue:0.2353 alpha:1.0];
    _onForegroundColor   = [UIColor colorWithRed:0.1569 green:0.1647 blue:0.2353 alpha:1.0];
    _offForegroundColor  = [UIColor colorWithWhite:1.0 alpha:1.0];
    _borderColor         = [UIColor colorWithRed:0.4667 green:0.5490 blue:0.9137 alpha:1.0];
    _cornerRadius        = 3.0;
    _canTurnOnWithTouch  = YES;
    _canTurnOffWithTouch = YES;
    _lastTouchLocation   = CGPointMake(-1.0, -1.0);
    
    self.backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.frame.size.width, self.frame.size.height)];
    self.backgroundView.clipsToBounds          = YES;
    self.backgroundView.userInteractionEnabled = NO;
    self.backgroundView.backgroundColor        = [UIColor clearColor];
    self.backgroundView.layer.cornerRadius     = self.cornerRadius;
    self.backgroundView.layer.borderColor      = self.borderColor.CGColor;
    self.backgroundView.layer.borderWidth      = 1.0;
    [self addSubview:self.backgroundView];
    
    self.textLabel = [[UILabel alloc] initWithFrame:CGRectMake((self.frame.size.width - self.labelWidth) * 0.5, 0.0, self.labelWidth, self.frame.size.height)];
    self.textLabel.adjustsFontSizeToFitWidth = YES;
    self.textLabel.userInteractionEnabled    = NO;
    self.textLabel.backgroundColor           = [UIColor clearColor];
    self.textLabel.textAlignment             = NSTextAlignmentCenter;
    self.textLabel.textColor                 = self.onForegroundColor;
    self.textLabel.font                      = [UIFont fontWithName:@"Helvetica" size:16.0];
    [self.backgroundView addSubview:self.textLabel];
}

#pragma mark - UIControl Method Overrides

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    if ((self.on && !self.canTurnOffWithTouch) || (!self.on && !self.canTurnOnWithTouch))
        return NO;
    
    [super beginTrackingWithTouch:touch withEvent:event];
    
    self.valueAtBeginTracking   = self.on;
    self.didChangeWhileTracking = NO;
    self.canDisplayUpdates      = NO;
    self.lastTouchLocation      = [touch locationInView:self];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(300 * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
        if (self.tracking)
            self.canDisplayUpdates = YES;
    });
    
    return YES;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    [super continueTrackingWithTouch:touch withEvent:event];
    
    const BOOL lastTouchWasInside = self.isTouchInside;
    self.lastTouchLocation        = [touch locationInView:self];
    
    if (self.canDisplayUpdates && self.isTouchInside != lastTouchWasInside) {
        const BOOL showOn = XOR(self.valueAtBeginTracking, self.isTouchInside);
        [self showOn:showOn];
        
        if (showOn != self.on)
            self.didChangeWhileTracking = YES;
    }
    
    return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    [super endTrackingWithTouch:touch withEvent:event];
    
    self.lastTouchLocation   = CGPointMake(-1.0, -1.0);
    const BOOL previousValue = self.on;
    
    if (self.didChangeWhileTracking)
        self.on = self.currentVisualValue;
    else
        self.on = !previousValue;
    
    if (previousValue != self.on)
        [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)cancelTrackingWithEvent:(UIEvent *)event {
    [super cancelTrackingWithEvent:event];
    
    self.lastTouchLocation = CGPointMake(-1.0, -1.0);
    
    [self showOn:self.on];
}

- (BOOL)isTouchInside {
    return CGRectContainsPoint(CGRectMake(0.0, 0.0, self.bounds.size.width, self.bounds.size.height), self.lastTouchLocation);
}

//MARK: - UIView Method Overrides

- (void)layoutSubviews {
    [super layoutSubviews];
    
    self.backgroundView.frame = CGRectMake(0.0, 0.0, self.frame.size.width, self.frame.size.height);
    self.textLabel.frame      = CGRectMake((self.frame.size.width - self.labelWidth) * 0.5, 0.0, self.labelWidth, self.frame.size.height);
}

@end
