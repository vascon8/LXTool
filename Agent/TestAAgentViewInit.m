//
//  TestAAgentViewInit.m
//  TestWa
//
//  Created by xin liu on 2016/11/12.
//  Copyright © 2016年 ___xin.liu___. All rights reserved.
//

#import "TestAAgentViewInit.h"

@implementation TestAAgentViewInit
+ (void)initAgentView
{
    NSString *filePath = [[[NSBundle mainBundle]resourcePath] stringByAppendingPathComponent:@"node_modules/testwa/node_modules/appium-xcuitest-driver/WebDriverAgent/TestWaAgent/ViewController.m"];
    
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:filePath]) {
        [fm removeItemAtPath:filePath error:nil];
    }
    
    NSString *str = @"//\n//  ViewController.m\n//  TestWaAgent\n//\n//  Created by Xin Liu on 16/11/20.\n//  Copyright © 2016年 Xin Liu All rights reserved.\n//\n\n#import \"ViewController.h\"\n\n@interface ViewController ()<UIWebViewDelegate>\n@property (weak,nonatomic) UIWebView *webView;\n@property (weak,nonatomic) UIActivityIndicatorView *indicator;\n\n@end\n\n@implementation ViewController\n\n- (void)viewDidLoad\n{\n    [super viewDidLoad];\n    UIWebView *webView = [[UIWebView alloc]initWithFrame:self.view.bounds];\n    [self.view addSubview:webView];\n    [webView setAutoresizingMask:UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight];\n    self.webView = webView;\n    webView.delegate = self;\n    \n    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];\n    [self.view addSubview:indicator];\n    self.indicator = indicator;\n    indicator.color = [UIColor blueColor];\n    indicator.hidesWhenStopped = YES;\n    indicator.center = self.webView.center;\n    \n    [self loadWeibo];\n}\n\n- (void)loadWeibo\n{\n    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:@\"http://www.testwa.com\"]];\n    [self.webView loadRequest:request];\n}\n\n- (void)webViewDidStartLoad:(UIWebView *)webView\n{\n    [self.indicator startAnimating];\n}\n- (void)webViewDidFinishLoad:(UIWebView *)webView\n{\n    [self.indicator stopAnimating];\n}\n- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error\n{\n    NSLog(@\"%@\",error);\n    [self.indicator stopAnimating];\n}\n\n@end\n";
    
    [str writeToFile:filePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}
@end
