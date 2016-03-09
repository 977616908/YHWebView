//
//  YHWebViewVC.h
//  YHWebView
//
//  Created by zhouyehong on 16/03/09.
//  Copyright (c) 2016年 zhouyehong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface YHWebViewVC : UIViewController<UIWebViewDelegate>

@property (strong, nonatomic) UIWebView *webView;
/**
 *  进度条颜色,默认绿色
 */
@property(nonatomic,strong)UIColor *progreeColor;

@property(nonatomic,strong)NSURL *url;

/**
 *  创建当前页面的Navigation Item， 子类可以覆盖，默认的实现是：如果没有返回上级，则只显示返回，否则会显示关闭
 *
 *  @param close 是否有关闭按钮
 */
-(void)steupNavigationItem:(BOOL)close;

/**
 *  返回上级事件
 */
-(void)webBackAction;

/**
 *  关闭网页事件
 */
-(void)webCloseAction;
@end

