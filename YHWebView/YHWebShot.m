//
//  YHWebShot.m
//  YHWebView
//
//  Created by zhouyehong on 16/03/09.
//  Copyright (c) 2016年 zhouyehong. All rights reserved.
//

#import "YHWebShot.h"

@implementation YHWebShot

-(NSString*)description{
    return [NSString stringWithFormat:@"key:%@ view:%@",_key,_shotView];
}
@end
