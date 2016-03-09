//
//  YHWebShotManager.m
//  YHWebView
//
//  Created by zhouyehong on 16/03/09.
//  Copyright (c) 2016年 zhouyehong. All rights reserved.
//

#import "YHWebShotManager.h"

#define YHWeb_MAX_SHOT_CACHE 6

@interface YHWebShotManager ()
@property(nonatomic,strong)NSMutableArray *cache;
@end

@implementation YHWebShotManager

-(instancetype)init{
    if (self = [super init]) {
        self.cache = [NSMutableArray array];
    }
    return self;
}

-(void)addShot:(NSString*)key view:(NSObject*)view{
    YHWebShot *shot = [YHWebShot new];
    shot.key = key;
    shot.shotView = view;
    [self addWebShot:shot];
}
-(void)addWebShot:(YHWebShot*)webShot{
    __block NSUInteger index = NSNotFound;
    [_cache enumerateObjectsUsingBlock:^(YHWebShot *obj, NSUInteger idx, BOOL *stop) {
        if ([obj.key isEqualToString:webShot.key]) {
            index = idx;
            *stop = YES;
        }
    }];
    if (index != NSNotFound) {
        [_cache replaceObjectAtIndex:index withObject:webShot];
    }else {
        [_cache addObject:webShot];
        if (_cache.count > YHWeb_MAX_SHOT_CACHE) {
            [_cache removeObjectAtIndex:0];
        }
    }
    NSLog(@"_cache count:%zd",_cache.count);
}

-(YHWebShot*)backShot{
    NSInteger index = _cache.count-2;
    if (index >= 0) {
        return _cache[index];
    }
    return nil;
}

-(YHWebShot*)lastShot{
    return [_cache lastObject];
}

-(void)removeLastShot{
    [_cache removeLastObject];
}

-(void)clear{
    [_cache removeAllObjects];
}

-(NSString*)description{
    return [NSString stringWithFormat:@"%@",_cache];
}
@end
