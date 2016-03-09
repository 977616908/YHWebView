# YHWebView
类似微信朋友圈网页，可以手势返回上一页，加载进度条

使用方法：
YHWebViewVC *vc = [YHWebViewVC new];
vc.url = [NSURL URLWithString:@"http://www.baidu.com"];
[self.navigationController pushViewController:vc animated:YES];
