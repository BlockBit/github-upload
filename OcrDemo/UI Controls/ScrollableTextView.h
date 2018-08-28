//
//  ScrollableTextView.h
//  OcrDemo
//
//  Copyright © 1991-2017 LEAD Technologies, Inc. All rights reserved.
//

NS_ASSUME_NONNULL_BEGIN

@interface ScrollableTextView : UIView

@property (nonatomic, copy, null_unspecified) NSString *text;
@property (nonatomic, strong, nullable)       UIView *inputView;

- (IBAction)selectAll:(nullable id)sender;

@end

NS_ASSUME_NONNULL_END
