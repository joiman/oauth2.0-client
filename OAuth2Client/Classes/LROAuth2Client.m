//
//  LROAuth2Client.m
//  LROAuth2Client
//
//  Created by Luke Redpath on 14/05/2010.
//  Copyright 2010 LJR Software Limited. All rights reserved.
//

#import "LROAuth2Client.h"
#import "NSURL+QueryInspector.h"
#import "LROAuth2AccessToken.h"
#import "LRURLRequestOperation.h"
#import "NSDictionary+QueryString.h"

#import "OAuth2DialogViewController.h"

#pragma mark -

static UIActivityIndicatorView *_indicator;

@interface LROAuth2Client (Private)
- (void)handleCompletionForAuthorizationRequestOperation:(LRURLRequestOperation *)operation;
- (NSURLRequest *)userAuthorizationRequestWithParameters:(NSDictionary *)additionalParameters;
- (void)verifyAuthorizationWithAccessCode:(NSString *)accessCode;
- (void)extractAccessCodeFromCallbackURL:(NSURL *)url;
@end

@implementation LROAuth2Client {
    NSOperationQueue *_networkQueue;
    BOOL isVerifying;
}

@synthesize clientID;
@synthesize clientSecret;
@synthesize redirectURL;
@synthesize cancelURL;
@synthesize userURL;
@synthesize tokenURL;
@synthesize delegate;
@synthesize accessToken;

-(id)init{
    if (self = [super init]){
        _networkQueue = [[NSOperationQueue alloc] init];
    }
    return self;
}

- (id)initWithClientID:(NSString *)_clientID 
                secret:(NSString *)_secret 
          authorizeURL:(NSString *)_urlau
              tokenURL:(NSString *)_urlto
           redirectURL:(NSString *)_urlre;
{
    if (self = [self init]) {
        self.clientID = _clientID;
        self.clientSecret = _secret;
        self.userURL = [NSURL URLWithString:_urlau];
        self.tokenURL = _urlto ? [NSURL URLWithString:_urlto] : nil;
        self.redirectURL = _urlre ? [NSURL URLWithString:_urlre] : nil;
    }
    return self;
}

- (void)dealloc;
{
    self.clientID = nil;
    self.clientSecret = nil;
    self.userURL = nil;
    self.tokenURL = nil;
    self.redirectURL = nil;
    self.cancelURL = nil;
    [accessToken release];
    
    [_networkQueue cancelAllOperations];
    [_networkQueue release];
}

#pragma mark -
#pragma mark Authorization

- (NSURLRequest *)userAuthorizationRequestWithParameters:(NSDictionary *)additionalParameters;
{
    NSDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:@"web_server" forKey:@"type"];
    [params setValue:clientID forKey:@"client_id"];
    if (self.redirectURL && self.tokenURL) {
        [params setValue:[redirectURL absoluteString] forKey:@"redirect_uri"];
        [params setValue:@"code" forKey:@"response_type"];
    } else {
        [params setValue:@"token" forKey:@"response_type"];
    }
    
    if (additionalParameters) {
        for (NSString *key in additionalParameters) {
            [params setValue:[additionalParameters valueForKey:key] forKey:key];
        }
    }  
    NSURL *fullURL = [NSURL URLWithString:[[self.userURL absoluteString] stringByAppendingFormat:@"?%@", [params stringWithFormEncodedComponents]]];
    NSMutableURLRequest *authRequest = [NSMutableURLRequest requestWithURL:fullURL];
    [authRequest setHTTPMethod:@"GET"];
    
    return [authRequest copy];
}

//called when response_type = code
- (void)verifyAuthorizationWithAccessCode:(NSString *)accessCode;
{
    @synchronized(self) {
        if (isVerifying) return; // don't allow more than one auth request
        
        isVerifying = YES;
        
        NSDictionary *params = [NSMutableDictionary dictionary];
        [params setValue:@"authorization_code" forKey:@"grant_type"];
        [params setValue:clientID forKey:@"client_id"];
        [params setValue:clientSecret forKey:@"client_secret"];
        [params setValue:[redirectURL absoluteString] forKey:@"redirect_uri"];
        [params setValue:accessCode forKey:@"code"];
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.tokenURL];
        [request setHTTPMethod:@"POST"];
        [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
        [request setHTTPBody:[[params stringWithFormEncodedComponents] dataUsingEncoding:NSUTF8StringEncoding]];
        
        LRURLRequestOperation *operation = [[LRURLRequestOperation alloc] initWithURLRequest:request];
        
        __unsafe_unretained id blockOperation = operation;
        
        [operation setCompletionBlock:^{
            [self handleCompletionForAuthorizationRequestOperation:blockOperation];
        }];
        
        [_networkQueue addOperation:operation];
    }
}

- (void)refreshAccessToken:(LROAuth2AccessToken *)_accessToken;
{
    accessToken = _accessToken;
    
    NSDictionary *params = [NSMutableDictionary dictionary];
    [params setValue:@"refresh_token" forKey:@"grant_type"];
    [params setValue:clientID forKey:@"client_id"];
    [params setValue:clientSecret forKey:@"client_secret"];
    //[params setValue:[redirectURL absoluteString] forKey:@"redirect_uri"];
    [params setValue:_accessToken.refreshToken forKey:@"refresh_token"];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.tokenURL];
    [request setHTTPMethod:@"POST"];
    [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
    [request setHTTPBody:[[params stringWithFormEncodedComponents] dataUsingEncoding:NSUTF8StringEncoding]];
    
    LRURLRequestOperation *operation = [[LRURLRequestOperation alloc] initWithURLRequest:request];
    
    __unsafe_unretained id blockOperation = operation;
    
    [operation setCompletionBlock:^{
        [self handleCompletionForAuthorizationRequestOperation:blockOperation];
    }];
    
    [_networkQueue addOperation:operation];
}

-(void)storeToken:(NSDictionary *)dic{
    if (accessToken == nil) {
        accessToken = [[LROAuth2AccessToken alloc] initWithAuthorizationResponse:dic];
        if ([self.delegate respondsToSelector:@selector(oauthClientDidReceiveAccessToken:)]) {
            //[self.delegate  oauthClientDidReceiveAccessToken:self];
            [(NSObject *)self.delegate performSelectorOnMainThread:@selector(oauthClientDidReceiveAccessToken:) withObject:self waitUntilDone:NO];
        } 
    } else {
        [accessToken refreshFromAuthorizationResponse:dic];
        if ([self.delegate respondsToSelector:@selector(oauthClientDidRefreshAccessToken:)]) {
            //[self.delegate oauthClientDidRefreshAccessToken:self];
            [(NSObject *)self.delegate performSelectorOnMainThread:@selector(oauthClientDidRefreshAccessToken:) withObject:self waitUntilDone:NO];
        }
    }
}

- (void)handleCompletionForAuthorizationRequestOperation:(LRURLRequestOperation *)operation
{
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)operation.URLResponse;
    
    if (response.statusCode == 200) {
        NSError *parserError;
        NSDictionary *authData = [NSJSONSerialization JSONObjectWithData:operation.responseData options:0 error:&parserError];
        
        if (authData == nil) {
            // try and decode the response body as a query string instead
            NSString *responseString = [[NSString alloc] initWithData:operation.responseData encoding:NSUTF8StringEncoding];
            authData = [NSDictionary dictionaryWithFormEncodedString:responseString];
        }
        if ([authData objectForKey:@"access_token"] == nil) {
            NSAssert(NO, @"Unhandled parsing failure");
        }
        [self storeToken:authData];
    }
    else {
        if (operation.connectionError) {
            NSLog(@"Connection error: %@", operation.connectionError);
        }
    }
}

@end

static UIViewController *_loginVC;

@implementation LROAuth2Client (NavigationIntegration)

- (void)authorizeUsingNavigation:(UINavigationController *)navi{
    [self authorizeUsingNavigation:navi param:nil];
}

- (void)authorizeUsingNavigation:(UINavigationController *)navi param:(NSDictionary *)dic {
    UIViewController *vc = [[UIViewController alloc] init];
    vc.title = @"授权登陆";
    UIWebView *webv = [[[UIWebView alloc] initWithFrame:vc.view.bounds] autorelease];
    [vc.view addSubview: webv];
    [navi pushViewController:vc animated:YES];
    [vc release];
    _loginVC = vc;
    [self authorizeUsingWebView:webv additionalParameters:dic];
}

-(void)finishAuthUsingNavigation{
    [_loginVC.navigationController popViewControllerAnimated:YES];
}

@end

@implementation LROAuth2Client (DialogIntegration)

- (void)authorizeUsingPopupViewWithParam:(NSDictionary *)dic{
    OAuth2DialogViewController *_popup = [[OAuth2DialogViewController alloc] init];
    [_popup view];
    [_popup.webView setDelegate:self];
    [_popup.webView loadRequest:[self userAuthorizationRequestWithParameters:dic]];
    [_popup show];
    _loginVC = _popup;
}

- (void)authorizeUsingPopupView{
    [self authorizeUsingPopupViewWithParam:nil];
}

-(void)finishAuthUsingPopupView{
    [(OAuth2DialogViewController *)_loginVC close];
}

@end

@implementation LROAuth2Client (UIWebViewIntegration)

- (void)authorizeUsingWebView:(UIWebView *)webView;
{
    [self authorizeUsingWebView:webView additionalParameters:nil];
}

- (void)authorizeUsingWebView:(UIWebView *)webView additionalParameters:(NSDictionary *)additionalParameters;
{
    [webView setDelegate:self];
    [webView loadRequest:[self userAuthorizationRequestWithParameters:additionalParameters]];
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType;
{  
    NSLog(@"URL:%@#", [request.URL absoluteString]);
    if (self.redirectURL && [[request.URL absoluteString] hasPrefix:[self.redirectURL absoluteString]]) {
        [self extractAccessCodeFromCallbackURL:request.URL];
        
        return NO;
    } else if (self.cancelURL && [[request.URL absoluteString] hasPrefix:[self.cancelURL absoluteString]]) {
        if ([self.delegate respondsToSelector:@selector(oauthClientDidCancel:)]) {
            [self.delegate oauthClientDidCancel:self];
        }
        
        return NO;
    } 
    else if ([[request.URL absoluteString] rangeOfString:@"access_token="].location != NSNotFound) {
        //response_type=token
        [self storeToken:[request.URL fragmentDictionary]];
        return NO;
    }
    
    if ([self.delegate respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
        return [self.delegate webView:webView shouldStartLoadWithRequest:request navigationType:navigationType];
    }
    
    return YES;
}

/**
 * custom URL schemes will typically cause a failure so we should handle those here
 */
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    [_indicator stopAnimating];
    
#if __IPHONE_OS_VERSION_MAX_ALLOWED <= __IPHONE_3_2
    NSString *failingURLString = [error.userInfo objectForKey:NSErrorFailingURLStringKey];
#else
    NSString *failingURLString = [error.userInfo objectForKey:NSURLErrorFailingURLStringErrorKey];
#endif
    
    if (self.redirectURL && [failingURLString hasPrefix:[self.redirectURL absoluteString]]) {
        [webView stopLoading];
        [self extractAccessCodeFromCallbackURL:[NSURL URLWithString:failingURLString]];
    } else if (self.cancelURL && [failingURLString hasPrefix:[self.cancelURL absoluteString]]) {
        [webView stopLoading];
        if ([self.delegate respondsToSelector:@selector(oauthClientDidCancel:)]) {
            [self.delegate oauthClientDidCancel:self];
        }
    } else if ([failingURLString rangeOfString:@"access_token="].location != NSNotFound) {
        //response_type=token
        [webView stopLoading];
        [self storeToken:[[NSURL URLWithString:failingURLString] fragmentDictionary] ];
    }
    
    if ([self.delegate respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [self.delegate webView:webView didFailLoadWithError:error];
    }
}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    if (!_indicator) {
        _indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    }
    [_indicator removeFromSuperview];
    [webView addSubview:_indicator];
    _indicator.center = CGPointMake(webView.frame.size.width/2.0, webView.frame.size.height/2.0);
    [_indicator startAnimating];
    if ([self.delegate respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [self.delegate webViewDidStartLoad:webView];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    [_indicator stopAnimating];
    if ([self.delegate respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [self.delegate webViewDidFinishLoad:webView];
    }
}

- (void)extractAccessCodeFromCallbackURL:(NSURL *)callbackURL;
{
    NSString *accessCode = [[callbackURL queryDictionary] valueForKey:@"code"];
    
    if ([self.delegate respondsToSelector:@selector(oauthClientDidReceiveAccessCode:)]) {
        [self.delegate oauthClientDidReceiveAccessCode:self];
    }
    [self verifyAuthorizationWithAccessCode:accessCode];
}

@end
