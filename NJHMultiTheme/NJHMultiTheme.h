//
//  NJHMultiTheme.h
//  NJHMultiTheme
//
//  Created by Nathan Hosselton on 4/18/15.
//  Copyright (c) 2015 Nathan Hosselton. All rights reserved.
//

#import <AppKit/AppKit.h>

@interface NJHMultiTheme : NSObject

+ (instancetype)sharedPlugin;

@property (nonatomic, strong, readonly) NSBundle* bundle;
@end