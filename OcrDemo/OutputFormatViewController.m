//
//  OutputFormatViewController.m
//  OcrDemo
//
//  Copyright © 1991-2017 LEAD Technologies, Inc. All rights reserved.
//

#import "OutputFormatViewController.h"

#pragma mark - Functions

NSString *friendlyNameForOutputFormat(OutputFormat format) {
    switch (format) {
        case OutputFormatPdf:                   return @"PDF";
        case OutputFormatPdfEmbed:              return @"PDF Embedded Fonts";
        case OutputFormatPdfA:                  return @"PDF/A";
        case OutputFormatPdfImageOverText:      return @"PDF Image Over Text";
        case OutputFormatPdfEmbedImageOverText: return @"PDF Image Over Text | Embedded Fonts";
        case OutputFormatPdfAImageOverText:     return @"PDF/A Image Over Text";
        case OutputFormatDocx:                  return @"DOCX";
        case OutputFormatDocxFramed:            return @"DOCX Framed";
        case OutputFormatRtf:                   return @"RTF";
        case OutputFormatRtfFramed:             return @"RTF Framed";
        case OutputFormatText:                  return @"Text";
        case OutputFormatTextFormatted:         return @"Text Formatted";
        case OutputFormatSvg:                   return @"SVG";
    }
}

#pragma mark - Class Extension

@interface OutputFormatViewController() <UITableViewDelegate, UITableViewDataSource, UIGestureRecognizerDelegate>

@property (nonatomic, strong) IBOutlet UIButton *backButton;
@property (nonatomic, strong) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) IBOutlet UITableView *tableView;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *clearViewConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *titleLabelConstraint;

@property (nonatomic, strong) UITapGestureRecognizer *gestureRecognizer;

@end

#pragma mark - Class Implementation

@implementation OutputFormatViewController

#pragma mark - Property Synthesis

@synthesize format = _format, languages = _languages, selectedLanguage = _selectedLanguage, constraint = _constraint, backButton = _backButton, titleLabel = _titleLabel, tableView = _tableView, clearViewConstraint = _clearViewConstraint, titleLabelConstraint = _titleLabelConstraint, gestureRecognizer = _gestureRecognizer;

- (void)setConstraint:(CGFloat)constraint {
    _constraint                   = constraint;
    _clearViewConstraint.constant = constraint;
}

- (void)setClearViewConstraint:(NSLayoutConstraint *)clearViewConstraint {
    _clearViewConstraint          = clearViewConstraint;
    _clearViewConstraint.constant = _constraint;
}

- (void)setTitleLabelConstraint:(NSLayoutConstraint *)titleLabelConstraint {
    _titleLabelConstraint = titleLabelConstraint;
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
        _titleLabelConstraint.constant = 16.0;
}

- (void)setTitleLabel:(UILabel *)titleLabel {
    _titleLabel                = titleLabel;
    _titleLabel.attributedText = [[NSAttributedString alloc] initWithString:_languages != nil ? @"LANGUAGE" : _titleLabel.text attributes:@{ NSKernAttributeName : @(2.0) }];
}

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _tableView.backgroundColor = [UIColor colorWithRed:0.1569 green:0.1647 blue:0.2353 alpha:1.0];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        if (_gestureRecognizer == nil) {
            _gestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapGestureRecognized:)];
            _gestureRecognizer.numberOfTapsRequired = 1;
            _gestureRecognizer.cancelsTouchesInView = NO;
            _gestureRecognizer.delegate             = self;
        }
        
        [self.view.window addGestureRecognizer:_gestureRecognizer];
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
        [self.view.window removeGestureRecognizer:_gestureRecognizer];
}

#pragma mark - UITableViewDelegate Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return (NSInteger)(_languages != nil ? _languages.count : OutputFormatSvg + 1);
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (_languages != nil)
        _selectedLanguage = _languages[indexPath.row];
    else
        _format = (OutputFormat)indexPath.row;
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    [tableView reloadData];
    
    [self performSegueWithIdentifier:@"outputFormatSelected" sender:self];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
    // Background color correction for iPad devices
    if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad)
        cell.backgroundColor = [UIColor clearColor];
}

#pragma mark - UITableViewDataSource Methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString * const CellIdentifier = @"com.leadtools.ocrdemo.outputformatcell";
    UITableViewCell * const cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier forIndexPath:indexPath];
    
    if (_languages != nil) {
        cell.textLabel.attributedText = [[NSAttributedString alloc] initWithString:[[NSLocale currentLocale] displayNameForKey:NSLocaleIdentifier value:_languages[indexPath.row]] attributes:@{ NSKernAttributeName : @(1.0) }];
        cell.accessoryType            = [_selectedLanguage isEqualToString:_languages[indexPath.row]] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    else {
        cell.textLabel.attributedText = [[NSAttributedString alloc] initWithString:friendlyNameForOutputFormat((OutputFormat)indexPath.row) attributes:@{ NSKernAttributeName : @(1.0) }];
        cell.accessoryType            = (_format == indexPath.row) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    
    cell.selectedBackgroundView = [[UIView alloc] init];
    cell.selectedBackgroundView.backgroundColor = [UIColor colorWithRed:0.2588 green:0.2745 blue:0.5098 alpha:1.0];
    
    return cell;
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

#pragma mark - Custom Methods

- (void)tapGestureRecognized:(UITapGestureRecognizer *)sender {
    const CGPoint touchLocation = [sender locationInView:self.view];
    
    if (!CGRectContainsPoint(CGRectMake(0.0, 0.0, self.view.bounds.size.width, self.view.bounds.size.height), touchLocation))
        [self done:sender];
}

#pragma mark - Action Methods

- (IBAction)done:(id)sender {
    [self performSegueWithIdentifier:@"DismissSettings" sender:self];
}

@end
