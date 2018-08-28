//
//  ViewController.m
//  OcrDemo
//
//  Copyright © 1991-2017 LEAD Technologies, Inc. All rights reserved.
//

#import "AppDelegate.h"
#import "ViewController.h"
#import "OptionsViewController.h"
#import "QuickTextViewController.h"
#import "OutputFormatViewController.h"
#import "LTImageViewerSelectAreaInteractiveMode.h"
#import "LTImageViewerManualDeskewInteractiveMode.h"

#import "UI Controls/ToolbarView.h"
#import "UI Controls/TabBar.h"

#pragma mark - Private Constants

static NSString * const currentLanguageKey         = @"currentLanguage";
static NSString * const detectGraphicsAndColorsKey = @"detectGraphicsAndColors";
static NSString * const detectInvertedRegionsKey   = @"detectInvertedRegions";
static NSString * const detectTablesKey            = @"detectTables";
static NSString * const intelligentSelectAreaKey   = @"intelligentSelectArea";
static NSString * const autoInvertImagesKey        = @"autoInvertImages";
static NSString * const autoRotateImagesKey        = @"autoRotateImages";
static NSString * const outputFormatKey            = @"outputFormat";
static NSString * const selectAreaModeKey          = @"selectAreaMode";

#pragma mark - Type Definitions

typedef NS_ENUM(NSInteger, ScanType) {
    ScanTypeNone,
    ScanTypeScanDocument,
    ScanTypeExtractText
};

// The following enums/options have been derived from the Advantage OCR Engine Settings found here: https://www.leadtools.com/help/leadtools/v19m/dh/to/fo-topics-ocrenginespecificsettingsadvantage.html

typedef NS_ENUM(NSInteger, RecognitionModuleTradeoff) {
    RecognitionModuleTradeoffAccurate = 0,
    RecognitionModuleTradeoffBalanced = 1,
    RecognitionModuleTradeoffFast     = 2
};

typedef NS_ENUM(NSInteger, BlackWhiteImageConversionMethod) {
    BlackWhiteImageConversionMethodDefault = 0,
    BlackWhiteImageConversionMethodDynamic = 1,
    BlackWhiteImageConversionMethodUser    = 2
};

typedef NS_ENUM(NSInteger, DetectVerticalZones) {
    DetectVerticalZonesAuto = 0,
    DetectVerticalZonesOn   = 1,
    DetectVerticalZonesOff  = 2
};

typedef NS_ENUM(NSInteger, DefaultDocumentOrientation) {
    DefaultDocumentOrientationNone      = 0,
    DefaultDocumentOrientationPortrait  = 1,
    DefaultDocumentOrientationLandscape = 2
};

// Enum that matches OCR Advantage "Recognition.Preprocess.ModifyOriginalImageOptions"
typedef NS_OPTIONS(NSUInteger, ModifyOriginalImageOptions) {
    ModifyOriginalImageOptionsNone   = 0x00,
    ModifyOriginalImageOptionsDeskew = 0x01,
    ModifyOriginalImageOptionsRotate = 0x02,
    ModifyOriginalImageOptionsInvert = 0x04
};

// Enum that matches OCR Advantage "Recognition.Zoning.Options"
typedef NS_OPTIONS(NSUInteger, AutoZoneOptions) {
    AutoZoneOptionsNone                      = 0x0000,
    AutoZoneOptionsDetectText                = 0x0001,
    AutoZoneOptionsDetectGraphics            = 0x0002,
    AutoZoneOptionsDetectTable               = 0x0004,
    AutoZoneOptionsAllowOverlap              = 0x0008,
    AutoZoneOptionsDetectAccurateZones       = 0x0010,
    AutoZoneOptionsRecognizeOneCellTable     = 0x0020,
    AutoZoneOptionsTableCellsAsZones         = 0x0040,
    AutoZoneOptionsUseAdvancedTableDetection = 0x0080,
    AutoZoneOptionsUseTextExtractor          = 0x0100,
    AutoZoneOptionsDetectCheckbox            = 0x0200,
    AutoZoneOptionsFavorGraphics             = 0x0400
};

#pragma mark - Private Functions

static inline LTDocumentFormat documentFormatFromOutputFormat(OutputFormat format) {
    switch (format) {
        case OutputFormatPdf:
        case OutputFormatPdfEmbed:
        case OutputFormatPdfA:
        case OutputFormatPdfImageOverText:
        case OutputFormatPdfEmbedImageOverText:
        case OutputFormatPdfAImageOverText:
            return LTDocumentFormatPdf;
            
        case OutputFormatDocx:
        case OutputFormatDocxFramed:
            return LTDocumentFormatDocx;
            
        case OutputFormatRtf:
        case OutputFormatRtfFramed:
            return LTDocumentFormatRtf;
            
        case OutputFormatText:
        case OutputFormatTextFormatted:
            return LTDocumentFormatText;
            
        case OutputFormatSvg:
            return LTDocumentFormatSvg;
    }
}

static inline NSString *friendlyAbbreviationForFormat(OutputFormat format) {
    switch (format) {
        case OutputFormatPdf:
        case OutputFormatPdfEmbed:
        case OutputFormatPdfA:
        case OutputFormatPdfImageOverText:
        case OutputFormatPdfEmbedImageOverText:
        case OutputFormatPdfAImageOverText:
            return @"PDF";
            
        case OutputFormatDocx:
        case OutputFormatDocxFramed:
            return @"DOCX";
            
        case OutputFormatRtf:
        case OutputFormatRtfFramed:
            return @"RTF";
            
        case OutputFormatText:
        case OutputFormatTextFormatted:
            return @"TXT";
            
        case OutputFormatSvg:
            return @"SVG";
    }
}

static inline CGRect CGRectFromPoints(CGPoint point1, CGPoint point2) {
    const CGFloat left   = MIN(point1.x, point2.x);
    const CGFloat top    = MIN(point1.y, point2.y);
    const CGFloat right  = MAX(point1.x, point2.x);
    const CGFloat bottom = MAX(point1.y, point2.y);
    
    return CGRectMake(left, top, right - left, bottom - top);
}

#pragma mark - Class (TabBarItemStack) Interface

@interface TabBarItemStack : NSObject

@property (nonatomic, strong, readonly) UITabBarItem *currentItem;
@property (nonatomic, strong)           void (^ __nullable popHandler)(UITabBarItem *);

- (instancetype)initWithItem:(UITabBarItem *)item;
- (instancetype)init __unavailable;

- (void)push:(UITabBarItem *)item;
- (UITabBarItem *)pop;

@end

#pragma mark - NSUserDefaults Category (HasValueForKey) Interface

@interface NSUserDefaults (HasValueForKey)

- (BOOL)hasValueForKey:(NSString *)key;

@end

#pragma mark - LTImageViewer Category (SelectAreaMode) Interface

@interface LTImageViewer (SelectAreaMode)

@property (nonatomic, assign, readonly) BOOL isSelectAreaMode;

@end

#pragma mark - Class (ViewController) Extension

@interface ViewController() <UITabBarDelegate, LTImageViewerRubberBandDelegate, UIDocumentInteractionControllerDelegate, UIPopoverPresentationControllerDelegate, AppRateUtilityDelegate> {
    volatile BOOL _abort;
}

@property (nonatomic, strong) IBOutlet LTImageViewer *imageViewer;

@property (nonatomic, strong) IBOutlet UIScrollView *scrollbar;
@property (nonatomic, strong) IBOutlet UITabBar *tabBar;

@property (nonatomic, strong) IBOutlet UILabel *imageSizeLabel;
@property (nonatomic, strong) IBOutlet UILabel *elapsedTimeLabel;

@property (nonatomic, strong) IBOutlet UIButton *deskewApplyButton;
@property (nonatomic, strong) IBOutlet UIButton *deskewExitButton;
@property (nonatomic, strong) IBOutlet UIButton *deskewUndoButton;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *animatableConstraint;

@property (nonatomic, strong) IBOutlet UITabBarItem *recognizeItem;
@property (nonatomic, strong) IBOutlet UITabBarItem *selectAreaItem;

@property (nonatomic, strong) IBOutlet UIView *blockingView;
@property (nonatomic, strong) IBOutlet UILabel *operationLabel;
@property (nonatomic, strong) IBOutlet UIProgressView *progressBar;
@property (nonatomic, strong) IBOutlet UIButton *cancelButton;
@property (nonatomic, strong) IBOutlet UIActivityIndicatorView *activityIndicator;

@property (nonatomic, strong) void (^ __nullable viewDidAppearHandler)();

@property (nonatomic, strong) LTRasterImage *originalImage;
@property (nonatomic, strong) UIView *tintView;

@property (nonatomic, strong) OptionsViewController *optionsController;
@property (nonatomic, strong) UIAlertController *recognizeActionSheet;
@property (nonatomic, strong) UIImagePickerController *imagePickerController;

@property (nonatomic, strong) LTOcrEngine *engine;
@property (nonatomic, assign) LTOcrLanguage currentLanguage;
@property (nonatomic, strong) ToolbarView *toolbar;

@property (nonatomic, strong) dispatch_queue_t processingQueue;

@property (nonatomic, assign) BOOL detectGraphicsAndColors;
@property (nonatomic, assign) BOOL detectInvertedRegions;
@property (nonatomic, assign) BOOL detectTables;
@property (nonatomic, assign) BOOL intelligentSelectArea;
@property (nonatomic, assign) BOOL autoInvertImages;
@property (nonatomic, assign) BOOL autoRotateImages;
@property (nonatomic, assign) SelectAreaMode selectAreaMode;
@property (nonatomic, assign) BOOL manualDeskewIsCancelling;
@property (nonatomic, strong) LTImageViewerInteractiveMode *interactiveMode;

@property (nonatomic, assign) BOOL gestureRecognized;
@property (nonatomic, strong) RasterActivityItem *activityItem;

@property (nonatomic, assign) OutputFormat outputFormat;
@property (nonatomic, assign) CGRect selectedArea;

@property (nonatomic, strong) TabBarItemStack *tabBarItems;

@end

#pragma mark - Class (ViewController) Implementation

@implementation ViewController

#pragma mark - Property Synthesis

@synthesize imageViewer = _imageViewer, scrollbar = _scrollbar, tabBar = _tabBar, imageSizeLabel = _imageSizeLabel, elapsedTimeLabel = _elapsedTimeLabel, deskewApplyButton = _deskewApplyButton, deskewExitButton = _deskewExitButton, deskewUndoButton = _deskewUndoButton, animatableConstraint = _animatableConstraint, recognizeItem = _recognizeItem, selectAreaItem = _selectAreaItem, blockingView = _blockingView, operationLabel = _operationLabel, progressBar = _progressBar, cancelButton = _cancelButton, activityIndicator = _activityIndicator, originalImage = _originalImage, tintView = _tintView, optionsController = _optionsController, recognizeActionSheet = _recognizeActionSheet, imagePickerController = _imagePickerController, engine = _engine, currentLanguage = _currentLanguage, toolbar = _toolbar, processingQueue = _processingQueue, detectGraphicsAndColors = _detectGraphicsAndColors, detectInvertedRegions = _detectInvertedRegions, detectTables = _detectTables, intelligentSelectArea = _intelligentSelectArea, autoInvertImages = _autoInvertImages, autoRotateImages = _autoRotateImages, selectAreaMode = _selectAreaMode, manualDeskewIsCancelling = _manualDeskewIsCancelling, interactiveMode = _interactiveMode, gestureRecognized = _gestureRecognized, activityItem = _activityItem, outputFormat = _outputFormat, selectedArea = _selectedArea, tabBarItems = _tabBarItems;

- (void)setDeskewApplyButton:(UIButton *)deskewApplyButton {
    _deskewApplyButton = deskewApplyButton;
    [_deskewApplyButton setAttributedTitle:[[NSAttributedString alloc] initWithString:_deskewApplyButton.titleLabel.text attributes:@{ NSKernAttributeName : @(2.0) }] forState:UIControlStateNormal | UIControlStateSelected];
}

- (void)setDeskewExitButton:(UIButton *)deskewExitButton {
    _deskewExitButton = deskewExitButton;
    [deskewExitButton setAttributedTitle:[[NSAttributedString alloc] initWithString:_deskewExitButton.titleLabel.text attributes:@{ NSKernAttributeName : @(2.0) }] forState:UIControlStateNormal | UIControlStateSelected];
}

- (void)setDeskewUndoButton:(UIButton *)deskewUndoButton {
    _deskewUndoButton = deskewUndoButton;
    [_deskewUndoButton setAttributedTitle:[[NSAttributedString alloc] initWithString:_deskewUndoButton.titleLabel.text attributes:@{ NSKernAttributeName : @(2.0) }] forState:UIControlStateNormal | UIControlStateSelected];
}

- (void)setCancelButton:(UIButton *)cancelButton {
    _cancelButton = cancelButton;
    [_cancelButton setAttributedTitle:[[NSAttributedString alloc] initWithString:_cancelButton.titleLabel.text attributes:@{ NSKernAttributeName : @(2.0) }] forState:UIControlStateNormal | UIControlStateSelected];
}

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _detectGraphicsAndColors = YES;
    _detectInvertedRegions   = YES;
    _intelligentSelectArea   = YES;
    _autoInvertImages        = YES;
    _autoRotateImages        = YES;
    
    _processingQueue = dispatch_queue_create("com.leadtools.ocrdemo.processingqueue", DISPATCH_QUEUE_SERIAL);
    
    if ([LTRasterSupport isLocked:LTRasterSupportTypeOcrAdvantage]) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"Warning" message:@"OCR functionality isn't unlocked with the license/key that you've provided!" preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            exit(0);
        }]];
        
        [alert show];
        return;
    }
    
    AppRateUtility.sharedInstance.delegate = self;
    [self loadSettings];
    
    LTImageViewerPanZoomInteractiveMode * const panZoom = [[LTImageViewerPanZoomInteractiveMode alloc] init];
    panZoom.enableRotate = NO;
    
    _imageViewer.sizeMode               = LTImageViewerSizeModeFitAlways;
    _imageViewer.touchInteractiveMode   = panZoom;
    _imageViewer.convertToImageOptions |= LTConvertToImageOptionsLinkImage;
    _imageViewer.newImageResetOptions   = LTImageViewerNewImageResetOptionsNone;
    
    [_imageViewer addObserver:self forKeyPath:@"touchInteractiveMode" options:(NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld) context:nil];
    
    UILongPressGestureRecognizer * const longPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
    [_imageViewer addGestureRecognizer:longPressRecognizer];
    
    [NSNotificationCenter.defaultCenter addObserver:self selector:@selector(doubleTap:) name:LTInteractiveServiceDoubleTapNotification object:_imageViewer.interactiveService];
    
    // Use LTRasterCodecs to load the image to preserve DPI information
    LTRasterCodecs * const codecs = [[LTRasterCodecs alloc] init];
    _imageViewer.rasterImage      = [codecs loadFile:[[NSBundle mainBundle] pathForResource:@"OCR1" ofType:@"TIF"] error:nil];
    
    _originalImage           = [_imageViewer.rasterImage clone:nil];
    
    [self updateImageInfo];
    [self updateUIState];
    [self startupEngine];
    
    if (_currentLanguage != LTOcrLanguageNone && ![_engine.languageManager.enabledLanguages containsObject:@(_currentLanguage)] && [_engine.languageManager.supportedLanguages containsObject:@(_currentLanguage)])
        [_engine.languageManager enableLanguages:@[@(_currentLanguage)] error:nil];
    
    NSArray<NSNumber *> * const enabledLanguages = [_engine.languageManager enabledLanguages];
    if (enabledLanguages.count == 0 || (LTOcrLanguage)enabledLanguages[0].integerValue == LTOcrLanguageNone)
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"At least one language is required to perform OCR" userInfo:nil];
    
    if (![enabledLanguages containsObject:@(_currentLanguage)])
        _currentLanguage = (LTOcrLanguage)enabledLanguages[0].integerValue;
    
    _toolbar       = [[UINib nibWithNibName:@"ToolbarView" bundle:nil] instantiateWithOwner:nil options:nil][0];
    _toolbar.frame = CGRectMake(_toolbar.frame.origin.x, _toolbar.frame.origin.y, _scrollbar.bounds.size.width, _toolbar.frame.size.height);
    
    [_scrollbar addSubview:_toolbar];
    _scrollbar.contentSize = _toolbar.bounds.size;
    
    _scrollbar.delaysContentTouches    = NO;
    _scrollbar.canCancelContentTouches = YES;
    
    __unsafe_unretained __typeof(self) _self = self;
    _toolbar.handler = ^(UIButton *sender) {
        [_self toolbarItemSelected:sender];
    };
    
    for (UITabBarItem *item in _tabBar.items) {
        [item setTitleTextAttributes:@{ NSForegroundColorAttributeName : [UIColor colorWithRed:0.5098 green:0.6 blue:1.0 alpha:1.0] } forState:UIControlStateSelected];
        [item setTitleTextAttributes:@{ NSForegroundColorAttributeName : [UIColor colorWithRed:0.3451 green:0.3647 blue:0.6078 alpha:1.0] } forState:UIControlStateNormal];
    }
    
    _tabBarItems = [[TabBarItemStack alloc] initWithItem:_tabBar.items[0]];
    _tabBarItems.popHandler = ^(UITabBarItem *item) {
        if (item.tag == 4)
            [_self selectArea:item];
    };
    _tabBar.selectedItem = _tabBarItems.currentItem;
    
    if ([_tabBar isKindOfClass:[TabBar class]])
        ((TabBar *)_tabBar).dividerColor = [UIColor colorWithRed:0.3882 green:0.4078 blue:0.6471 alpha:1.0];
}

- (void)viewDidAppear:(BOOL)animated {
    if (_viewDidAppearHandler != nil) {
        _viewDidAppearHandler();
        _viewDidAppearHandler = nil;
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    
    [_imageViewer freeRasterImage];
}

#pragma mark - Autorotate Methods

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    self.toolbar.frame = CGRectMake(self.toolbar.frame.origin.x, self.toolbar.frame.origin.y, size.width, self.toolbar.frame.size.height);
    [self.toolbar layoutIfNeeded];
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> context) {
        [self.tabBar setNeedsDisplay];
        [self.toolbar layoutIfNeeded];
        
        if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
            if (self.recognizeActionSheet != nil)
                [self configureControllerForCurrentDevice:self.recognizeActionSheet];
            if (self.imagePickerController != nil)
                [self configureControllerForCurrentDevice:self.imagePickerController];
        }
    } completion:nil];
}

#pragma mark - KVO Methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"touchInteractiveMode"]) {
        if ([change[NSKeyValueChangeOldKey] isKindOfClass:[LTImageViewerInteractiveMode class]])
            _interactiveMode = _imageViewer.touchInteractiveMode;
        
        _toolbar.deskewHighlighted = [_imageViewer.touchInteractiveMode isKindOfClass:[LTImageViewerManualDeskewInteractiveMode class]];
    }
    else
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
}

#pragma mark - UITabBarDelegate Methods

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item {
    if (_imageViewer.isSelectAreaMode && item.tag == 4) {
        [self setPanZoomInteractiveMode];
        [self updateUIState];
        _tabBar.selectedItem = [_tabBarItems pop];
        return;
    }
    
    [_tabBarItems push:item];
    
    switch (item.tag) {
        case 1: // Load Image
            [self loadImage:item];
            break;
            
        case 2: // Take Picture
            [self takePicture:item];
            break;
            
        case 3: // Recognize
            [self recognizeText:item];
            break;
            
        case 4: // Select Area
            [self selectArea:item];
            break;
            
        case 5: // Options
            [self displayOptions:item];
            break;
    }
}

#pragma mark - UIDocumentInteractionControllerDelegate Methods

- (UIViewController *)documentInteractionControllerViewControllerForPreview:(UIDocumentInteractionController *)controller {
    return self;
}

- (void)documentInteractionControllerDidEndPreview:(UIDocumentInteractionController *)controller {
    [AppRateUtility.sharedInstance significantEventOccurred];
}

#pragma mark - AppRateUtilityDelegate Methods

- (UIViewController *)appRateUtilityViewControllerForDialog {
    return self;
}

#pragma mark - UIPopoverPresentationControllerDelegate Methods

- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController {
    if (_imagePickerController != nil) {
        _imagePickerController = nil;
        _tabBar.selectedItem   = [_tabBarItems pop];
    }
    
    return YES;
}

#pragma mark - LTImageViewerRubberBandDelegate Methods

- (void)imageViewerRubberBandInteractiveMode:(LTImageViewerRubberBandInteractiveMode *)imageViewerRubberBandInteractiveMode endWithArgs:(LTImageViewerRubberBandEventArg *)args {
    const CGRect bounds = CGRectFromPoints(args.point1, args.point2);
    
    if (bounds.size.width < [_engine.settingManager integerValueForSetting:@"Recognition.CharacterFilter.MinimumPixelWidth"] || bounds.size.height < [_engine.settingManager integerValueForSetting:@"Recognition.CharacterFilter.MinimumPixelHeight"])
        return;
    
    LTImageViewerSelectAreaInteractiveMode * const selectAreaInteractiveMode = [[LTImageViewerSelectAreaInteractiveMode alloc] init];
    const CGRect imageBounds               = [_imageViewer convertRect:CGRectMake(0.0, 0.0, _imageViewer.imageSize.width, _imageViewer.imageSize.height) sourceType:LTCoordinateTypeImage destType:LTCoordinateTypeControl];
    selectAreaInteractiveMode.selectedArea = CGRectIntersection(bounds, imageBounds);
    
    dispatch_on_main_queue(NO, ^{
        _imageViewer.touchInteractiveMode = selectAreaInteractiveMode;
        [self updateUIState];
    });
    
    _tabBar.selectedItem = _recognizeItem;
    [self tabBar:_tabBar didSelectItem:_recognizeItem];
}

#pragma mark - UIMenuController Methods

- (void)longPress:(UIGestureRecognizer *)gestureRecognizer {
    if (_gestureRecognized || _activityItem == nil || [_imageViewer.touchInteractiveMode isKindOfClass:[LTImageViewerManualDeskewInteractiveMode class]])
        return;
    
    _gestureRecognized = YES;
    
    const CGPoint point = [gestureRecognizer locationInView:_imageViewer];
    
    UIMenuController * const menuController = [UIMenuController sharedMenuController];
    menuController.menuItems = @[[[UIMenuItem alloc] initWithTitle:@"Copy" action:@selector(copyMenuItemPressed:)]];
    
    [menuController setTargetRect:CGRectMake(point.x, point.y, 0.0, 0.0) inView:_imageViewer];
    [menuController setMenuVisible:YES animated:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuWillHide:) name:UIMenuControllerWillHideMenuNotification object:menuController];
}

- (void)copyMenuItemPressed:(UIMenuController *)sender {
    [_activityItem wait]; // Guarantees that the save operation has completed
    
    if (_activityItem.error == nil)
        [[UIPasteboard generalPasteboard] setData:_activityItem.imageData forPasteboardType:_activityItem.dataTypeIdentifier];
}

- (void)menuWillHide:(NSNotification *)notification {
    _gestureRecognized = NO;
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIMenuControllerWillHideMenuNotification object:[notification.object isKindOfClass:[UIMenuController class]] ? notification.object : nil];
}

#pragma mark - UIResponder Method Overrides

- (BOOL)canBecomeFirstResponder {
    return YES;
}

- (BOOL)canPerformAction:(SEL)action withSender:(id)sender {
    return (action == @selector(copyMenuItemPressed:));
}

#pragma mark - Action Methods

- (IBAction)toolbarItemSelected:(UIButton *)sender {
    switch (sender.tag) {
        case 1:  // Deskew
            if ([_imageViewer.touchInteractiveMode isKindOfClass:[LTImageViewerManualDeskewInteractiveMode class]])
                [self setPanZoomInteractiveMode];
            else if (_imageViewer.rasterImage != nil) {
                if (_originalImage == nil)
                    _originalImage = [_imageViewer.rasterImage clone:nil];
                
                if (_imageViewer.isSelectAreaMode)
                    [self tabBar:_tabBar didSelectItem:_selectAreaItem];
                
                _imageViewer.touchInteractiveMode = [[LTImageViewerManualDeskewInteractiveMode alloc] init];
            }
            break;
            
        case 2:  // Invert
            if (_imageViewer.rasterImage != nil) {
                [_imageViewer beginUpdate];
                
                const CGRect selectedArea = [_imageViewer.touchInteractiveMode isKindOfClass:[LTImageViewerSelectAreaInteractiveMode class]] ? ((LTImageViewerSelectAreaInteractiveMode *)_imageViewer.touchInteractiveMode).selectedArea : CGRectZero;
                
                LTInvertCommand * const invert = [[LTInvertCommand alloc] init];
                [invert run:_imageViewer.rasterImage error:nil];
                
                if ([_imageViewer.touchInteractiveMode isKindOfClass:[LTImageViewerSelectAreaInteractiveMode class]])
                    ((LTImageViewerSelectAreaInteractiveMode *)_imageViewer.touchInteractiveMode).selectedArea = selectedArea;
                
                [_imageViewer endUpdate];
                [self updateImageInfo];
            }
            break;
            
        case 3:  // Rotate-Right
            if (_imageViewer.rasterImage != nil) {
                if (_imageViewer.isSelectAreaMode)
                    [self tabBar:_tabBar didSelectItem:_selectAreaItem];
                else if ([_imageViewer.touchInteractiveMode isKindOfClass:[LTImageViewerManualDeskewInteractiveMode class]])
                    [self setPanZoomInteractiveMode];
                
                LTRotateCommand * const rotate = [[LTRotateCommand alloc] initWithAngle:9000 flags:LTRotateCommandFlagsResize fillColor:[LTRasterColor black]];
                [rotate run:_imageViewer.rasterImage error:nil];
                [self updateImageInfo];
            }
            break;
    }
    
    [self updateUIState];
}

- (IBAction)loadImage:(id)sender {
    if (![DemoUtilities requestPhotosAccess:YES]) {
        _tabBar.selectedItem = [_tabBarItems pop];
        return;
    }
    
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    
    [self configureControllerForCurrentDevice:imagePicker];
    
    ImageLoaderOptions * const options = [[ImageLoaderOptions alloc] init];
    options.pickerDismissalHander = ^{
        if (self.imageViewer.rasterImage != nil)
            self.activityItem = [[PNGActivityItem alloc] initWithImage:self.imageViewer.rasterImage codecs:nil];
    };
    options.cancellationHandler   = ^{
        [imagePicker dismissViewControllerAnimated:YES completion:nil];
        
        self.imagePickerController = nil;
        self.tabBar.selectedItem   = [self.tabBarItems pop];
    };
    
    [ImageLoader addImagePicker:imagePicker rasterCodecs:nil options:options completion:^(LTRasterImage *rasterImage, UIImage *image, NSError *error) {
        [self setPanZoomInteractiveMode];
        
        if (rasterImage != nil)
            self.imageViewer.rasterImage = rasterImage;
        else if (image != nil)
            self.imageViewer.image = image;
        
        [self.imageViewer zoomWithSizeMode:LTImageViewerSizeModeFitAlways scaleFactor:1.0 origin:self.imageViewer.defaultZoomOrigin];
        
        if (self.imageViewer.rasterImage != nil)
            self.originalImage = [self.imageViewer.rasterImage clone:nil];
        
        [self updateImageInfo];
        [self updateUIState];
        
        self.elapsedTimeLabel.text = @"00:00 (s)";
    }];
    
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (IBAction)takePicture:(id)sender {
    if (![DemoUtilities requestCameraAccess:YES]) {
        _tabBar.selectedItem = [_tabBarItems pop];
        return;
    }
    
    UIImagePickerController *imagePicker = [[UIImagePickerController alloc] init];
    
    imagePicker.sourceType             = UIImagePickerControllerSourceTypeCamera;
    imagePicker.modalPresentationStyle = UIModalPresentationFullScreen;
    
    ImageLoaderOptions * const options = [[ImageLoaderOptions alloc] init];
    options.pickerDismissalHander = ^{
        if (self.imageViewer.rasterImage != nil)
            self.activityItem = [[PNGActivityItem alloc] initWithImage:self.imageViewer.rasterImage codecs:nil];
    };
    options.cancellationHandler   = ^{
        [imagePicker dismissViewControllerAnimated:YES completion:nil];
        
        self.imagePickerController = nil;
        self.tabBar.selectedItem   = [self.tabBarItems pop];
    };
    
    [ImageLoader addImagePicker:imagePicker rasterCodecs:nil options:options completion:^(LTRasterImage *rasterImage, UIImage *image, NSError *error) {
        [self setPanZoomInteractiveMode];
        
        if (rasterImage != nil)
            self.imageViewer.rasterImage = rasterImage;
        else if (image != nil)
            self.imageViewer.image = image;
        
        [self.imageViewer zoomWithSizeMode:LTImageViewerSizeModeFitAlways scaleFactor:1.0 origin:self.imageViewer.defaultZoomOrigin];
        
        if (self.imageViewer.rasterImage != nil)
            self.originalImage = [self.imageViewer.rasterImage clone:nil];
        
        [self updateImageInfo];
        [self updateUIState];
        
        self.elapsedTimeLabel.text = @"00:00 (s)";
    }];
    
    [self presentViewController:imagePicker animated:YES completion:nil];
}

- (IBAction)recognizeText:(id)sender {
    LeadRect bounds = LeadRectZero;
    
    if (_imageViewer.touchInteractiveMode != nil) {
        if ([_imageViewer.touchInteractiveMode isKindOfClass:[LTImageViewerManualDeskewInteractiveMode class]]) {
            [self setPanZoomInteractiveMode];
            [self updateUIState];
        }
        else if ([_imageViewer.touchInteractiveMode isKindOfClass:[LTImageViewerSelectAreaInteractiveMode class]]) {
            bounds = LeadRectFromCGRect([_imageViewer convertRect:((LTImageViewerSelectAreaInteractiveMode *)_imageViewer.touchInteractiveMode).selectedArea sourceType:LTCoordinateTypeControl destType:LTCoordinateTypeImage]);
        }
        else if ([_imageViewer.touchInteractiveMode isKindOfClass:[LTImageViewerRubberBandInteractiveMode class]]) {
            bounds        = LeadRectFromCGRect([_imageViewer convertRect:_selectedArea sourceType:LTCoordinateTypeControl destType:LTCoordinateTypeImage]);
            _selectedArea = CGRectZero;
        }
    }
    
    if (_imageViewer.rasterImage == nil) {
        [self displayAlertWithTitle:@"Warning" message:@"Please load an image first"];
        return;
    }
    
    void (^block)(ScanType) = ^(ScanType scanType) {
        if (self.imageViewer.isSelectAreaMode) {
            if (bounds.width < [_engine.settingManager integerValueForSetting:@"Recognition.CharacterFilter.MinimumPixelWidth"] || bounds.height < [_engine.settingManager integerValueForSetting:@"Recognition.CharacterFilter.MinimumPixelHeight"]) {
                dispatch_on_main_queue(NO, ^{
                    [self displayAlertWithTitle:@"No text found" message:@"The selected area in the image is too small for processing"];
                    
                    self.tabBar.selectedItem  = [self.tabBarItems pop];
                    self.recognizeActionSheet = nil;
                });
                
                return;
            }
        }
        
        dispatch_on_main_queue(NO, ^{
            [self presentActivityView:YES];
            [UIApplication sharedApplication].idleTimerDisabled = YES;
        });
        
        dispatch_async(_processingQueue, ^{
            if (scanType == ScanTypeScanDocument)
                [self recognizeImage:_imageViewer.rasterImage zone:bounds intelligent:_intelligentSelectArea];
            else
                [self recognizeQuickTextInBounds:bounds intelligent:_intelligentSelectArea];
            
            dispatch_on_main_queue(NO, ^{
                [self presentActivityView:NO];
            });
        });
        
        self.recognizeActionSheet = nil;
    };
    
    _recognizeActionSheet = [UIAlertController alertControllerWithTitle:@"How would you like to process this image?" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [_recognizeActionSheet addAction:[UIAlertAction actionWithTitle:[NSString stringWithFormat:@"OCR Document to %@", friendlyAbbreviationForFormat(_outputFormat)] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        block(ScanTypeScanDocument);
    }]];
    [_recognizeActionSheet addAction:[UIAlertAction actionWithTitle:@"Extract Text from Image" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        block(ScanTypeExtractText);
    }]];
    [_recognizeActionSheet addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        self.tabBar.selectedItem  = [self.tabBarItems pop];
        self.recognizeActionSheet = nil;
    }]];
    
    [self configureControllerForCurrentDevice:_recognizeActionSheet];
    [self presentViewController:_recognizeActionSheet animated:YES completion:nil];
}

- (IBAction)selectArea:(id)sender {
    if (_imageViewer.rasterImage != nil && !_imageViewer.isSelectAreaMode) {
        LTImageViewerSelectAreaInteractiveMode * const selectAreaInteractiveMode = [[LTImageViewerSelectAreaInteractiveMode alloc] init];
        LTImageViewerRubberBandInteractiveMode * const rubberBandInteractiveMode = [[LTImageViewerRubberBandInteractiveMode alloc] init];
        
        if (_selectAreaMode == SelectAreaModeSelectionRect) {
            dispatch_on_main_queue(NO, ^{
                self.imageViewer.touchInteractiveMode = selectAreaInteractiveMode;
                [self updateUIState];
            });
        }
        else {
            rubberBandInteractiveMode.borderDashPattern = @[@4.0, @4.0];
            rubberBandInteractiveMode.borderThickness   = selectAreaInteractiveMode.lineWidth;
            rubberBandInteractiveMode.borderColor       = selectAreaInteractiveMode.lineColor;
            rubberBandInteractiveMode.delegate          = self;
            
            dispatch_on_main_queue(NO, ^{
                self.imageViewer.touchInteractiveMode = rubberBandInteractiveMode;
                [self updateUIState];
            });
        }
    }
}

- (IBAction)displayOptions:(id)sender {
    UIViewController * const controller = [self.storyboard instantiateViewControllerWithIdentifier:@"OptionsViewController"];
    
    if ([controller isKindOfClass:[UINavigationController class]]) {
        UINavigationController * const navigationController = (UINavigationController *)controller;
        
        if ([navigationController.topViewController isKindOfClass:[OptionsViewController class]]) {
            OptionsViewController * const options = (OptionsViewController *)navigationController.topViewController;
            
            options.detectGraphicsAndColors = _detectGraphicsAndColors;
            options.detectInvertedRegions   = _detectInvertedRegions;
            options.detectTables            = _detectTables;
            options.intelligentSelectArea   = _intelligentSelectArea;
            options.autoInvertImages        = _autoInvertImages;
            options.autoRotateImages        = _autoRotateImages;
            options.selectAreaMode          = _selectAreaMode;
            options.format                  = _outputFormat;
            
            NSArray<NSNumber *> * const supportedLanguages = [_engine.languageManager supportedLanguages];
            NSMutableArray<NSString *> * const supportedLangugageNames = [NSMutableArray arrayWithCapacity:supportedLanguages.count];
            
            for (NSNumber *supportedLanguage in supportedLanguages)
                [supportedLangugageNames addObject:[LTOcrLanguageManager nameForLanguage:(LTOcrLanguage)supportedLanguage.integerValue]];
            
            options.availableLanguages = supportedLangugageNames;
            options.currentLanguage    = [LTOcrLanguageManager nameForLanguage:_currentLanguage];
            
            _optionsController         = options;
            
            // For iPad devices, we present the view like normal, however, for iPhone/iPod Touch devices we manually animate the view so that we can use it like an UIAlertController
            if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
                navigationController.modalPresentationStyle = UIModalPresentationFormSheet;
                options.modalPresentationStyle              = UIModalPresentationFormSheet;
                
                [self presentViewController:navigationController animated:YES completion:nil];
            }
            else {
                options.allowedConstraintValues = @[@(self.view.bounds.size.height * 0.2), @(self.view.bounds.size.height * 0.25)];
                options.modalPresentationStyle  = UIModalPresentationOverCurrentContext;
                
                _tintView                 = [[UIView alloc] initWithFrame:CGRectMake(0.0, 0.0, self.view.bounds.size.width, self.view.bounds.size.height)];
                _tintView.backgroundColor = [UIColor clearColor];
                [self.view addSubview:_tintView];
                
                [UIView animateWithDuration:0.4 animations:^{
                    self.tintView.backgroundColor = [UIColor colorWithWhite:0.0 alpha:0.5569];
                }];
                
                self.modalPresentationStyle = UIModalPresentationOverCurrentContext;
                [self presentViewController:navigationController animated:YES completion:nil];
            }
        }
    }
}

- (IBAction)dismissSettings:(UIStoryboardSegue *)sender {
    OptionsViewController *options = [sender.sourceViewController isKindOfClass:[OptionsViewController class]] ? (OptionsViewController *)sender.sourceViewController : nil;
    if (options == nil)
        options = _optionsController;
    
    BOOL shouldDismissSelectAreaMode = NO;
    
    if (options != nil) {
        shouldDismissSelectAreaMode = options.selectAreaMode != _selectAreaMode && _imageViewer.isSelectAreaMode;
        
        _detectGraphicsAndColors = options.detectGraphicsAndColors;
        _detectInvertedRegions   = options.detectInvertedRegions;
        _detectTables            = options.detectTables;
        _intelligentSelectArea   = options.intelligentSelectArea;
        _autoInvertImages        = options.autoInvertImages;
        _autoRotateImages        = options.autoRotateImages;
        _selectAreaMode          = options.selectAreaMode;
        _outputFormat            = options.format;
        _currentLanguage         = [LTOcrLanguageManager languageForName:options.currentLanguage];
        
        [self saveSettings];
        
        [_engine.languageManager enableLanguages:@[@(_currentLanguage)] error:nil];
        
        switch (documentFormatFromOutputFormat(_outputFormat)) {
            case LTDocumentFormatDocx:
                _recognizeItem.image         = [UIImage imageNamed:@"DOCX"];
                _recognizeItem.selectedImage = [UIImage imageNamed:@"DOCX-Selected"];
                break;
                
            case LTDocumentFormatPdf:
                _recognizeItem.image         = [UIImage imageNamed:@"PDF"];
                _recognizeItem.selectedImage = [UIImage imageNamed:@"PDF-Selected"];
                break;
                
            case LTDocumentFormatRtf:
                _recognizeItem.image         = [UIImage imageNamed:@"RTF"];
                _recognizeItem.selectedImage = [UIImage imageNamed:@"RTF-Selected"];
                break;
                
            case LTDocumentFormatSvg:
                _recognizeItem.image         = [UIImage imageNamed:@"SVG"];
                _recognizeItem.selectedImage = [UIImage imageNamed:@"SVG-Selected"];
                break;
                
            case LTDocumentFormatText:
                _recognizeItem.image         = [UIImage imageNamed:@"TXT"];
                _recognizeItem.selectedImage = [UIImage imageNamed:@"TXT-Selected"];
                break;
                
            default:
                break;
        }
    }
    
    _optionsController   = nil;
    _tabBar.selectedItem = [_tabBarItems pop];
    
    if (shouldDismissSelectAreaMode)
        [self tabBar:_tabBar didSelectItem:_selectAreaItem];
    
    if (self.tintView != nil) {
        [UIView animateWithDuration:0.25 animations:^{
            self.tintView.backgroundColor = [UIColor clearColor];
        } completion:^(BOOL finished) {
            [self.tintView removeFromSuperview];
            self.tintView = nil;
        }];
    }
}

- (IBAction)dismissExtractedTextController:(UIStoryboardSegue *)sender {
    _viewDidAppearHandler = ^{
        [AppRateUtility.sharedInstance significantEventOccurred];
    };
}

- (IBAction)cancelRecognition:(id)sender {
    if (_operationLabel.text != nil && _operationLabel.text.length > 0 && !_abort)
        _operationLabel.attributedText = [[NSAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ (Aborting...)", _operationLabel.text] attributes:@{ NSKernAttributeName : @(1.0) }];
    
    _abort = YES;
}

- (IBAction)applyDeskew:(id)sender {
    if ([_imageViewer.touchInteractiveMode isKindOfClass:[LTImageViewerManualDeskewInteractiveMode class]])
        [(LTImageViewerManualDeskewInteractiveMode *)_imageViewer.touchInteractiveMode applyDeskew:nil];
    
    [self updateUIState];
}

- (IBAction)undoDeskew:(id)sender {
    _imageViewer.rasterImage = _originalImage;
    [(LTImageViewerManualDeskewInteractiveMode *)_imageViewer.touchInteractiveMode resetThumbs];
    
    [self updateUIState];
}

- (IBAction)cancelDeskew:(id)sender {
    [self setPanZoomInteractiveMode];
    [self updateUIState];
}

#pragma mark - Custom Methods

- (void)loadSettings {
    NSUserDefaults * const defaults = NSUserDefaults.standardUserDefaults;
    
    if ([defaults hasValueForKey:detectGraphicsAndColorsKey]) _detectGraphicsAndColors = [defaults boolForKey:detectGraphicsAndColorsKey];
    if ([defaults hasValueForKey:detectInvertedRegionsKey])   _detectInvertedRegions   = [defaults boolForKey:detectInvertedRegionsKey];
    if ([defaults hasValueForKey:detectTablesKey])            _detectTables            = [defaults boolForKey:detectTablesKey];
    if ([defaults hasValueForKey:intelligentSelectAreaKey])   _intelligentSelectArea   = [defaults boolForKey:intelligentSelectAreaKey];
    if ([defaults hasValueForKey:autoInvertImagesKey])        _autoInvertImages        = [defaults boolForKey:autoInvertImagesKey];
    if ([defaults hasValueForKey:autoRotateImagesKey])        _autoRotateImages        = [defaults boolForKey:autoRotateImagesKey];
    if ([defaults hasValueForKey:currentLanguageKey])         _currentLanguage         = (LTOcrLanguage)[defaults integerForKey:currentLanguageKey];
    if ([defaults hasValueForKey:outputFormatKey])            _outputFormat            = (OutputFormat)[defaults integerForKey:outputFormatKey];
    if ([defaults hasValueForKey:selectAreaModeKey])          _selectAreaMode          = (SelectAreaMode)[defaults integerForKey:selectAreaModeKey];
    
    switch (documentFormatFromOutputFormat(_outputFormat)) {
        case LTDocumentFormatDocx:
            _recognizeItem.image         = [UIImage imageNamed:@"DOCX"];
            _recognizeItem.selectedImage = [UIImage imageNamed:@"DOCX-Selected"];
            break;
            
        case LTDocumentFormatPdf:
            _recognizeItem.image         = [UIImage imageNamed:@"PDF"];
            _recognizeItem.selectedImage = [UIImage imageNamed:@"PDF-Selected"];
            break;
            
        case LTDocumentFormatRtf:
            _recognizeItem.image         = [UIImage imageNamed:@"RTF"];
            _recognizeItem.selectedImage = [UIImage imageNamed:@"RTF-Selected"];
            break;
            
        case LTDocumentFormatSvg:
            _recognizeItem.image         = [UIImage imageNamed:@"SVG"];
            _recognizeItem.selectedImage = [UIImage imageNamed:@"SVG-Selected"];
            break;
            
        case LTDocumentFormatText:
            _recognizeItem.image         = [UIImage imageNamed:@"TXT"];
            _recognizeItem.selectedImage = [UIImage imageNamed:@"TXT-Selected"];
            break;
            
        default:
            break;
    }
}

- (void)saveSettings {
    NSUserDefaults * const defaults = NSUserDefaults.standardUserDefaults;
    
    [defaults setBool:_detectGraphicsAndColors       forKey:detectGraphicsAndColorsKey];
    [defaults setBool:_detectInvertedRegions         forKey:detectInvertedRegionsKey];
    [defaults setBool:_detectTables                  forKey:detectTablesKey];
    [defaults setBool:_intelligentSelectArea         forKey:intelligentSelectAreaKey];
    [defaults setBool:_autoInvertImages              forKey:autoInvertImagesKey];
    [defaults setBool:_autoRotateImages              forKey:autoRotateImagesKey];
    [defaults setInteger:(NSInteger)_currentLanguage forKey:currentLanguageKey];
    [defaults setInteger:(NSInteger)_outputFormat    forKey:outputFormatKey];
    [defaults setInteger:(NSInteger)_selectAreaMode  forKey:selectAreaModeKey];
}

- (void)configureControllerForCurrentDevice:(UIViewController *)controller {
    const NSUInteger index = [_tabBar.items indexOfObject:_tabBar.selectedItem];
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad && index != NSNotFound) {
        const CGRect tabBarItemFrame = [_tabBar.subviews sortedArrayUsingComparator:^NSComparisonResult(id obj1, id obj2) {
            if ([obj1 isKindOfClass:[UIControl class]] && ![obj2 isKindOfClass:[UIControl class]])
                return NSOrderedAscending;
            else if (![obj1 isKindOfClass:[UIControl class]] && [obj2 isKindOfClass:[UIControl class]])
                return NSOrderedDescending;
            else if ([obj1 isKindOfClass:[UIControl class]] && [obj2 isKindOfClass:[UIControl class]]) {
                if (((UIControl *)obj1).frame.origin.x < ((UIControl *)obj2).frame.origin.x)
                    return NSOrderedAscending;
                else if (((UIControl *)obj1).frame.origin.x > ((UIControl *)obj2).frame.origin.x)
                    return NSOrderedDescending;
            }
            
            return NSOrderedSame;
        }][index].frame;
        
        controller.modalPresentationStyle = UIModalPresentationPopover;
        controller.popoverPresentationController.sourceView = _tabBar;
        controller.popoverPresentationController.sourceRect = tabBarItemFrame;
        controller.popoverPresentationController.delegate   = self;
        
        if ([controller isKindOfClass:[UIImagePickerController class]])
            _imagePickerController = (UIImagePickerController *)controller;
    }
    else
        controller.modalPresentationStyle = UIModalPresentationFullScreen;
}

- (void)updateImageInfo {
    if (_imageViewer.image != nil)
        _imageSizeLabel.text = [NSString stringWithFormat:@"%ld x %ld", (long)_imageViewer.image.size.width, (long)_imageViewer.image.size.height];
    else {
        _imageSizeLabel.text   = @"No image loaded";
        _elapsedTimeLabel.text = @"00:00 (s)";
    }
}

- (void)updateUIState {
    _recognizeItem.enabled = (_imageViewer.image != nil) && ![_imageViewer.touchInteractiveMode isKindOfClass:[LTImageViewerRubberBandInteractiveMode class]];
    
    const BOOL deskewMode = (_imageViewer.touchInteractiveMode != nil && [_imageViewer.touchInteractiveMode isKindOfClass:[LTImageViewerManualDeskewInteractiveMode class]]);
    
    [self.view layoutIfNeeded];
    if (deskewMode && _animatableConstraint.constant != 89.0) {
        _animatableConstraint.constant = 89.0;
        
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState animations:^{
            self.deskewApplyButton.alpha = 1.0;
            self.deskewUndoButton.alpha  = 1.0;
            self.deskewExitButton.alpha  = 1.0;
            [self.view layoutIfNeeded];
        } completion:nil];
    }
    else if (!deskewMode && _animatableConstraint.constant != 16.0) {
        _animatableConstraint.constant = 16.0;
        
        [UIView animateWithDuration:0.3 delay:0.0 options:UIViewAnimationOptionCurveEaseOut | UIViewAnimationOptionBeginFromCurrentState animations:^{
            self.deskewApplyButton.alpha = 0.0;
            self.deskewUndoButton.alpha  = 0.0;
            self.deskewExitButton.alpha  = 0.0;
            [self.view layoutIfNeeded];
        } completion:nil];
    }
    
    _deskewApplyButton.enabled = deskewMode;
    _deskewUndoButton.enabled  = deskewMode;
    _deskewExitButton.enabled  = deskewMode;
}

- (void)startupEngine {
    _engine = [LTOcrEngineManager createEngine:LTOcrEngineTypeAdvantage];
    
    NSError *error = nil;
    
    if (![_engine startup:nil workDirectory:nil startupParameters:[[NSBundle mainBundle] bundlePath] error:&error]) {
        [self displayErrorMessage:[NSString stringWithFormat:@"Unable to start up the OCR Engine: %@", error.localizedDescription] terminate:YES];
        return;
    }
    
    AppDelegate * const delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
    delegate.engine = _engine;
}

- (void)recognizeImage:(LTRasterImage *)image zone:(LeadRect)zone intelligent:(BOOL)intelligent {
    if (image == nil)
        return;
    
    NSError *error = nil;
    _abort = NO;
    
    @autoreleasepool {
        NSDate * const startDate = [NSDate date];
        
        NSMutableDictionary<NSString *, NSString *> * const modifiedOptions = [[self setRecognizeOptions:_outputFormat hasSelectionArea:!LeadRectIsZero(zone) ocrImage:image] mutableCopy];
        
        @try {
            LTRasterImage *ocrImage = [image clone:&error];
            
            if (error != nil) {
                [self displayErrorMessage:error.localizedDescription terminate:NO];
                return;
            }
            
            LTOcrDocument *document;
            LTOcrPage *page = [_engine createPage:ocrImage sharingMode:LTOcrImageSharingModeAutoDispose error:&error];
            if (page == nil) {
                [self displayErrorMessage:error.localizedDescription terminate:NO];
                return;
            }
            
            LTOcrPageAreaOptions * const areaOptions = [LTOcrPageAreaOptions optionsWithArea:zone intersectPercentage:50 useTextZone:!intelligent];
            page.areaOptions = areaOptions;
            
            if (!_abort) {
                LTOcrProgressHandler progressHandler = ^(LTOcrProgressData *progressData) {
                    dispatch_on_main_queue(NO, ^{
                        if (_abort)
                            progressData.status = LTOcrProgressStatusAbort;
                        else {
                            _operationLabel.attributedText = [[NSAttributedString alloc] initWithString:[self friendlyNameForOperation:progressData.operation] attributes:@{ NSKernAttributeName : @(1.0) }];
                            _progressBar.progress          = progressData.percentage / 100.0;
                        }
                    });
                };
                
                dispatch_on_main_queue(NO, ^{
                    _operationLabel.attributedText = [[NSAttributedString alloc] initWithString:@"Process Image" attributes:@{ NSKernAttributeName : @(1.0) }];
                });
                
                if (_autoInvertImages)
                    [page autoPreprocess:LTOcrAutoPreprocessPageCommandInvert progress:progressHandler error:nil];
                
                if (_autoRotateImages)
                    [page autoPreprocess:LTOcrAutoPreprocessPageCommandRotate progress:progressHandler error:nil];
                
                [page autoPreprocess:LTOcrAutoPreprocessPageCommandDeskew progress:progressHandler error:nil];
                
                if (!_abort) {
                    if (![page recognize:progressHandler error:&error]) {
                        if (error.code != LTErrorCodeUserAbort)
                            [self displayErrorMessage:error.localizedDescription terminate:NO];
                        return;
                    }
                    
                    if (!LeadRectIsZero(areaOptions.area)) {
                        // Copy the area of the page
                        page = [page copy:&error];
                        if (page == nil) {
                            if (error.code != LTErrorCodeUserAbort)
                                [self displayErrorMessage:error.localizedDescription terminate:NO];
                            return;
                        }
                    }
                }
                
                if (!_abort) {
                    document = [_engine.documentManager createDocument:nil options:LTOcrCreateDocumentOptionsAutoDeleteFile error:&error];
                    [document.pages addPage:page error:&error];
                    
                    if (document == nil) {
                        if (error.code != LTErrorCodeUserAbort)
                            [self displayErrorMessage:error.localizedDescription terminate:NO];
                        return;
                    }
                }
                
                if (!_abort) {
                    NSDate * const endDate = [NSDate date];
                    dispatch_on_main_queue(NO, ^{
                        _elapsedTimeLabel.text = [NSString stringWithFormat:@"%0.2f (s)", [endDate timeIntervalSinceDate:startDate]];
                    });
                }
                
                dispatch_on_main_queue(YES, ^{
                    if (!_abort)
                        [self displayRecognitionResults:document page:page];
                });
            }
        }
        @finally {
            [self restoreRecognizeOptions:modifiedOptions];
            
            dispatch_on_main_queue(YES, ^{
                [UIApplication sharedApplication].idleTimerDisabled = NO;
                self.tabBar.selectedItem = [self.tabBarItems pop];
            });
        }
    }
}

- (void)recognizeQuickTextInBounds:(LeadRect)bounds intelligent:(BOOL)intelligent {
    dispatch_on_main_queue(NO, ^{
        _elapsedTimeLabel.text = @"N/A";
    });
    
    @autoreleasepool {
        NSDate * const startDate = [NSDate date];
        LTRasterImage * const image = [_imageViewer.rasterImage clone:nil];
        NSMutableDictionary<NSString *, NSString *> *modifiedOptions = [[self setRecognizeOptions:OutputFormatText hasSelectionArea:!LeadRectIsZero(bounds) ocrImage:image] mutableCopy];
        
        // We aren't expecting an exception to be thrown. We are using this for the try-finally semantics to ensure that the recognize options are restored
        @try {
            NSError *error = nil;
            _abort = NO;
            
            LTOcrPage *ocrPage = nil;
            LTOcrProgressHandler progressHandler = ^(LTOcrProgressData *progressData) {
                dispatch_on_main_queue(NO, ^{
                    if (_abort)
                        progressData.status = LTOcrProgressStatusAbort;
                    else {
                        _operationLabel.attributedText = [[NSAttributedString alloc] initWithString:[self friendlyNameForOperation:progressData.operation] attributes:@{ NSKernAttributeName : @(1.0) }];
                        _progressBar.progress          = progressData.percentage / 100.0;
                    }
                });
            };
            
            ocrPage = [_engine createPage:image sharingMode:LTOcrImageSharingModeAutoDispose error:&error];
            
            if (ocrPage == nil) {
                if (error.code != LTErrorCodeUserAbort)
                    [self displayErrorMessage:error.localizedDescription terminate:NO];
                return;
            }
            
            LTOcrPageAreaOptions * const areaOptions = [LTOcrPageAreaOptions optionsWithArea:bounds intersectPercentage:50 useTextZone:!intelligent];
            ocrPage.areaOptions = areaOptions;
            
            dispatch_on_main_queue(NO, ^{
                _operationLabel.attributedText = [[NSAttributedString alloc] initWithString:@"Process Image" attributes:@{ NSKernAttributeName : @(1.0) }];
            });
            
            if (_autoInvertImages)
                [ocrPage autoPreprocess:LTOcrAutoPreprocessPageCommandInvert progress:progressHandler error:nil];
            
            if (_autoRotateImages)
                [ocrPage autoPreprocess:LTOcrAutoPreprocessPageCommandRotate progress:progressHandler error:nil];
            
            [ocrPage autoPreprocess:LTOcrAutoPreprocessPageCommandDeskew progress:progressHandler error:nil];
            
            if (_abort) return;
            
            if (![ocrPage recognize:progressHandler error:&error]) {
                if (error.code != LTErrorCodeUserAbort)
                    [self displayErrorMessage:error.localizedDescription terminate:NO];
                return;
            }
            
            if (_abort) return;
            
            NSDate * const endDate = [NSDate date];
            dispatch_on_main_queue(NO, ^{
                _elapsedTimeLabel.text = [NSString stringWithFormat:@"%0.2f (s)", [endDate timeIntervalSinceDate:startDate]];
            });
            
            NSString * const recognizedText = [ocrPage textForZoneAtIndex:-1 error:&error];
            if (recognizedText == nil && error != nil) {
                dispatch_on_main_queue(NO, ^{
                    [self displayNoTextFoundAlert];
                });
                return;
            }
            
            if (recognizedText != nil && recognizedText.length > 0) {
                [self displayQuickTextResults:[recognizedText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]];
            }
            else
                dispatch_on_main_queue(NO, ^{
                    [self displayNoTextFoundAlert];
                });
        }
        @finally {
            dispatch_on_main_queue(NO, ^{
                self.tabBar.selectedItem = [self.tabBarItems pop];
            });
            
            [self restoreRecognizeOptions:modifiedOptions];
        }
    }
}

- (void)displayNoTextFoundAlert {
    UIAlertController * const alert = [UIAlertController alertControllerWithTitle:nil message:@"No text found" preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:@"Help" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UIAlertController * const help = [UIAlertController alertControllerWithTitle:nil message:@"Check that your image is properly oriented\n\nCheck that your image is clearly lit\n\nCheck the recognition settings in the options menu" preferredStyle:UIAlertControllerStyleAlert];
        
        [help addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
        [help addAction:[UIAlertAction actionWithTitle:@"Options" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            self.tabBar.selectedItem = self.tabBar.items[4];
            [self tabBar:self.tabBar didSelectItem:self.tabBar.items[4]];
        }]];
        
        [self presentViewController:help animated:YES completion:nil];
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)displayErrorMessage:(NSString *)message terminate:(BOOL)terminate {
    UIAlertController * const alert = [UIAlertController alertControllerWithTitle:@"Warning" message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        if (terminate) exit(0);
    }]];
    
    dispatch_on_main_queue(NO, ^{
        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (void)displayAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleCancel handler:nil]];
    
    dispatch_on_main_queue(NO, ^{
        [self presentViewController:alert animated:YES completion:nil];
    });
}

- (void)displayRecognitionResults:(LTOcrDocument *)document page:(LTOcrPage *)page {
    NSError *error = nil;
    
    const LTDocumentFormat format = [self setOutputDocumentFormatOptions:_engine.documentWriterInstance outputFormat:_outputFormat];
    
    NSString * const documentsDirectory = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString * const filePath = [documentsDirectory stringByAppendingPathComponent:[@"Recognition Results" stringByAppendingPathExtension:[LTDocumentWriter fileExtensionForFormat:format]]];
    NSString * const xmlFilePath = [filePath stringByAppendingPathExtension:@"xml"];
    
    NSFileManager * const fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:filePath])
        [fileManager removeItemAtPath:filePath error:nil];
    
    if ([fileManager fileExistsAtPath:xmlFilePath])
        [fileManager removeItemAtPath:xmlFilePath error:nil];
    
    if (![document saveToFile:filePath format:format progress:nil error:&error]) {
        [self displayErrorMessage:error.localizedDescription terminate:NO];
        return;
    }
    
    if (page != nil)
        [page saveXmlToFile:xmlFilePath pageNumber:1 xmlWriteOptions:nil outputOptions:LTOcrXmlOutputOptionsCharacters | LTOcrXmlOutputOptionsCharacterAttributes error:nil];
    
    NSURL * const fileURL = [NSURL fileURLWithPath:filePath];
    
    UIDocumentInteractionController * const documentController = [UIDocumentInteractionController interactionControllerWithURL:fileURL];
    
    documentController.delegate = self;
    
    if (![documentController presentPreviewAnimated:YES]) {
        UIActivityViewController * const activity = [[UIActivityViewController alloc] initWithActivityItems:@[fileURL] applicationActivities:nil];
        activity.completionWithItemsHandler = ^(UIActivityType activityType, BOOL completed, NSArray *returnedItems, NSError *activityError) {
            
        };
        
        [self configureControllerForCurrentDevice:activity];
        [self presentViewController:activity animated:YES completion:nil];
    }
}

- (void)displayQuickTextResults:(NSString *)recognitionText {
    UIViewController * const controller = [self.storyboard instantiateViewControllerWithIdentifier:@"QuickTextViewController"];
    
    if ([controller isKindOfClass:[UINavigationController class]]) {
        UINavigationController * const navigationController = (UINavigationController *)controller;
        
        if ([navigationController.topViewController isKindOfClass:[QuickTextViewController class]]) {
            QuickTextViewController * const quickTextController = (QuickTextViewController *)navigationController.topViewController;
            
            quickTextController.recognitionText = recognitionText;
            
            dispatch_on_main_queue(NO, ^{
                [self presentViewController:navigationController animated:YES completion:nil];
            });
        }
    }
}

- (void)setPanZoomInteractiveMode {
    LTImageViewerPanZoomInteractiveMode * const panZoom = [[LTImageViewerPanZoomInteractiveMode alloc] init];
    panZoom.enableRotate = NO;
    
    _imageViewer.touchInteractiveMode = panZoom;
}

- (void)doubleTap:(NSNotification *)notification {
    UIGestureRecognizer * const gestureRecognizer = (UIGestureRecognizer *)notification.userInfo[LTInteractiveServiceGestureRecognizerKey];
    
    if ([_imageViewer.touchInteractiveMode isKindOfClass:[LTImageViewerPanZoomInteractiveMode class]]) {
        if (_imageViewer.scaleFactor == 1.0 && _imageViewer.sizeMode == LTImageViewerSizeModeFitAlways)
            [_imageViewer zoomWithSizeMode:LTImageViewerSizeModeActualSize scaleFactor:1.0 origin:[gestureRecognizer locationInView:_imageViewer]];
        else
            [_imageViewer zoomWithSizeMode:LTImageViewerSizeModeFitAlways scaleFactor:1.0 origin:_imageViewer.defaultZoomOrigin];
    }
    else if ([_imageViewer.touchInteractiveMode isKindOfClass:[LTImageViewerSelectAreaInteractiveMode class]]) {
        if (CGRectContainsPoint(((LTImageViewerSelectAreaInteractiveMode *)_imageViewer.touchInteractiveMode).selectedArea, [gestureRecognizer locationInView:_imageViewer])) {
            _tabBar.selectedItem = _recognizeItem;
            [self tabBar:_tabBar didSelectItem:_recognizeItem];
        }
    }
}

- (void)presentActivityView:(BOOL)show {
    _blockingView.hidden = !show;
    
    dispatch_on_main_queue(NO, ^{
        if (!show) {
            [_blockingView.superview sendSubviewToBack:_blockingView];
            [_blockingView.superview sendSubviewToBack:_operationLabel];
            [_blockingView.superview sendSubviewToBack:_progressBar];
            [_blockingView.superview sendSubviewToBack:_cancelButton];
            
            _operationLabel.hidden = !show;
            _progressBar.hidden    = !show;
            _cancelButton.hidden   = !show;
            
            _operationLabel.text   = @"";
            _progressBar.progress  = 0.0;
            
            return;
        }
        
        [_blockingView.superview bringSubviewToFront:_blockingView];
        [_blockingView.superview bringSubviewToFront:_operationLabel];
        [_blockingView.superview bringSubviewToFront:_progressBar];
        [_blockingView.superview bringSubviewToFront:_cancelButton];
        
        _operationLabel.hidden = !show;
        _progressBar.hidden    = !show;
        _cancelButton.hidden   = !show;
        
        _operationLabel.text   = @"";
        _progressBar.progress  = 0.0;
    });
}

- (NSString *)friendlyNameForOperation:(LTOcrProgressOperation)operation {
    switch (operation) {
        case LTOcrProgressOperationLoadImage:                return @"Load Image";
        case LTOcrProgressOperationSaveImage:                return @"Save Image";
        case LTOcrProgressOperationPreprocessImage:          return @"Process Image";
        case LTOcrProgressOperationAutoZone:                 return @"Find Zones";
        case LTOcrProgressOperationRecognize:                return @"Recognize - First Pass";
        case LTOcrProgressOperationSaveDocumentPrepare:      return @"Save Document - Prepare";
        case LTOcrProgressOperationSaveDocument:             return @"Save Document";
        case LTOcrProgressOperationSaveDocumentConvertImage: return @"Save Document - Convert Image";
        case LTOcrProgressOperationFormatting:               return @"Formatting";
        case LTOcrProgressOperationRecognizeOMR:             return @"Recognize Omr";
    }
}

- (LTDocumentFormat)setOutputDocumentFormatOptions:(LTDocumentWriter *)documentWriter outputFormat:(OutputFormat)outputFormat {
    LTDocumentFormat format           = LTDocumentFormatUser;
    LTDocumentDropObjects dropObjects = _detectGraphicsAndColors ? LTDocumentDropObjectsNone : (LTDocumentDropObjectsDropImages | LTDocumentDropObjectsDropShapes);
    
    switch (outputFormat) {
        case OutputFormatPdf:
        case OutputFormatPdfEmbed:
        case OutputFormatPdfA:
        case OutputFormatPdfImageOverText:
        case OutputFormatPdfEmbedImageOverText:
        case OutputFormatPdfAImageOverText:
        {
            format = LTDocumentFormatPdf;
            LTPdfDocumentOptions * const pdfOptions = (LTPdfDocumentOptions *)[documentWriter optionsForFormat:format];
            
            if (outputFormat == OutputFormatPdfA || outputFormat == OutputFormatPdfAImageOverText)
                pdfOptions.documentType = LTPdfDocumentTypePdfA;
            else
                pdfOptions.documentType = LTPdfDocumentTypePdf;
            
            if (outputFormat == OutputFormatPdfEmbed || outputFormat == OutputFormatPdfEmbedImageOverText)
                pdfOptions.fontEmbedMode = LTDocumentFontEmbedModeAll;
            else
                pdfOptions.fontEmbedMode = LTDocumentFontEmbedModeAuto;
            
            pdfOptions.imageOverText = (outputFormat == OutputFormatPdfImageOverText || outputFormat == OutputFormatPdfEmbedImageOverText || outputFormat == OutputFormatPdfAImageOverText);
            pdfOptions.dropObjects   = dropObjects;
        }
            break;
            
        case OutputFormatDocx:
        case OutputFormatDocxFramed:
        {
            format = LTDocumentFormatDocx;
            LTDocxDocumentOptions * const docxOptions = (LTDocxDocumentOptions *)[documentWriter optionsForFormat:format];
            
            docxOptions.textMode    = (outputFormat == OutputFormatDocxFramed ? LTDocumentTextModeFramed : LTDocumentTextModeNonFramed);
            docxOptions.dropObjects = dropObjects;
        }
            break;
            
        case OutputFormatRtf:
        case OutputFormatRtfFramed:
        {
            format = LTDocumentFormatRtf;
            LTRtfDocumentOptions * const rtfOptions = (LTRtfDocumentOptions *)[documentWriter optionsForFormat:format];
            
            rtfOptions.textMode    = (outputFormat == OutputFormatRtfFramed ? LTDocumentTextModeFramed : LTDocumentTextModeNonFramed);
            rtfOptions.dropObjects = dropObjects;
        }
            break;
            
        case OutputFormatText:
        case OutputFormatTextFormatted:
        {
            format = LTDocumentFormatText;
            LTTextDocumentOptions * const txtOptions = (LTTextDocumentOptions *)[documentWriter optionsForFormat:format];
            
            txtOptions.documentType = LTTextDocumentTypeUTF8;
            txtOptions.formatted    = (outputFormat == OutputFormatTextFormatted);
        }
            break;
            
        case OutputFormatSvg:
            format = LTDocumentFormatSvg;
            break;
    }
    
    return format;
}

// Change the recognition options of the engine based on the demo options and output format
- (NSDictionary<NSString *, NSString *> *)setRecognizeOptions:(OutputFormat)outputFormat hasSelectionArea:(BOOL)hasSelectionArea ocrImage:(LTRasterImage *)ocrImage {
    LTOcrSettingManager * const settingManager = _engine.settingManager;
    
    // Detect whether we want to export graphics and colored text
    // Disabling this option if not needed (for example, when the output format is text) enhances the optimization speed
    BOOL detectColors;
    
    switch (outputFormat) {
        case OutputFormatText:
        case OutputFormatTextFormatted:
        case OutputFormatPdfImageOverText:
        case OutputFormatPdfAImageOverText:
        case OutputFormatPdfEmbedImageOverText:
            detectColors = NO;
            break;
            
        default:
            detectColors = _detectGraphicsAndColors;
            break;
    }
    
    // Detect whether we want to detect font styles and attributes
    // Disabling this option if not needed (for example, when the output format is text) enhances the optimization speed
    BOOL detectFontStylesAndAttributes;
    
    switch (outputFormat) {
        case OutputFormatText:
        case OutputFormatTextFormatted:
            detectFontStylesAndAttributes = NO;
            break;
            
        default:
            detectFontStylesAndAttributes = YES;
            break;
    }
    
    // Detect whether we want to detect font styles and attributes
    // Disabling this option if not needed (for example, when the output format is text) enhances the optimization speed
    BOOL detectTables;
    
    switch (outputFormat) {
        case OutputFormatText:
            detectTables = NO;
            // For formatted text, use the option since tables will help in constructing the final document accurately
            break;
            
        default:
            // Use what the user selected in the options
            detectTables = _detectTables;
    }
    
    // Set this if image has DPI greater than or equal to 150
    const BOOL isDocumentImage = MAX(ocrImage.xResolution, ocrImage.yResolution) >= 150;
    
    // Now set the settings in the OCR engine (saving the original settings so we can restore them later)
    NSMutableDictionary<NSString *, NSString *> * const modifiedSettings = [NSMutableDictionary dictionary];
    
    NSString *settingName = @"Recognition.DetectColors";
    modifiedSettings[settingName] = [settingManager valueForSetting:settingName];
    [settingManager setBooleanValue:detectColors forSetting:settingName];
    
    settingName = @"Recognition.Fonts.RecognizeFontAttributes";
    modifiedSettings[settingName] = [settingManager valueForSetting:settingName];
    [settingManager setBooleanValue:detectFontStylesAndAttributes forSetting:settingName];
    
    settingName = @"Recognition.Fonts.DetectFontStyles";
    modifiedSettings[settingName] = [settingManager valueForSetting:settingName];
    if (!detectFontStylesAndAttributes)
        [settingManager setEnumValue:(NSInteger)LTOcrCharacterFontStyleRegular forSetting:settingName];
    
    if (!detectTables) {
        settingName = @"Recognition.Zoning.Options";
        modifiedSettings[settingName] = [settingManager valueForSetting:settingName];
        NSUInteger autoZoneOptions = (NSUInteger)[settingManager enumValueForSetting:settingName];
        
        // Remove table detection
        autoZoneOptions &= ~AutoZoneOptionsDetectTable;
        [settingManager setEnumValue:(NSInteger)autoZoneOptions forSetting:settingName];
    }
    
    // For this demo purposes, we do not want to invert the original image
    settingName = @"Recognition.Preprocess.ModifyOriginalImageOptions";
    modifiedSettings[settingName] = [settingManager valueForSetting:settingName];
    NSUInteger modifyOriginalImageOptions = [settingManager enumValueForSetting:settingName];
    
    // Remove "Invert" option
    modifyOriginalImageOptions &= ~ModifyOriginalImageOptionsInvert;
    [settingManager setEnumValue:modifyOriginalImageOptions forSetting:settingName];
    
    // Tell the OCR engine if the image is a document or a picture
    [settingManager setBooleanValue:!isDocumentImage forSetting:@"Recognition.Preprocess.MobileImagePreprocess"];
    
    // Tell the OCR engine to auto-process the inverted regions in the image
    settingName = @"Recognition.Preprocess.RemoveInvertedTextRegionsFromProcessImage";
    modifiedSettings[settingName] = [settingManager valueForSetting:settingName];
    [settingManager setBooleanValue:_detectInvertedRegions forSetting:settingName];
    
    // Tell the OCR engine to ignore zones with low confidence values if we are performing full page recognition
    settingName = @"Recognition.Words.DiscardLowConfidenceZones";
    modifiedSettings[settingName] = [settingManager valueForSetting:settingName];
    [settingManager setBooleanValue:!hasSelectionArea forSetting:settingName];
    
    return modifiedSettings;
}

- (void)restoreRecognizeOptions:(NSDictionary<NSString *, NSString *> *)modifiedSettings {
    if (modifiedSettings.count != 0) {
        [modifiedSettings enumerateKeysAndObjectsUsingBlock:^(NSString *settingName, NSString *value, BOOL *stop) {
            [_engine.settingManager setValue:value forSetting:settingName];
        }];
    }
}

@end

#pragma mark - Class (TabBarItemStack) Implementation

@implementation TabBarItemStack {
    NSMutableArray<UITabBarItem *> *_items;
}

#pragma mark - Property Synthesis

@synthesize popHandler = _popHandler;
@dynamic currentItem;

- (UITabBarItem *)currentItem {
    return _items.lastObject;
}

#pragma mark - Initialization

- (instancetype)initWithItem:(UITabBarItem *)item {
    if (self = [super init]) {
        _items = [NSMutableArray arrayWithObject:item];
    }
    
    return self;
}

#pragma mark - Public Methods

- (void)push:(UITabBarItem *)item {
    [_items addObject:item];
}

- (UITabBarItem *)pop {
    if (_items.count > 1)
        [_items removeLastObject];
    
    if (_popHandler != nil)
        _popHandler(_items.lastObject);
    
    return _items.lastObject;
}

@end

#pragma mark - NSUserDefaults Category (HasValueForKey) Implementation

@implementation NSUserDefaults (HasValueForKey)

- (BOOL)hasValueForKey:(NSString *)key {
    return [self objectForKey:key] != nil;
}

@end

#pragma mark - LTImageViewer Category (SelectAreaMode) Implementation

@implementation LTImageViewer (SelectAreaMode)

@dynamic isSelectAreaMode;
- (BOOL)isSelectAreaMode {
    return self.touchInteractiveMode != nil && ([self.touchInteractiveMode isKindOfClass:[LTImageViewerSelectAreaInteractiveMode class]] || [self.touchInteractiveMode isKindOfClass:[LTImageViewerRubberBandInteractiveMode class]]);
}

@end
