//
//  YHWebViewVC.m
//  YHWebView
//
//  Created by zhouyehong on 16/03/09.
//  Copyright (c) 2016年 zhouyehong. All rights reserved.
//

#import "YHWebViewVC.h"
#import "YHWebShotManager.h"

#define WebViewShotMaxOffset 50
#define WebViewShotShadowMaxOpacity .8f
#define WebViewShotBgMaxOpacity .2f

#define WebViewLeftPanWidth 10

#define completeRPCURL @"webviewprogressproxy://complete"

static const float initialProgressValue = 0.05;
static const float beforeInteractiveMaxProgressValue = 0.5;
static const float afterInteractiveMaxProgressValue = 0.9;

@interface YHWebViewVC ()<UIGestureRecognizerDelegate>{
}

@property(nonatomic,strong) UIView *shotContentView;

@property(nonatomic,strong)YHWebShotManager *shotManager;

@property(nonatomic,strong)UIView *progressView;
@property(nonatomic,strong)UIView *progressBlockView;

@property(nonatomic,strong)NSURL *currentURL;

@property (assign, nonatomic) float progress;
@property (assign, nonatomic, getter = isInteractive) BOOL interactive;
@property (assign, nonatomic) NSUInteger loadingCount;
@property (assign, nonatomic) NSUInteger maxLoadCount;

@property(nonatomic,strong)UIScreenEdgePanGestureRecognizer *panGesture;
@end

@implementation YHWebViewVC

- (void)viewDidLoad {
    [super viewDidLoad];
    self.webView = [[UIWebView alloc] initWithFrame:self.view.bounds];
    _webView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
    _webView.backgroundColor = [UIColor whiteColor];
    _webView.opaque = NO;
    [self.view addSubview:_webView];
    _webView.delegate = self;
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:_url cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:60];
    [_webView loadRequest:urlRequest];
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 7) {
        
        self.shotManager = [YHWebShotManager new];
        
        self.shotContentView = [[UIView alloc] initWithFrame:self.view.bounds];
        _shotContentView.autoresizingMask = UIViewAutoresizingFlexibleHeight|UIViewAutoresizingFlexibleWidth;
        _shotContentView.userInteractionEnabled = NO;
        [self.view insertSubview:_shotContentView atIndex:0];
        
        [[_webView layer] setShadowOpacity:0.0];
        [[_webView layer] setShadowOffset:CGSizeMake(-1, 0)];
        [[_webView layer] setShadowRadius:5];
        [[_webView layer] setShadowPath:[[UIBezierPath bezierPathWithRect:_webView.bounds] CGPath]];
        
        UIView *panHelpView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, WebViewLeftPanWidth, self.view.bounds.size.height)];
        panHelpView.backgroundColor = [UIColor clearColor];
        [self.view addSubview:panHelpView];
        
        self.panGesture= [[UIScreenEdgePanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
        _panGesture.edges = UIRectEdgeLeft;
        _panGesture.enabled = NO;
        [self.view addGestureRecognizer:_panGesture];
        self.navigationController.interactivePopGestureRecognizer.delegate = self;
    }
    self.progressView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 2)];
    _progressView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    _progressView.userInteractionEnabled = NO;
    _progressView.backgroundColor = [UIColor clearColor];
    self.progressBlockView = [[UIView alloc] initWithFrame:CGRectZero];
    _progressBlockView.backgroundColor = self.progreeColor;
    _progressBlockView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [_progressView addSubview:_progressBlockView];
    [self.view addSubview:_progressView];
    
    [self steupNavigationItem:NO];
}

-(void)viewDidLayoutSubviews {
    if ([self respondsToSelector:@selector(topLayoutGuide)]) {
        UIEdgeInsets currentInsets = self.webView.scrollView.contentInset;
        self.webView.scrollView.contentInset = (UIEdgeInsets){
            .top = self.topLayoutGuide.length,
            .bottom = currentInsets.bottom,
            .left = currentInsets.left,
            .right = currentInsets.right
        };
        self.webView.scrollView.scrollIndicatorInsets = self.webView.scrollView.contentInset;
    }
}

-(void)steupNavigationItem:(BOOL)close{
    UIButton *backBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [backBtn setImage:[UIImage imageNamed:@"navigation_backbtn"] forState:UIControlStateNormal];
    [backBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    backBtn.titleLabel.font = [UIFont systemFontOfSize:14];
    [backBtn sizeToFit];
    [backBtn addTarget:self action:@selector(webBackAction) forControlEvents:UIControlEventTouchUpInside];
    NSMutableArray *leftItems = [NSMutableArray arrayWithObject:[[UIBarButtonItem alloc] initWithCustomView:backBtn]];
    if (close) {
        UIButton *closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [closeBtn setImage:[UIImage imageNamed:@"navigation_closebtn"] forState:UIControlStateNormal];
        [closeBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        closeBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        [closeBtn sizeToFit];
        [closeBtn addTarget:self action:@selector(webCloseAction) forControlEvents:UIControlEventTouchUpInside];
        [leftItems addObject:[[UIBarButtonItem alloc] initWithCustomView:closeBtn]];
    }
    
    self.navigationItem.leftBarButtonItems = leftItems;
}

-(void)webBackAction{
    if ([_webView canGoBack]) {
        [_shotManager removeLastShot];
        [[NSURLCache sharedURLCache] removeCachedResponseForRequest:_webView.request];
        [[NSURLCache sharedURLCache] removeAllCachedResponses];
        [_webView goBack];
        
        [self steupNavigationItem:YES];
    }else {
        [self.navigationController popViewControllerAnimated:YES];
    }
}

-(void)webCloseAction{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Progress handling

- (void)startProgress {
    if ([self progress] < initialProgressValue) {
        [self setProgress:initialProgressValue];
    }
}

- (void)incrementProgress {
    float progress = [self progress];
    float maxProgress = [self isInteractive] ? afterInteractiveMaxProgressValue : beforeInteractiveMaxProgressValue;
    float remainPercent = (float)_loadingCount / (float)_maxLoadCount;
    float increment = (maxProgress - progress) * remainPercent;
    
    progress += increment;
    progress = fmin(progress, maxProgress);
    
    [self setProgress:progress];
}

- (void)completeProgress {
    [self setProgress:1.0];
}

- (void)setProgress:(float)progress {
    if (progress > [self progress] || progress == 0) {
        _progress = progress;
//    NSLog(@"progress:%f",progress);
                _progressView.hidden = NO;
        [UIView animateWithDuration:.1f delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
            CGRect frame = _progressView.bounds;
            frame.size.width = frame.size.width * progress;
            _progressBlockView.frame = frame;
        } completion:^(BOOL falg){
            if (progress == 1) {
                CGRect frame = _progressView.bounds;
                frame.size.width = frame.size.width * 0;
                _progressBlockView.frame = frame;
                _progressView.hidden = YES;
            }
        }];
    }
}

- (void)resetProgress {
    self.maxLoadCount = self.loadingCount = 0;
    self.interactive = NO;
    
    [self setProgress:0.0];
}

-(void)panAction:(UIScreenEdgePanGestureRecognizer*)sender{
    switch (sender.state) {
        case UIGestureRecognizerStateBegan:{
            [_shotContentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
//            NSLog(@"_shotManager:%@",_shotManager);
            YHWebShot *shot = [_shotManager backShot];
            UIView *shotView = (UIView*)shot.shotView;
            if (shotView && shotView.frame.size.width == _shotContentView.frame.size.width) {
                [_shotContentView addSubview:(UIView*)shot.shotView];
                UIView *maskView = [[UIView alloc] initWithFrame:_shotContentView.bounds];
                [_shotContentView addSubview:maskView];
            }
            break;
        }
        case UIGestureRecognizerStateChanged:{
            CGPoint p = [sender translationInView:self.view];
            p.x = MIN(p.x, self.view.frame.size.width);
            p.x = MAX(p.x, 0);
             _webView.transform = CGAffineTransformMakeTranslation(p.x, 0);
            float change = p.x/(_webView.frame.size.width);
            _webView.layer.shadowOpacity = WebViewShotShadowMaxOpacity-change*0.6;
             UIView *maskView = [_shotContentView.subviews lastObject];
            maskView.backgroundColor = [UIColor colorWithWhite:0 alpha:WebViewShotBgMaxOpacity-change*0.8];
            _shotContentView.transform = CGAffineTransformMakeTranslation(-WebViewShotMaxOffset*(1-change), 0);
            break;
        }
        case UIGestureRecognizerStateEnded:{
            CGPoint velocity = [sender velocityInView:self.view];
//            NSLog(@"velocity:%f",velocity.x);
            CGFloat tx = _webView.transform.tx;
            if (tx > self.view.frame.size.width/3 || velocity.x > 400) {
                [UIView animateWithDuration:.2f delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                    _webView.transform = CGAffineTransformMakeTranslation(self.view.frame.size.width, 0);
                    _webView.layer.shadowOpacity = 0;
                    _shotContentView.transform = CGAffineTransformIdentity;
                } completion:^(BOOL flag){
                    [_shotManager removeLastShot];
                    [[NSURLCache sharedURLCache] removeCachedResponseForRequest:_webView.request];
                    [[NSURLCache sharedURLCache] removeAllCachedResponses];
                    [_webView goBack];
                    [_shotContentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
                    _webView.transform = CGAffineTransformIdentity;
                    [self steupNavigationItem:YES];
                    
                }];
            }else {
                [UIView animateWithDuration:.2f delay:0 options:UIViewAnimationOptionBeginFromCurrentState animations:^{
                    _webView.transform = CGAffineTransformIdentity;
                    _webView.layer.shadowOpacity = WebViewShotShadowMaxOpacity;
                    _shotContentView.transform = CGAffineTransformMakeTranslation(-WebViewShotMaxOffset, 0);;
                } completion:^(BOOL flag){
                    [_shotContentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
                }];
            }
            
            break;
        }
        case UIGestureRecognizerStateCancelled:{
            [_shotContentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
            _webView.transform = CGAffineTransformIdentity;
            break;
        }
        
        default:
            NSLog(@"%zd",sender.state);
            break;
    }
}

-(void)webViewDidStartLoad:(UIWebView *)webView{
    self.loadingCount++;
    self.maxLoadCount = fmax(self.maxLoadCount, self.loadingCount);
    
    [self startProgress];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView{
    
//    NSLog(@"\n************webViewDidFinishLoad:%@************",webView.request.URL.absoluteString);
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(.4f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        NSString *t = [webView stringByEvaluatingJavaScriptFromString:@"document.title"];
        self.title = t;
    });
    NSString *key = webView.request.URL.absoluteString;
    if (key != nil && ![key isEqualToString:@""] ) {
        [_shotManager addShot:key view:nil];
    }

    [self updateContentInset:self.interfaceOrientation];
    
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 7) {
        if (_webView.canGoBack) {
            self.navigationController.interactivePopGestureRecognizer.enabled = NO;
            _panGesture.enabled = YES;
        }else {
            self.navigationController.interactivePopGestureRecognizer.enabled = YES;
            _panGesture.enabled = NO;
        }
    }
    [self _webViewLoadComplete];
}


- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 7) {
        if (_webView.canGoBack) {
            self.navigationController.interactivePopGestureRecognizer.enabled = NO;
            _panGesture.enabled = YES;
        }else {
            self.navigationController.interactivePopGestureRecognizer.enabled = YES;
            _panGesture.enabled = NO;
        }
    }
    [self _webViewLoadComplete];
}

-(void)_webViewLoadComplete{
    self.loadingCount--;
    [self incrementProgress];
    
    NSString *readyState = [_webView stringByEvaluatingJavaScriptFromString:@"document.readyState"];
    
    BOOL isInteractive = [readyState isEqualToString:@"interactive"];
    if (isInteractive) {
        self.interactive = YES;
        NSString *waitForCompleteJS = [NSString stringWithFormat:@"window.addEventListener('load',function() { var iframe = document.createElement('iframe'); iframe.style.display = 'none'; iframe.src = '%@'; document.body.appendChild(iframe);  }, false);", completeRPCURL];
        [_webView stringByEvaluatingJavaScriptFromString:waitForCompleteJS];
    }
    
    BOOL isNotRedirect = self.currentURL && [self.currentURL isEqual:[[_webView request] mainDocumentURL]];
    BOOL complete = [readyState isEqualToString:@"complete"];
    if (complete && isNotRedirect) {
        [self completeProgress];
    }
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType{
    if ([[[request URL] absoluteString] isEqualToString:completeRPCURL]) {
        [self completeProgress];
        return NO;
    }
    
    BOOL isFragmentJump = NO;
    if ([[request URL] fragment]) {
        NSString *nonFragmentURL = [[[request URL] absoluteString] stringByReplacingOccurrencesOfString:[@"#" stringByAppendingString:[[request URL] fragment]] withString:@""];
        isFragmentJump = [nonFragmentURL isEqualToString:[[[webView request] URL] absoluteString]];
    }
    BOOL isTopLevelNavigation = [[request mainDocumentURL] isEqual:[request URL]];
    
    BOOL isHTTP = [[[request URL] scheme] isEqualToString:@"http"] || [[[request URL] scheme] isEqualToString:@"https"];
    if (!isFragmentJump && isHTTP && isTopLevelNavigation) {
        self.currentURL = [request URL];
        [self resetProgress];
        
        if ([[UIDevice currentDevice].systemVersion floatValue] >= 7) {
            YHWebShot *lastShot = [_shotManager lastShot];
            NSString *key = webView.request.URL.absoluteString;
            if ([lastShot.key isEqualToString:key] && lastShot.shotView == nil) {
                [_shotManager addShot:key view:[_webView snapshotViewAfterScreenUpdates:YES]];
            }
        }
    }
    
//    NSLog(@"\n url:%@\n to:%@\n self.currentURL:%@",webView.request.URL.host,request.URL.host,self.currentURL.host);
    return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 7) {
        [_shotContentView.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    }
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 7) {
        [[_webView layer] setShadowPath:[[UIBezierPath bezierPathWithRect:_webView.bounds] CGPath]];
    }
    [self updateContentInset:self.interfaceOrientation];
}

-(void)updateContentInset:(UIInterfaceOrientation)_intnterface{
    CGRect frame = _progressView.frame;
    frame.origin.y = _webView.scrollView.contentInset.top;
    _progressView.frame = frame;
    
    frame.origin = CGPointZero;
    frame.size.width = 0;
    _progressBlockView.frame = frame;
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    if ([[UIDevice currentDevice].systemVersion floatValue] >= 7) {
        self.navigationController.interactivePopGestureRecognizer.enabled = YES;
    }
}

-(UIColor*)progreeColor{
    return _progreeColor?_progreeColor:[UIColor colorWithRed:0.000 green:0.699 blue:0.000 alpha:1.000];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    [self.shotManager clear];
}

@end
