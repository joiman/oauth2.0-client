//
//  LROAuth2Client.h
//  LROAuth2Client
//
//  Created by Luke Redpath on 14/05/2010.
//  Copyright 2010 LJR Software Limited. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "LROAuth2ClientDelegate.h"
#import "LROAuth2AccessToken.h"

@interface LROAuth2Client : NSObject {
    NSString *clientID;
    NSString *clientSecret;
    NSURL *redirectURL;
    NSURL *cancelURL;
    NSURL *userURL;//authorize
    NSURL *tokenURL;//token
    id<LROAuth2ClientDelegate> __unsafe_unretained delegate;
    
    LROAuth2AccessToken *accessToken;//result
}

@property (nonatomic, copy) NSString *clientID;
@property (nonatomic, copy) NSString *clientSecret;
@property (nonatomic, copy) NSURL *redirectURL;
@property (nonatomic, copy) NSURL *cancelURL;
@property (nonatomic, copy) NSURL *userURL;
@property (nonatomic, copy) NSURL *tokenURL;
@property (nonatomic, unsafe_unretained) id<LROAuth2ClientDelegate> delegate;
@property (nonatomic, readonly) LROAuth2AccessToken *accessToken;

- (id)initWithClientID:(NSString *)_clientID 
                secret:(NSString *)_secret 
          authorizeURL:(NSString *)_urlau
              tokenURL:(NSString *)_urlto
           redirectURL:(NSString *)_urlre;//if redirectURL == nil || tokenURL == nil:responde_type=token, else responde_type=code

- (void)refreshAccessToken:(LROAuth2AccessToken *)_accessToken;

@end

@interface LROAuth2Client (UIWebViewIntegration) <UIWebViewDelegate>//using webview
- (void)authorizeUsingWebView:(UIWebView *)webView;
- (void)authorizeUsingWebView:(UIWebView *)webView additionalParameters:(NSDictionary *)additionalParameters;
@end

@interface LROAuth2Client (DialogIntegration)//popup controller
- (void)authorizeUsingPopupView;
- (void)authorizeUsingPopupViewWithParam:(NSDictionary *)dic;
- (void)finishAuthUsingPopupView;
@end

@interface LROAuth2Client (NavigationIntegration)//navigation controller
- (void)authorizeUsingNavigation:(UINavigationController *)navi;
- (void)authorizeUsingNavigation:(UINavigationController *)navi param:(NSDictionary *)dic;
- (void)finishAuthUsingNavigation;
@end


