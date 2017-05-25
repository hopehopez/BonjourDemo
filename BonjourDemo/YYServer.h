//
//  YYServer.h
//  BonjourDemo
//
//  Created by 张树青 on 2017/3/22.
//  Copyright © 2017年 zsq. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol YYServerDelegate <NSObject>

- (void)receiveNewMessage:(NSString *)message;

@end

@interface YYServer : NSObject

@property (nonatomic, assign) id<YYServerDelegate> delegate;

+ (instancetype)shareInsatance;

- (void)startServerWithName:(NSString *)name;
- (void)stopServer;

//向所有学生发送消息
- (void)sendMessage:(NSString *)message;
//根据指定手机号发送消息
- (void)sendMessage:(NSString *)message toPhone:(NSString *)phoneNumber;


@end
