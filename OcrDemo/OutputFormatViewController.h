//
//  OutputFormatViewController.h
//  OcrDemo
//
//  Copyright © 1991-2017 LEAD Technologies, Inc. All rights reserved.
//

typedef NS_ENUM(NSInteger, OutputFormat) {
    OutputFormatPdf,
    OutputFormatPdfEmbed,
    OutputFormatPdfA,
    OutputFormatPdfImageOverText,
    OutputFormatPdfEmbedImageOverText,
    OutputFormatPdfAImageOverText,
    OutputFormatDocx,
    OutputFormatDocxFramed,
    OutputFormatRtf,
    OutputFormatRtfFramed,
    OutputFormatText,
    OutputFormatTextFormatted,
    OutputFormatSvg,
};

NSString *friendlyNameForOutputFormat(OutputFormat format);



@interface OutputFormatViewController : UIViewController

@property (nonatomic, assign) OutputFormat format;

@property (nonatomic, strong) NSArray<NSString *> *languages;
@property (nonatomic, copy)   NSString *selectedLanguage;

@property (nonatomic, assign) CGFloat constraint;

@end
