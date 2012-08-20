//
//  ViewController.h
//  tbsdk
//
//  Created by self on 8/17/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LROAuth2Client.h"
#import "LROAuth2AccessToken.h"

@interface ViewController : UIViewController<LROAuth2ClientDelegate>{
    UIButton *clickedbtn;
}


- (IBAction)btnclick:(id)sender;
@property (retain, nonatomic) IBOutlet UITextView *txtResult;
@property (retain, nonatomic) IBOutlet UISegmentedControl *segVC;

@end
