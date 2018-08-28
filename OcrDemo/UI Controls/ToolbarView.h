//
//  ToolbarView.h
//  OcrDemo
//
//  Copyright © 1991-2017 LEAD Technologies, Inc. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface ToolbarView : UIView

@property (nonatomic, strong) IBOutlet UIButton *deskewButton;
@property (nonatomic, strong) IBOutlet UIButton *invertButton;
@property (nonatomic, strong) IBOutlet UIButton *rotateButton;

@property (nonatomic, strong) void (^ __nullable handler)(UIButton *sender);

@property (nonatomic, assign) BOOL deskewHighlighted;

@end



@interface UIButton (HitTestEdgeInsets)

@property (nonatomic, assign) UIEdgeInsets hitTestEdgeInsets;

@end

NS_ASSUME_NONNULL_END
