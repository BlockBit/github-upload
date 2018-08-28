//
//  ScrollableTextView.m
//  OcrDemo
//
//  Copyright © 1991-2017 LEAD Technologies, Inc. All rights reserved.
//

#import "ScrollableTextView.h"

#pragma mark - Class (ScrollableTextView) Extension

@interface ScrollableTextView()

@property (nonatomic, strong) UIScrollView *scrollView;
@property (nonatomic, strong) UITextView *textView;

@end

#pragma mark - Class (TextView) Interface

@interface TextView : UITextView
@end

#pragma mark - Class (ScrollableTextView) Implementation

@implementation ScrollableTextView

#pragma mark - Property Synthesis

@synthesize text = _text, scrollView = _scrollView, textView = _textView;

- (NSString *)text {
    return _textView.text;
}

- (void)setText:(NSString *)text {
    _scrollView.contentSize = [self sizeOfText:text];
    _textView.frame         = CGRectMake(0.0, 0.0, _scrollView.contentSize.width, _scrollView.contentSize.height);
    
    _text                   = text;
    _textView.text          = text;
}

- (UIView *)inputView {
    return _textView.inputView;
}

- (void)setInputView:(UIView *)inputView {
    _textView.inputView = inputView;
}

#pragma mark - Initialization

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0.0, 0.0, frame.size.width, frame.size.height)];
        _textView   = [[TextView alloc] initWithFrame:CGRectZero];
        
        [self setDefaultPropertyValues];
        
        [self addSubview:_scrollView];
        [_scrollView addSubview:_textView];
    }
    
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        _scrollView = [[UIScrollView alloc] initWithCoder:aDecoder];
        _textView   = [[TextView alloc] initWithCoder:aDecoder];
        
        [self setDefaultPropertyValues];
        
        [self addSubview:_scrollView];
        [_scrollView addSubview:_textView];
    }
    
    return self;
}

#pragma mark - UIView Method Overrides

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _scrollView.frame       = CGRectMake(0.0, 0.0, self.frame.size.width, self.frame.size.height);
    _scrollView.contentSize = [self sizeOfText:self.text];
    _textView.frame         = CGRectMake(0.0, 0.0, _scrollView.contentSize.width, _scrollView.contentSize.height);
}

#pragma mark - Action Methods

- (IBAction)selectAll:(id)sender {
    [_textView selectAll:sender];
}

#pragma mark - Private Methods

- (CGSize)sizeOfText:(NSString *)text {
    if (text == nil) return CGSizeZero;
    
    const CGSize size = [text sizeWithAttributes:@{ NSFontAttributeName : _textView.font }];
    return CGSizeMake(size.width + _textView.textContainerInset.left + _textView.textContainerInset.right, size.height + _textView.textContainerInset.top + _textView.textContainerInset.bottom);
}

- (void)setDefaultPropertyValues {
    _scrollView.clipsToBounds = YES;
    
    _textView.textContainerInset = UIEdgeInsetsMake(20.0, 20.0, 20.0, 20.0);
    _textView.scrollEnabled      = NO;
    _textView.text               = self.text;
    
    if (_textView.font == nil)
        _textView.font = [UIFont systemFontOfSize:14.0];
}

@end

#pragma mark - Class (TextView) Implementation

@implementation TextView

#pragma mark - UIResponder Method Overrides

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    if (action == @selector(cut:) || action == @selector(paste:))
        return NO;
    
    return [super canPerformAction:action withSender:sender];
}

@end
