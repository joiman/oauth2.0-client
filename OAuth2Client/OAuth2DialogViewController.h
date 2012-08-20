//
//  ROBaseDialogViewController.h
//  RenrenSDKDemo
//
//  Created by xiawh on 11-8-30.
//  Copyright 2011年 renren-inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface OAuth2DialogViewController : UIViewController {
    UIView *_backgroundView;
    UIButton *_cancelButton;
    BOOL _showingKeyboard;
    UIDeviceOrientation _orientation;
    
	UIWebView *_webView;
    UIActivityIndicatorView *_indicatorView;
}

@property (nonatomic,retain)UIView *backgroundView;
@property (nonatomic,retain)UIButton *cancelButton;
@property (nonatomic,retain)UIWebView *webView;

- (void)show;
- (void)close;
- (void)updateSubviewOrientation;
- (void)sizeToFitOrientation:(BOOL)transform;
- (CGRect)fitOrientationFrame;

@end
