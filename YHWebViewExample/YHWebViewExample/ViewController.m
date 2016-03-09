//
//  ViewController.m
//  YHWebViewExample
//
//  Created by zhouyehong on 16/3/9.
//  Copyright © 2016年 zhouyehong. All rights reserved.
//

#import "ViewController.h"
#import "YHWebViewVC.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
}

-(IBAction)showWebAction:(id)sender{
    YHWebViewVC *vc = [YHWebViewVC new];
    vc.url = [NSURL URLWithString:@"http://www.baidu.com"];
    [self.navigationController pushViewController:vc animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
