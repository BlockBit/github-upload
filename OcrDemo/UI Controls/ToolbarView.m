//
//  ToolbarView.m
//  OcrDemo
//
//  Copyright © 1991-2017 LEAD Technologies, Inc. All rights reserved.
//

#import "ToolbarView.h"
#import <objc/runtime.h>

#pragma mark - Private Constants

#define selectionColor [UIColor colorWithRed:0.7333 green:0.8157 blue:1.0 alpha:1.0]
#define clearColor     [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.0]

#pragma mark - Class (ToolbarView) Extension

@interface ToolbarView()

@property (nonatomic, strong) IBOutlet UIView *deskewSelectionBar;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *leadingConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *widthsConstraint;

@end

#pragma mark - Class (ToolbarView) Implementation

@implementation ToolbarView

#pragma mark - Property Synthesis

@synthesize deskewButton = _deskewButton, invertButton = _invertButton, rotateButton = _rotateButton, handler = _handler, deskewSelectionBar = _deskewSelectionBar;
@dynamic deskewHighlighted;

- (BOOL)deskewHighlighted {
    return _deskewButton.isSelected;
}

- (void)setDeskewHighlighted:(BOOL)deskewHighlighted {
    _deskewButton.selected              = deskewHighlighted;
    _deskewSelectionBar.backgroundColor = deskewHighlighted ? selectionColor : clearColor;
}

#pragma mark - Initialization

- (void)awakeFromNib {
    [super awakeFromNib];
    
    const UIEdgeInsets inset = UIEdgeInsetsMake(-7.0, -5.0, -7.0, -5.0);
    
    for (UIButton *button in @[_deskewButton, _invertButton, _rotateButton])
        button.hitTestEdgeInsets = inset;
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        [NSLayoutConstraint deactivateConstraints:@[_leadingConstraint, _widthsConstraint]];
        
        _leadingConstraint = [NSLayoutConstraint constraintWithItem:_leadingConstraint.firstItem attribute:_leadingConstraint.firstAttribute relatedBy:NSLayoutRelationGreaterThanOrEqual toItem:nil attribute:NSLayoutAttributeNotAnAttribute multiplier:1.0 constant:10.0];
        _widthsConstraint  = [NSLayoutConstraint constraintWithItem:_widthsConstraint.firstItem attribute:_widthsConstraint.firstAttribute relatedBy:NSLayoutRelationEqual toItem:_widthsConstraint.secondItem attribute:_widthsConstraint.secondAttribute multiplier:2.0 constant:0.0];
        
        [NSLayoutConstraint activateConstraints:@[_leadingConstraint, _widthsConstraint]];
    }
}

#pragma mark - Action Methods

- (IBAction)buttonTapped:(id)sender {
    if ([sender isKindOfClass:[UIButton class]]) {
        if (sender == _deskewButton)
            self.deskewHighlighted = !self.deskewHighlighted;
        
        if (_handler != nil)
            _handler((UIButton *)sender);
    }
}

@end

#pragma mark - UIButton Category (HitTestEdgeInsets) Implementation

@implementation UIButton (HitTestEdgeInsets)

#pragma mark - Property Synthesis

- (UIEdgeInsets)hitTestEdgeInsets {
    NSValue * const value = objc_getAssociatedObject(self, @selector(hitTestEdgeInsets));
    if (value != nil)
        return [value UIEdgeInsetsValue];
    
    return UIEdgeInsetsZero;
}

- (void)setHitTestEdgeInsets:(UIEdgeInsets)hitTestEdgeInsets {
    objc_setAssociatedObject(self, @selector(hitTestEdgeInsets), [NSValue valueWithUIEdgeInsets:hitTestEdgeInsets], OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

#pragma mark - Custom Methods

- (BOOL)__pointInside:(CGPoint)point withEvent:(nullable UIEvent *)event {
    if (UIEdgeInsetsEqualToEdgeInsets(self.hitTestEdgeInsets, UIEdgeInsetsZero) || !self.enabled || self.hidden)
        return [self __pointInside:point withEvent:event];
    
    return CGRectContainsPoint(UIEdgeInsetsInsetRect(self.bounds, self.hitTestEdgeInsets), point);
}

#pragma mark - UIButton Method Overrides

+ (void)initialize {
    if (self != [UIButton class])
        return;
    
    static dispatch_once_t onceToken = 0;
    dispatch_once(&onceToken, ^{
        const SEL originalSelector     = @selector(pointInside:withEvent:);
        const SEL replacementSelector  = @selector(__pointInside:withEvent:);
        const Method originalMethod    = class_getInstanceMethod(self, originalSelector);
        const Method replacementMethod = class_getInstanceMethod(self, replacementSelector);
        
        if (class_addMethod(self, originalSelector, method_getImplementation(replacementMethod), method_getTypeEncoding(replacementMethod)))
            class_replaceMethod(self, replacementSelector, method_getImplementation(originalMethod), method_getTypeEncoding(originalMethod));
        else
            method_exchangeImplementations(originalMethod, replacementMethod);
    });
}

@end
