//
//  OptionsViewController.h
//  OcrDemo
//
//  Copyright © 1991-2017 LEAD Technologies, Inc. All rights reserved.
//

typedef NS_ENUM(NSInteger, SelectAreaMode) {
    SelectAreaModeSelectionRect = 0,
    SelectAreaModeRubberBand = 1
};

#import "OutputFormatViewController.h"

@interface OptionsViewController : UIViewController

@property (nonatomic, strong) NSArray<NSString *> *availableLanguages;
@property (nonatomic, copy)   NSString *currentLanguage;

@property (nonatomic, assign) BOOL detectGraphicsAndColors;
@property (nonatomic, assign) BOOL detectInvertedRegions;
@property (nonatomic, assign) BOOL detectTables;
@property (nonatomic, assign) BOOL intelligentSelectArea;
@property (nonatomic, assign) BOOL autoInvertImages;
@property (nonatomic, assign) BOOL autoRotateImages;
@property (nonatomic, assign) SelectAreaMode selectAreaMode;

@property (nonatomic, strong) NSArray<NSNumber* > *allowedConstraintValues;

@property (nonatomic, assign) OutputFormat format;

@end
