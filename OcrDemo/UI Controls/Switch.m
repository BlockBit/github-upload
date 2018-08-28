//
//  Switch.m
//  OcrDemo
//
//  Copyright © 1991-2017 LEAD Technologies, Inc. All rights reserved.
//

#import "Switch.h"

#pragma mark - Class Extension

@interface Switch()

@property (nonatomic, strong)                     UIView *backgroundView;
@property (nonatomic, strong)                     UIView *thumbView;

@property (nonatomic, assign)                     BOOL switchValue;
@property (nonatomic, assign)                     BOOL valueAtBeginTracking;
@property (nonatomic, assign)                     BOOL currentVisualValue;
@property (nonatomic, assign)                     BOOL didChangeWhileTracking;
@property (nonatomic, assign, getter=isAnimating) BOOL animating;

@property (nonatomic, assign)                     CGFloat normalThumbWidth;
@property (nonatomic, assign)                     CGFloat activeThumbWidth;

@end

#pragma mark - Class Implementation

@implementation Switch

#pragma mark - Property Synthesis

@synthesize offTintColor = _offTintColor, onTintColor = _onTintColor, borderColor = _borderColor, onThumbTintColor = _onThumbTintColor, offThumbTintColor = _offThumbTintColor, borderWidth = _borderWidth, thumbInset = _thumbInset, backgroundView = _backgroundView, thumbView = _thumbView, switchValue = _switchValue, valueAtBeginTracking = _valueAtBeginTracking, currentVisualValue = _currentVisualValue, didChangeWhileTracking = _didChangeWhileTracking, animating = _animating;
@dynamic on, normalThumbWidth, activeThumbWidth;

- (BOOL)on {
    return _switchValue;
}

- (void)setOn:(BOOL)on {
    _switchValue = on;
    [self setOn:on animated:NO];
}

- (void)setOffTintColor:(UIColor *)offTintColor {
    if (!self.on && !self.tracking)
        _backgroundView.backgroundColor = offTintColor;
    
    _offTintColor = offTintColor;
}

- (void)setOnTintColor:(UIColor *)onTintColor {
    if (self.on && !self.tracking) {
        _backgroundView.backgroundColor   = onTintColor;
        _backgroundView.layer.borderColor = onTintColor.CGColor;
    }
    
    _onTintColor = onTintColor;
}

- (void)setBorderColor:(UIColor *)borderColor {
    if (!self.on)
        _backgroundView.layer.borderColor = borderColor.CGColor;
    
    _borderColor = borderColor;
}

- (void)setBorderWidth:(CGFloat)borderWidth {
    _backgroundView.layer.borderWidth = borderWidth;
    _borderWidth                      = borderWidth;
}

- (void)setThumbInset:(CGFloat)thumbInset {
    if (!self.tracking)
        [self showOn:self.on animated:NO];
}

- (void)setOnThumbTintColor:(UIColor *)onThumbTintColor {
    if (self.on && !self.tracking)
        _thumbView.backgroundColor = onThumbTintColor;
    
    _onThumbTintColor = onThumbTintColor;
}

- (void)setOffThumbTintColor:(UIColor *)offThumbTintColor {
    if (!self.on && !self.tracking)
        _thumbView.backgroundColor = offThumbTintColor;
    
    _offThumbTintColor = offThumbTintColor;
}

- (CGFloat)normalThumbWidth {
    return (self.bounds.size.height - 2.0 * _thumbInset);
}

- (CGFloat)activeThumbWidth {
    return self.normalThumbWidth + 5.0;
}

#pragma mark - Initialization

- (instancetype)init {
    return [self initWithFrame:CGRectMake(0.0, 0.0, 60.0, 30.0)];
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

- (void)setOn:(BOOL)on animated:(BOOL)animated {
    _switchValue = on;
    [self showOn:on animated:animated];
}

- (void)setup {
    _offTintColor      = [UIColor colorWithRed:0.1569 green:0.1647 blue:0.2353 alpha:1.0];
    _onTintColor       = [UIColor colorWithRed:0.4667 green:0.5490 blue:0.9137 alpha:1.0];
    _borderColor       = [UIColor colorWithRed:0.4667 green:0.5490 blue:0.9137 alpha:1.0];
    _borderWidth       = 1.0;
    _thumbInset        = 4.0;
    _onThumbTintColor  = [UIColor colorWithRed:0.1569 green:0.1647 blue:0.2353 alpha:1.0];
    _offThumbTintColor = [UIColor colorWithRed:0.4667 green:0.5490 blue:0.9137 alpha:1.0];
    
    self.backgroundView = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.frame.size.width, self.frame.size.height)];
    self.backgroundView.userInteractionEnabled = NO;
    self.backgroundView.backgroundColor        = self.on ? self.onTintColor : self.offTintColor;
    self.backgroundView.clipsToBounds          = YES;
    self.backgroundView.layer.cornerRadius     = self.frame.size.height * 0.5;
    self.backgroundView.layer.borderColor      = self.borderColor.CGColor;
    self.backgroundView.layer.borderWidth      = self.borderWidth;
    [self addSubview:self.backgroundView];
    
    self.thumbView = [[UIView alloc] initWithFrame:CGRectMake(self.thumbInset, self.thumbInset, self.normalThumbWidth, self.normalThumbWidth)];
    self.thumbView.userInteractionEnabled = NO;
    self.thumbView.backgroundColor        = self.on ? self.onThumbTintColor : self.offThumbTintColor;
    self.thumbView.layer.cornerRadius     = self.thumbView.frame.size.height * 0.5;
    self.thumbView.layer.masksToBounds    = NO;
    [self addSubview:self.thumbView];
    
    self.on = NO;
}

- (void)showOn:(BOOL)on animated:(BOOL)animated {
    const CGFloat normalThumbWidth = self.normalThumbWidth;
    const CGFloat activeThumbWidth = self.activeThumbWidth;
    
    void (^animations)(void) = ^{
        if (self.tracking && on)
            self.thumbView.frame = CGRectMake(self.bounds.size.width - (activeThumbWidth + self.thumbInset), self.thumbView.frame.origin.y, activeThumbWidth, self.thumbView.frame.size.height);
        else if (self.tracking && !on)
            self.thumbView.frame = CGRectMake(self.thumbInset, self.thumbView.frame.origin.y, activeThumbWidth, self.thumbView.frame.size.height);
        else if (!self.tracking && on)
            self.thumbView.frame = CGRectMake(self.bounds.size.width - (normalThumbWidth + self.thumbInset), self.thumbView.frame.origin.y, normalThumbWidth, self.thumbView.frame.size.height);
        else if (!self.tracking && !on)
            self.thumbView.frame = CGRectMake(self.thumbInset, self.thumbView.frame.origin.y, normalThumbWidth, self.thumbView.frame.size.height);
        
        self.backgroundView.layer.borderColor = self.borderColor.CGColor;
        self.backgroundView.backgroundColor   = on ? self.onTintColor : self.offTintColor;
        self.thumbView.backgroundColor        = on ? self.onThumbTintColor : self.offThumbTintColor;
    };
    
    if (animated) {
        self.animating = YES;
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState animations:animations completion:^(BOOL finished) {
            self.animating = NO;
        }];
    }
    else {
        animations();
    }
    
    self.currentVisualValue = on;
}

#pragma mark - UIControl Method Overrides

- (BOOL)beginTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    [super beginTrackingWithTouch:touch withEvent:event];
    
    self.valueAtBeginTracking      = self.on;
    self.didChangeWhileTracking    = NO;
    self.animating                 = YES;
    const CGFloat activeThumbWidth = self.activeThumbWidth;
    
    [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState animations:^{
        if (self.on) {
            self.thumbView.frame                = CGRectMake(self.bounds.size.width - (activeThumbWidth + self.thumbInset), self.thumbView.frame.origin.y, activeThumbWidth, self.thumbView.frame.size.height);
            self.thumbView.backgroundColor      = self.onThumbTintColor;
            self.backgroundView.backgroundColor = self.onTintColor;
        }
        else {
            self.thumbView.frame                = CGRectMake(self.thumbView.frame.origin.x, self.thumbView.frame.origin.y, activeThumbWidth, self.thumbView.frame.size.height);
            self.thumbView.backgroundColor      = self.offThumbTintColor;
            self.backgroundView.backgroundColor = self.offTintColor;
        }
    } completion:^(BOOL finished) {
        self.animating = NO;
    }];
    
    return YES;
}

- (BOOL)continueTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    [super continueTrackingWithTouch:touch withEvent:event];
    
    const CGPoint lastTouchLocation = [touch locationInView:self];
    
    if (lastTouchLocation.x > self.bounds.size.width * 0.5) {
        [self showOn:YES animated:YES];
        
        if (!self.valueAtBeginTracking)
            self.didChangeWhileTracking = YES;
    }
    else {
        [self showOn:NO animated:YES];
        
        if (self.valueAtBeginTracking)
            self.didChangeWhileTracking = YES;
    }
    
    return YES;
}

- (void)endTrackingWithTouch:(UITouch *)touch withEvent:(UIEvent *)event {
    [super endTrackingWithTouch:touch withEvent:event];
    
    const BOOL previousValue = self.on;
    
    if (self.didChangeWhileTracking)
        [self setOn:self.currentVisualValue animated:YES];
    else
        [self setOn:!self.on animated:YES];
    
    if (previousValue != self.on)
        [self sendActionsForControlEvents:UIControlEventValueChanged];
}

- (void)cancelTrackingWithEvent:(UIEvent *)event {
    [super cancelTrackingWithEvent:event];
    [self showOn:self.on animated:YES];
}

#pragma mark - UIView Method Overrides

- (void)layoutSubviews {
    [super layoutSubviews];
    
    if (!self.isAnimating) {
        self.backgroundView.frame              = CGRectMake(0.0, 0.0, self.frame.size.width, self.frame.size.height);
        self.backgroundView.layer.cornerRadius = self.frame.size.height * 0.5;
        
        const CGFloat normalThumbWidth = self.normalThumbWidth;
        if (self.on)
            self.thumbView.frame = CGRectMake(self.frame.size.width - (normalThumbWidth + self.thumbInset), self.thumbInset, self.frame.size.height - 2.0 * self.thumbInset, normalThumbWidth);
        else
            self.thumbView.frame = CGRectMake(self.thumbInset, self.thumbInset, self.normalThumbWidth, self.normalThumbWidth);
            
        self.thumbView.layer.cornerRadius = self.thumbView.frame.size.height * 0.5;
    }
}

@end
