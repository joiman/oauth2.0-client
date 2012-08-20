//
//  NSURL+QueryInspector.h
//  LROAuth2Client
//
//  Created by Luke Redpath on 14/05/2010.
//  Copyright 2010 LJR Software Limited. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface NSURL (QueryInspector)

- (NSDictionary *)queryDictionary;
- (NSDictionary *)fragmentDictionary;

@end
