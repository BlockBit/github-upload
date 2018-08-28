//
//  newyViewController.m
//  OcrDemo
//
//  Created by Shajahan Kakkattil on 10/7/17.
//  Copyright © 2017 LEAD Technologies, Inc. All rights reserved.
//

#import "newyViewController.h"

@interface newyViewController ()
@property (weak, nonatomic) IBOutlet UITextView *load_Text;

@end

@implementation newyViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    NSString *savedValue = [[NSUserDefaults standardUserDefaults]
                            stringForKey:@"OCR_READ"];
    
    _load_Text.text = savedValue;
    
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
