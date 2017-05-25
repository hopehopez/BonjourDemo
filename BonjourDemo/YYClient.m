//
//  YYClient.m
//  BonjourDemo
//
//  Created by 张树青 on 2017/3/22.
//  Copyright © 2017年 zsq. All rights reserved.
//

#import "YYClient.h"
#import "ServerBrowser.h"
#import "ServerBrowserDelegate.h"
#import "Connection.h"

@interface YYClient() <ServerBrowserDelegate, ConnectionDelegate>
@property (nonatomic, strong) ServerBrowser* serverBrowser;
@property (nonatomic, strong) Connection *connection;
@property (nonatomic, strong) NSThread *thread;
@property (nonatomic, copy) NSString *serverName;
@property (nonatomic, assign) double lastTime;
@property (nonatomic, retain) NSTimer *timer;
@property (nonatomic, strong) NSPort *port;

@end

@implementation YYClient
+ (instancetype)shareInsatance{
    static YYClient *_client;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _client = [[YYClient alloc] init];
    });
    return _client;
}

- (void)strtWithServerName:(NSString *)serverName{
    
    [self stop];
    
    self.serverName = serverName;
    
    self.thread = [[NSThread alloc]initWithTarget:self selector:@selector(run) object:nil];
    [self.thread start];
    
    [self performSelector:@selector(action) onThread:self.thread withObject:nil waitUntilDone:NO ];
    
    
}
- (void)action{
    ServerBrowser *serverBrowser = [[ServerBrowser alloc] init];
    self.serverBrowser = serverBrowser;
    self.serverBrowser.delegate = self;
    self.serverBrowser.serverName = self.serverName;
    [self.serverBrowser start];
    
}
- (void)run{
    //只要往RunLoop中添加了  timer、source或者observer就会继续执行，一个Run Loop通常必须包含一个输入源或者定时器来监听事件，如果一个都没有，Run Loop启动后立即退出。
    
    @autoreleasepool {
        
        //1、添加一个input source
        NSPort *port = [NSPort port];
        self.port = port;
        [[NSRunLoop currentRunLoop] addPort:self.port forMode:NSRunLoopCommonModes];
        [[NSRunLoop currentRunLoop] run];
        //        //2、添加一个定时器
        //                    NSTimer *timer = [NSTimer timerWithTimeInterval:1/60.0 target:self selector:@selector(test) userInfo:nil repeats:YES];
        //                    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
        //                    [[NSRunLoop currentRunLoop] run];
    }
}
- (void)test{
    if ([self.thread isCancelled]) {
        [NSThread exit];
        self.thread=nil;
    }
}

- (void)startConnectionWithService:(NSNetService *)netService{
    [self stopHeart];
    
    [self closeConnection];
    
    Connection *conn = [[Connection alloc] initWithNetService:netService];
    self.connection = conn;
    if (self.connection == nil) {
        return;
    }
    
    self.connection.delegate = self;
    [self.connection connect];
    if (self.delegate && [self.delegate respondsToSelector:@selector(client:buildConnect:)]) {
        [self.delegate client:self buildConnect:self.connection];
    }
    [self startHeart];
}

- (void)closeConnection{
    if (self.connection) {
        [self.connection close];
        self.connection = nil;
    }
}

- (void)startHeart{
    __block typeof(self) weakself = self;
    self.lastTime = [[NSDate date] timeIntervalSince1970];
    NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:2.0 repeats:YES block:^(NSTimer * _Nonnull timer) {
        double currentTime = [[NSDate date] timeIntervalSince1970];
        double t = currentTime - weakself.lastTime;
        if (t>5) { //超过五秒没收到心跳消息, 重新查找服务
            [weakself strtWithServerName:weakself.serverName];
        }
        
        NSString *heartInfo = [weakself getHeartInfo];
        [self sendMessage:heartInfo];
    }];
    self.timer = timer;
}
- (NSString *)getHeartInfo{
    NSDictionary *header = @{
                             @"packet_type": @"S2T_3",       //报文类型
                             @"sender":@"18012345678",               //发送方push账号
                             @"receiver": @"1371234567",                 //接收方push账号
                             @"client_type": @"IOS",          //客户端类型：Android、IOS、Mac、Web、Pusher
                             @"desc":@"学生端心跳"                //报文描述
                             };
    NSDictionary *data = @{@"name":@"小明",
                           @"phone":@"18012345678",
                           @"oragn_staus": @(1)};
    NSDictionary *packet = @{@"header": header,
                            @"data": data};
    NSData *packetData = [NSJSONSerialization dataWithJSONObject:packet options:NSJSONWritingPrettyPrinted error:nil];
    NSString *str = [[NSString alloc] initWithData:packetData encoding:NSUTF8StringEncoding];
    return str;
}

- (void)stopHeart{
    if (self.timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}

- (void)stop{
    [self.serverBrowser stop];
    self.serverBrowser = nil;
    [self.thread cancel];
    [self performSelector:@selector(exitThread) onThread:self.thread withObject:nil waitUntilDone:NO];
    
    [self stopHeart];
    [self closeConnection];
}

- (void)sendMessage:(NSString *)message{
    if (self.connection) {
        [self.connection sendNetworkPacket:message];
    }
}


- (void)exitThread{
    [[NSRunLoop currentRunLoop] removePort:self.port forMode:NSRunLoopCommonModes];
    [NSThread exit];
    self.thread = nil;
}

#pragma mark - ServerBrowser delegate
- (void)updateServerList {
    //[serverList reloadData];
}
- (void)findWantServer:(NSNetService *)netService{
    //找到服务, 停止扫描
    NSLog(@"发现server: %@", netService.name);
    [self.serverBrowser stop];
    
    [self startConnectionWithService:netService];
    
}


#pragma mark - connection delegate
- (void)connectionAttemptFailed:(Connection*)connection {
    NSLog(@"连接服务失败, 重新开始扫描");
    [self strtWithServerName:self.serverName];
    if (self.delegate && [self.delegate respondsToSelector:@selector(client:connectionTerminated:)]) {
        [self.delegate client:self connectionTerminated:connection];
    }
}
- (void)connectionTerminated:(Connection*)connection {
    NSLog(@"连接中断, 重新开始扫描服务");
    [self strtWithServerName:self.serverName];
    if (self.delegate && [self.delegate respondsToSelector:@selector(client:connectionTerminated:)]) {
        [self.delegate client:self connectionTerminated:connection];
    }
}
- (void)receivedNetworkPacket:(NSString *)packet viaConnection:(Connection*)connection {
    if (![self.thread isCancelled]) {
        if (packet && [packet isKindOfClass:[NSString class]] && ((NSString *)packet).length>0) {
            NSLog(@"bonjour:%@", packet);
            [self.connection sendNetworkPacket:@""];
            if (self.delegate && [self.delegate respondsToSelector:@selector(client:receiveMessage:)]) {
                [self.delegate client:self receiveMessage:packet];
            }
        } else  {
            self.lastTime = [[NSDate date] timeIntervalSince1970];
        }
    } else {
        [[NSRunLoop currentRunLoop] removePort:self.port forMode:NSRunLoopCommonModes];
        [NSThread exit];
        self.thread = nil;
    }
}

@end
