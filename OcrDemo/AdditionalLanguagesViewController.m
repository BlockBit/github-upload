//
//  AdditionalLanguagesViewController.m
//  OcrDemo
//
//  Copyright © 1991-2016 LEAD Technologies, Inc. All rights reserved.
//

#import "AdditionalLanguagesViewController.h"
#import "OptionsViewController.h"
#import "ResourceManager.h"
#import "AppDelegate.h"

#pragma mark - Private Variables

static NSArray<NSString *> *bundleTags;

NSString * const DownloadCellIdentifier   = @"com.leadtools.ocrdemo.additionallanguages.downloadcell";
NSString * const DownloadedCellIdentifier = @"com.leadtools.ocrdemo.additionallanguages.downloadedcell";
NSString * const DeleteCellIdentifier     = @"com.leadtools.ocrdemo.additionallanguages.deletecell";

#pragma mark - Class Extension

@interface AdditionalLanguagesViewController()

@property (nonatomic, strong) NSMutableDictionary<NSIndexPath *, UIProgressView *> *progressViews;

@end

#pragma mark - Class Implementation

@implementation AdditionalLanguagesViewController

#pragma mark - Property Synthesis

@synthesize options = _options, progressViews = _progressViews;

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    bundleTags     = [ResourceManager supportedTags];
    _progressViews = [NSMutableDictionary dictionary];
}

#pragma mark - UITableViewDataSource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return bundleTags.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString * const tag  = bundleTags[indexPath.row];
    const double size     = [ResourceManager sizeOfResourcesForTag:tag] / (1024.0 * 1024.0); // Convert from B to MB
    UITableViewCell *cell = nil;
    
    if ([ResourceManager resourceIsPresentLocallyForTag:tag]) {
        if ([ResourceManager canDeleteResourcesForTag:tag])
            cell = [tableView dequeueReusableCellWithIdentifier:DeleteCellIdentifier forIndexPath:indexPath];
        else
            cell = [tableView dequeueReusableCellWithIdentifier:DownloadedCellIdentifier forIndexPath:indexPath];
    }
    else
        cell = [tableView dequeueReusableCellWithIdentifier:DownloadCellIdentifier forIndexPath:indexPath];
    
    UILabel * const languageName    = [cell viewWithTag:1];
    UILabel * const languageSize    = [cell viewWithTag:2];
    UIButton * const button         = [cell viewWithTag:3];
    UIProgressView * const progress = [cell viewWithTag:4];
    
    progress.hidden = YES;
    button.hidden   = NO;
    
    if (_progressViews[indexPath] != nil) {
        [cell addSubview:_progressViews[indexPath]];
        _progressViews[indexPath].hidden = NO;
        button.hidden = YES;
    }
    else if ([cell viewWithTag:-127] != nil)
        [[cell viewWithTag:-127] removeFromSuperview];
    
    languageName.text = [ResourceManager localizedLanguageNameForTag:tag];
    languageSize.text = [NSString stringWithFormat:@"(%0.1f MB)", size];
    
    [button addTarget:self action:@selector(downloadButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

#pragma mark - UITableViewDelegate Methods

- (BOOL)tableView:(UITableView *)tableView shouldHighlightRowAtIndexPath:(NSIndexPath *)indexPath {
    return NO;
}

#pragma mark - Action Methods

- (IBAction)downloadButtonTapped:(id)sender {
    UITableViewCell *cell = (UITableViewCell *)((UIButton *)sender).superview.superview;
    NSIndexPath *indexPath = [self.tableView indexPathForCell:cell];
    
    NSString * const tag = bundleTags[indexPath.row];
    if ([ResourceManager resourceIsPresentLocallyForTag:tag]) {
        [ResourceManager deleteResourcesForTag:tag];
        dispatch_on_main_queue(NO, ^{
            [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
            
            AppDelegate * const delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
            [delegate.engine shutdown];
            [delegate.engine startup:nil workDirectory:nil startupParameters:[ResourceManager directoryForResources] error:nil]; // Since the engine was already started, this shouldn't fail.
            
            NSArray<NSNumber *> * const supportedLanguages = [delegate.engine.languageManager supportedLanguages];
            NSMutableArray<NSString *> * const supportedLangugageNames = [NSMutableArray arrayWithCapacity:supportedLanguages.count];
            
            for (NSNumber *supportedLanguage in supportedLanguages)
                [supportedLangugageNames addObject:[LTOcrLanguageManager nameForLanguage:(LTOcrLanguage)supportedLanguage.integerValue]];
            
            const NSUInteger oldIndex = [_options.availableLanguages indexOfObject:_options.currentLanguage];
            
            _options.availableLanguages = supportedLangugageNames;
            
            if (![_options.availableLanguages containsObject:_options.currentLanguage]) {
                if (oldIndex >= _options.availableLanguages.count)
                    _options.currentLanguage = _options.availableLanguages.lastObject;
                else
                    _options.currentLanguage = _options.availableLanguages[oldIndex];
            }
            else
                _options.currentLanguage = _options.currentLanguage;
            
            [_options reloadData];
        });
    }
    else {
        UIProgressView * const tempProgressView = [cell viewWithTag:4];
        UIProgressView * const progressView = [[UIProgressView alloc] initWithFrame:tempProgressView.frame];
        progressView.tag = -127; // Avoid conflicting with tagged views
        _progressViews[indexPath] = progressView;
        
        dispatch_on_main_queue(NO, ^{
            [cell addSubview:progressView];
            
            ((UIButton *)sender).hidden = YES;
            progressView.hidden         = NO;
            progressView.progress       = 0.0;
        });
        
        [ResourceManager addResourceForTag:bundleTags[indexPath.row] progress:^(double percent, BOOL *cancel) {
            dispatch_on_main_queue(NO, ^{
                progressView.progress = percent;
            });
        } completionHandler:^(NSError *error) {
            dispatch_on_main_queue(NO, ^{
                [progressView removeFromSuperview];
                _progressViews[indexPath] = nil;
                [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
                
                AppDelegate * const delegate = (AppDelegate *)[UIApplication sharedApplication].delegate;
                [delegate.engine shutdown];
                [delegate.engine startup:nil workDirectory:nil startupParameters:[ResourceManager directoryForResources] error:nil]; // Since the engine was already started, this shouldn't fail.
                
                NSArray<NSNumber *> * const supportedLanguages = [delegate.engine.languageManager supportedLanguages];
                NSMutableArray<NSString *> * const supportedLangugageNames = [NSMutableArray arrayWithCapacity:supportedLanguages.count];
                
                for (NSNumber *supportedLanguage in supportedLanguages)
                    [supportedLangugageNames addObject:[LTOcrLanguageManager nameForLanguage:(LTOcrLanguage)supportedLanguage.integerValue]];
                
                _options.availableLanguages = supportedLangugageNames;
                _options.currentLanguage    = _options.currentLanguage; // Reset the selected row
                
                [_options reloadData];
            });
        }];
    }
}

@end