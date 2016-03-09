//
//  YHWebShotManager.h
//  YHWebView
//
//  Created by zhouyehong on 16/03/09.
//  Copyright (c) 2016年 zhouyehong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "YHWebShot.h"

@interface YHWebShotManager : NSObject

-(void)addShot:(NSString*)key view:(NSObject*)view;
-(void)addWebShot:(YHWebShot*)webShot;

-(YHWebShot*)backShot;
-(YHWebShot*)lastShot;
-(void)removeLastShot;

-(void)clear;
@end
