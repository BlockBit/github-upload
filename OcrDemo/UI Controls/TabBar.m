//
//  TabBar.m
//  OcrDemo
//
//  Copyright © 1991-2017 LEAD Technologies, Inc. All rights reserved.
//

#import "TabBar.h"

#pragma mark - UIColor Category (ColorComponents) Interface

@interface UIColor (ColorComponents)

@property (nonatomic, assign, readonly) CGFloat red;
@property (nonatomic, assign, readonly) CGFloat blue;
@property (nonatomic, assign, readonly) CGFloat green;
@property (nonatomic, assign, readonly) CGFloat alpha;

@end

#pragma mark - Class (TabBar) Implementation

@implementation TabBar

#pragma mark - Property Synthesis

@synthesize dividerColor = _dividerColor;

- (void)setDividerColor:(UIColor *)dividerColor {
    _dividerColor = dividerColor;
    [self setNeedsDisplay];
}

#pragma mark - UITabBar Method Overrides

- (void)setSelectedItem:(UITabBarItem *)selectedItem {
    [super setSelectedItem:selectedItem];
    [self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
    [super drawRect:rect];
    
    if (_dividerColor != nil && self.items.count > 1 && _dividerColor.alpha != 0.0) {
        NSArray<UIControl *> * const controls = [self.subviews filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary<NSString *,id> *bindings) {
            return [evaluatedObject isKindOfClass:[UIControl class]];
        }]];
        
        if (controls.count >= self.items.count) {
            NSMutableDictionary<NSString *, NSNumber *> * const classCount = [NSMutableDictionary dictionary];
            
            for (UIControl *control in controls) {
                NSArray<NSString *> * const _controls = [classCount.allKeys filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary<NSString *,id> *bindings) {
                    return [(NSString *)evaluatedObject compare:NSStringFromClass([control class]) options:NSCaseInsensitiveSearch] == NSOrderedSame;
                }]];
                
                if (_controls.count > 0)
                    classCount[_controls[0]] = @(classCount[_controls[0]].integerValue + 1);
                else
                    classCount[NSStringFromClass([control class])] = @1;
            }
            
            if (classCount.count > 0) {
                NSArray<NSNumber *> * const sortedCounts = [classCount.allValues sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                    NSNumber * const number1 = (NSNumber *)obj1;
                    NSNumber * const number2 = (NSNumber *)obj2;
                    
                    if (number1.integerValue > number2.integerValue) return NSOrderedDescending;
                    if (number1.integerValue < number2.integerValue) return NSOrderedAscending;
                    else                                             return NSOrderedSame;
                }];
                NSArray<NSString *> * const sortedClasses = [classCount.allKeys sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                    NSNumber * const number1 = classCount[(NSString *)obj1];
                    NSNumber * const number2 = classCount[(NSString *)obj2];
                    
                    if (number1.integerValue > number2.integerValue) return NSOrderedDescending;
                    if (number1.integerValue < number2.integerValue) return NSOrderedAscending;
                    else                                             return NSOrderedSame;
                }];
                
                if (sortedCounts[0].integerValue == self.items.count) {
                    NSArray<UIControl *> * const buttons = [[self.subviews filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^BOOL(id evaluatedObject, NSDictionary<NSString *,id> *bindings) {
                        return [evaluatedObject isKindOfClass:NSClassFromString(sortedClasses[0])];
                    }]] sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
                        const CGFloat x1 = ((UIControl *)obj1).frame.origin.x;
                        const CGFloat x2 = ((UIControl *)obj2).frame.origin.x;
                        
                        if (x1 > x2) return NSOrderedDescending;
                        if (x1 < x2) return NSOrderedAscending;
                        else         return NSOrderedSame;
                    }];
                    
                    const CGContextRef context = UIGraphicsGetCurrentContext();
                    CGContextSaveGState(context);
                    
                    CGContextSetLineWidth(context, 1.0);
                    CGContextSetStrokeColorWithColor(context, _dividerColor.CGColor);
                    
                    for (NSUInteger i = 0; i < buttons.count - 1; i++) {
                        UIControl * const button = buttons[i];
                        const CGFloat x          = (buttons[i+1].frame.origin.x + (button.frame.origin.x + button.frame.size.width)) * 0.5;
                        
                        CGContextMoveToPoint(context, x, 0.0);
                        CGContextAddLineToPoint(context, x, self.frame.size.height);
                        CGContextStrokePath(context);
                    }
                    
                    CGContextRestoreGState(context);
                }
            }
        }
    }
}

@end

#pragma mark - UIColor Category (ColorComponents) Implementation

@implementation UIColor (ColorComponents)

#pragma mark - Property Synthesis

@dynamic red, blue, green, alpha;

- (CGFloat)red {
    CGFloat red = -1.0;
    [self getRed:&red green:NULL blue:NULL alpha:NULL];
    return red;
}

- (CGFloat)green {
    CGFloat green = -1.0;
    [self getRed:NULL green:&green blue:NULL alpha:NULL];
    return green;
}

- (CGFloat)blue {
    CGFloat blue = -1.0;
    [self getRed:NULL green:NULL blue:&blue alpha:NULL];
    return blue;
}

- (CGFloat)alpha {
    CGFloat alpha = -1.0;
    [self getRed:NULL green:NULL blue:NULL alpha:&alpha];
    return alpha;
}

@end
