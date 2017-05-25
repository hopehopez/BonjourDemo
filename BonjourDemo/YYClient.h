//
//  YYClient.h
//  BonjourDemo
//
//  Created by 张树青 on 2017/3/22.
//  Copyright © 2017年 zsq. All rights reserved.
//

#import <Foundation/Foundation.h>
@class YYClient;
@class Connection;
@protocol YYClientDelegate <NSObject>

- (void)client:(YYClient *)client receiveMessage:(NSString *)message;
- (void)client:(YYClient *)client buildConnect:(Connection *)connection;
- (void)client:(YYClient *)client connectionTerminated:(Connection *)connection;

@end

@interface YYClient : NSObject

@property (nonatomic, assign) id<YYClientDelegate> delegate;
+ (instancetype)shareInsatance;
- (void)strtWithServerName:(NSString *)serverName;
- (void)stop;
- (void)sendMessage:(NSString *)message;

@end
