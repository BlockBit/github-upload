//
//  OptionsViewController.m
//  OcrDemo
//
//  Copyright © 1991-2017 LEAD Technologies, Inc. All rights reserved.
//

#import "OptionsViewController.h"
#import "AdditionalLanguagesViewController.h"
#import "UI Controls/Switch.h"
#import "UI Controls/ToolbarView.h"
#import "UI Controls/DualStateButton.h"

#pragma mark - Class Extension

@interface OptionsViewController () <UIGestureRecognizerDelegate>

@property (nonatomic, strong)           IBOutlet Switch *detectGraphicsAndColorsSwitch;
@property (nonatomic, strong)           IBOutlet Switch *detectInvertedRegionsSwitch;
@property (nonatomic, strong)           IBOutlet Switch *detectTablesSwitch;
@property (nonatomic, strong)           IBOutlet Switch *intelligentSelectAreaSwitch;
@property (nonatomic, strong)           IBOutlet Switch *autoInvertImagesSwitch;
@property (nonatomic, strong)           IBOutlet Switch *autoRotateImagesSwitch;
@property (nonatomic, strong)           IBOutlet UIButton *languageButton;
@property (nonatomic, strong)           IBOutlet UIButton *outputFormatButton;
@property (nonatomic, strong)           IBOutlet UISegmentedControl *selectAreaModeControl;

@property (nonatomic, strong)           IBOutlet UIButton *doneButton;
@property (nonatomic, strong)           IBOutlet UILabel *titleLabel;

@property (nonatomic, strong)           IBOutlet NSLayoutConstraint *titleLabelConstraint;
@property (nonatomic, strong)           IBOutlet NSLayoutConstraint *clearViewConstraint;
@property (nonatomic, strong)           IBOutlet NSLayoutConstraint *switchSpacingConstraint;

@property (nonatomic, strong)           UITapGestureRecognizer *tapGestureRecognizer;
@property (nonatomic, strong)           UISwipeGestureRecognizer *dragGestureRecognizer;
@property (nonatomic, assign)           CGFloat constraint;
@property (nonatomic, assign, readonly) BOOL canUseConstraint;

@end

#pragma mark - Class Implementation

@implementation OptionsViewController

#pragma mark - Property Synthesis

@synthesize availableLanguages = _availableLanguages, currentLanguage = _currentLanguage, detectGraphicsAndColors = _detectGraphicsAndColors, detectInvertedRegions = _detectInvertedRegions, intelligentSelectArea = _intelligentSelectArea, autoInvertImages = _autoInvertImages, autoRotateImages = _autoRotateImages, selectAreaMode = _selectAreaMode, allowedConstraintValues = _allowedConstraintValues, format = _format, detectGraphicsAndColorsSwitch = _detectGraphicsAndColorsSwitch, detectInvertedRegionsSwitch = _detectInvertedRegionsSwitch, detectTablesSwitch = _detectTablesSwitch, intelligentSelectAreaSwitch = _intelligentSelectAreaSwitch, autoInvertImagesSwitch = _autoInvertImagesSwitch, outputFormatButton = _outputFormatButton, selectAreaModeControl = _selectAreaModeControl, doneButton = _doneButton, titleLabel = _titleLabel, titleLabelConstraint = _titleLabelConstraint, clearViewConstraint = _clearViewConstraint, switchSpacingConstraint = _switchSpacingConstraint, tapGestureRecognizer = _tapGestureRecognizer, constraint = _constraint;
@dynamic canUseConstraint;

- (void)setFormat:(OutputFormat)format {
    _format = format;
    [_outputFormatButton setTitle:friendlyNameForOutputFormat(format) forState:UIControlStateNormal];
}

- (void)setDoneButton:(UIButton *)doneButton {
    _doneButton = doneButton;
    
    [_doneButton setAttributedTitle:[[NSAttributedString alloc] initWithString:_doneButton.titleLabel.text attributes:@{ NSKernAttributeName : @(1.0), NSForegroundColorAttributeName : [UIColor whiteColor] }] forState:UIControlStateNormal | UIControlStateSelected];
    _doneButton.hitTestEdgeInsets = UIEdgeInsetsMake(-10.0, -10.0, -10.0, -10.0);
}

- (void)setTitleLabel:(UILabel *)titleLabel {
    _titleLabel = titleLabel;
    _titleLabel.attributedText = [[NSAttributedString alloc] initWithString:_titleLabel.text attributes:@{ NSKernAttributeName : @(2.0) }];
}

- (BOOL)canUseConstraint {
    if (_constraint != 0.0)
        return YES;
    
    if (_outputFormatButton != nil && _selectAreaModeControl != nil) {
        BOOL success = NO;
        
        for (NSNumber *constraint in _allowedConstraintValues) {
            if (_outputFormatButton.frame.origin.y + _outputFormatButton.frame.size.height + 16.0 + constraint.doubleValue <= _selectAreaModeControl.frame.origin.y) {
                _constraint = constraint.doubleValue;
                success     = YES;
                break;
            }
        }
        
        if (!success) {
            const CGFloat switchSpacingConstraintOldValue = _switchSpacingConstraint.constant;
            _switchSpacingConstraint.constant = 8.0;
            
            for (NSNumber *constraint in _allowedConstraintValues) {
                const CGFloat switchesSpacing = (switchSpacingConstraintOldValue - _switchSpacingConstraint.constant) * 5.0;
                
                if (_outputFormatButton.frame.origin.y + _outputFormatButton.frame.size.height + 16.0 + constraint.doubleValue - switchesSpacing <= _selectAreaModeControl.frame.origin.y) {
                    _constraint = constraint.doubleValue;
                    success     = YES;
                    break;
                }
            }
            
            if (!success)
                _switchSpacingConstraint.constant = switchSpacingConstraintOldValue;
        }
        
        return success;
    }
    
    return NO;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSInteger index = [_availableLanguages indexOfObject:_currentLanguage];
    if (index == NSNotFound)
        @throw [NSException exceptionWithName:NSInternalInconsistencyException reason:@"'currentLanguage' is not contained within 'availableLanguages'" userInfo:nil];
    
    _detectGraphicsAndColorsSwitch.on           = _detectGraphicsAndColors;
    _detectInvertedRegionsSwitch.on             = _detectInvertedRegions;
    _detectTablesSwitch.on                      = _detectTables;
    _intelligentSelectAreaSwitch.on             = _intelligentSelectArea;
    _autoInvertImagesSwitch.on                  = _autoInvertImages;
    _autoRotateImagesSwitch.on                  = _autoRotateImages;
    _selectAreaModeControl.selectedSegmentIndex = (NSInteger)_selectAreaMode;
}

- (void)viewWillAppear:(BOOL)animated {
    _outputFormatButton.titleLabel.lineBreakMode = NSLineBreakByWordWrapping;
    _outputFormatButton.titleLabel.textAlignment = NSTextAlignmentRight;
    [_outputFormatButton setTitle:friendlyNameForOutputFormat(_format) forState:UIControlStateNormal];
    
    _languageButton.titleLabel.textAlignment = NSTextAlignmentRight;
    [_languageButton setTitle:[[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:_currentLanguage] forState:UIControlStateNormal];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        if (_tapGestureRecognizer == nil) {
            _tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognized:)];
            _tapGestureRecognizer.numberOfTapsRequired = 1;
            _tapGestureRecognizer.cancelsTouchesInView = NO;
            _tapGestureRecognizer.delegate             = self;
        }
        
        [self.view.window addGestureRecognizer:_tapGestureRecognizer];
    }
    if (self.constraint > 0.0 || [UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        if (_dragGestureRecognizer == nil) {
            _dragGestureRecognizer = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(dragGestureRecognized:)];
            _dragGestureRecognizer.cancelsTouchesInView = NO;
            _dragGestureRecognizer.delaysTouchesBegan   = YES;
            _dragGestureRecognizer.direction            = UISwipeGestureRecognizerDirectionDown;
            _dragGestureRecognizer.delegate             = self;
        }
        
        [self.view.window addGestureRecognizer:_dragGestureRecognizer];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
        [self.view.window removeGestureRecognizer:_tapGestureRecognizer];
    if (_dragGestureRecognizer != nil)
        [self.view.window removeGestureRecognizer:_dragGestureRecognizer];
}

- (void)viewWillLayoutSubviews {
    [super viewWillLayoutSubviews];
    
    if ([UIDevice currentDevice].userInterfaceIdiom != UIUserInterfaceIdiomPad) {
        if (self.canUseConstraint) {
            _titleLabelConstraint.constant = 16.0;
            _clearViewConstraint.constant  = _constraint;
        }
        else
            _titleLabelConstraint.constant = 36.0; // 20px for status bar + 16px of space
    }
}

#pragma mark - UIGestureRecognizerDelegate Methods

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
    return YES;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    return YES;
}

#pragma mark - Navigation Methods

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.destinationViewController isKindOfClass:[OutputFormatViewController class]]) {
        OutputFormatViewController * const outputFormatController = (OutputFormatViewController *)segue.destinationViewController;
        
        outputFormatController.format = _format;
        
        if (sender == _languageButton) {
            outputFormatController.languages        = _availableLanguages;
            outputFormatController.selectedLanguage = _currentLanguage;
        }
        
        if (_dragGestureRecognizer != nil)
            [self.view.window removeGestureRecognizer:_dragGestureRecognizer];
    }
}

- (IBAction)outputFormatViewDidComplete:(UIStoryboardSegue *)segue {
    if ([segue.sourceViewController isKindOfClass:[OutputFormatViewController class]]) {
        OutputFormatViewController * const outputFormatController = (OutputFormatViewController *)segue.sourceViewController;
        
        self.format = outputFormatController.format;
        
        if (outputFormatController.selectedLanguage != nil) {
            _currentLanguage = outputFormatController.selectedLanguage;
            [_languageButton setTitle:[[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:_currentLanguage] forState:UIControlStateNormal];
        }
    }
    
    // For devices running iOS < 9.0, we need to dismiss this view controller manually. (bug)
    if ([NSProcessInfo processInfo].operatingSystemVersion.majorVersion < 9)
        [segue.sourceViewController dismissViewControllerAnimated:YES completion:nil];
    
    [self viewDidAppear:YES];
    
    if ([segue.identifier isEqualToString:@"DismissSettings"])
        [self performSegueWithIdentifier:segue.identifier sender:self];
}

#pragma mark - Custom Methods

- (void)tapGestureRecognized:(UITapGestureRecognizer *)sender {
    const CGPoint touchLocation = [sender locationInView:self.view];
    
    if (!CGRectContainsPoint(CGRectMake(0.0, 0.0, self.view.bounds.size.width, self.view.bounds.size.height), touchLocation))
        [self doneButton:sender];
}

- (void)dragGestureRecognized:(UISwipeGestureRecognizer *)sender {
    [self doneButton:sender];
}

#pragma mark - Action Methods

- (IBAction)detectGraphicsAndColorsSwitch:(id)sender {
    _detectGraphicsAndColors = _detectGraphicsAndColorsSwitch.on;
}

- (IBAction)detectInvertedRegionsSwitch:(id)sender {
    _detectInvertedRegions = _detectInvertedRegionsSwitch.on;
}

- (IBAction)detectTablesSwitch:(id)sender {
    _detectTables = _detectTablesSwitch.on;
}

- (IBAction)intelligentSelectAreaSwitch:(id)sender {
    _intelligentSelectArea = _intelligentSelectAreaSwitch.on;
}

- (IBAction)autoInvertImagesSwitch:(id)sender {
    _autoInvertImages = _autoInvertImagesSwitch.on;
}

- (IBAction)autoRotateImagesSwitch:(id)sender {
    _autoRotateImages = _autoRotateImagesSwitch.on;
}

- (IBAction)selectAreaModeControl:(id)sender {
    _selectAreaMode = (SelectAreaMode)_selectAreaModeControl.selectedSegmentIndex;
}

- (IBAction)doneButton:(id)sender {
    [self performSegueWithIdentifier:@"DismissSettings" sender:self];
}

- (IBAction)showAbout:(id)sender {
    [DemoUtilities showAbout:@"OCR Application"];
}

@end
