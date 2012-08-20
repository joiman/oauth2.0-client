//
//  ViewController.m
//  tbsdk
//
//  Created by self on 8/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ViewController.h"

//taobao
#define tbauth @"https://oauth.taobao.com/authorize"
#define tbtoken @"https://oauth.taobao.com/token"

//sina
#define sinaauth @"https://api.weibo.com/oauth2/authorize"
#define sinatoken @"https://api.weibo.com/oauth2/access_token"

//qqweibo 
#define qqweiboauth @"https://open.t.qq.com/cgi-bin/oauth2/authorize"
#define qqweibotoken @"https://open.t.qq.com/cgi-bin/oauth2/access_token"




#error replace with your own key/secret/callback and remove this line
#error callback url must be the same as you input when create app
//taobao
#define tbkey @""
#define tbsecret @""
#define tbcallback @""

//sina
#define sinakey @""
#define sinasecret @""
#define sinacallback @""

//qqweibo
#define qqweibokey @""
#define qqweibosecret @""
#define qqweibocallback @""


@implementation ViewController
@synthesize txtResult;
@synthesize segVC;

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [self setTxtResult:nil];
    [self setSegVC:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
}

- (IBAction)btnclick:(id)sender {
    clickedbtn = (UIButton *)sender;
    
    NSMutableDictionary *param = [NSMutableDictionary dictionary];
    LROAuth2Client *client = [[LROAuth2Client alloc] init];
    client.delegate = self;
    
    //taobao
    if (clickedbtn.tag < 2) {
        client.clientID = tbkey;
        client.clientSecret = tbsecret;
        client.userURL = [NSURL URLWithString:tbauth];
        if (clickedbtn.tag == 1) {
            client.tokenURL = [NSURL URLWithString:tbtoken];
            client.redirectURL = [NSURL URLWithString:tbcallback];
        }
        [param setObject:@"wap" forKey:@"view"];
    }
    
    //sina
    if (clickedbtn.tag == 2 || clickedbtn.tag == 3) {
        client.clientID = sinakey;
        client.clientSecret = sinasecret;
        client.userURL = [NSURL URLWithString:sinaauth];
        if (clickedbtn.tag == 3) {
            client.tokenURL = [NSURL URLWithString:sinatoken];
            client.redirectURL = [NSURL URLWithString:sinacallback];
        }
        
        [param setObject:@"mobile" forKey:@"display"];
        [param setValue:sinacallback forKey:@"redirect_uri"];//when response_type=token, redirect_uri can be empty. but sina still requires it.so add it manually.
    }
    
    //qqweibo
    if (clickedbtn.tag > 3) {
        client.clientID = qqweibokey;
        client.clientSecret = qqweibosecret;
        client.userURL = [NSURL URLWithString:qqweiboauth];
        if (clickedbtn.tag == 5) {
            client.tokenURL = [NSURL URLWithString:qqweibotoken];
            client.redirectURL = [NSURL URLWithString:qqweibocallback];
        }
        
        [param setObject:@"2" forKey:@"wap"];
        [param setValue:qqweibocallback forKey:@"redirect_uri"];//when response_type=token, redirect_uri can be empty. but qqweibo still requires it.so add it manually.
    }
    
    if (segVC.selectedSegmentIndex == 1) {
        [client authorizeUsingNavigation:self.navigationController param:param];
    } else {
        [client authorizeUsingPopupViewWithParam:param];
    }
}


- (void)oauthClientDidReceiveAccessToken:(LROAuth2Client *)client{
    txtResult.text = @"";
    txtResult.text = [NSString stringWithFormat:@"token:%@\n\nrefresh:%@\n\n", client.accessToken.accessToken, client.accessToken.refreshToken];
    
    NSString *userid, *username;
    //taobao
    if (clickedbtn.tag < 2) {
        userid = [[client.accessToken.allData objectForKey:@"taobao_user_id"] copy];
        username = [[client.accessToken.allData objectForKey:@"taobao_user_nick"] copy];
    }
    //sina
    if (clickedbtn.tag == 2 || clickedbtn.tag == 3) {
        userid = [[client.accessToken.allData objectForKey:@"uid"] copy];
        username = @"[not available]";
    }
    //qqweibo
    if (clickedbtn.tag > 3) {
        userid = [[client.accessToken.allData objectForKey:@"openid"] copy];
        username = @"[not available]";
    }
    txtResult.text = [NSString stringWithFormat:@"%@userid:%@\n\nusername:%@", txtResult.text, userid, username];
    
    if (segVC.selectedSegmentIndex == 1) {
        [client finishAuthUsingNavigation];
    } else {
        [client finishAuthUsingPopupView];
    }
}

- (void)oauthClientDidRefreshAccessToken:(LROAuth2Client *)client{
    //
}

@end
