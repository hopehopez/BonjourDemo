//
//  ViewController.m
//  BonjourDemo
//
//  Created by 张树青 on 2017/3/22.
//  Copyright © 2017年 zsq. All rights reserved.
//

#import "ViewController.h"
#import "YYServer.h"
#import "YYClient.h"
@interface ViewController ()
@property (weak, nonatomic) IBOutlet UITextField *textField;

@property (nonatomic, strong) dispatch_source_t timer;
@property (weak, nonatomic) IBOutlet UITextField *phoneText;
@property (weak, nonatomic) IBOutlet UITextField *messageText;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

    


- (IBAction)sendClick:(UIButton *)sender {
    if (self.textField.text.length>0) {
        [[YYServer shareInsatance] sendMessage: [@([[NSDate date] timeIntervalSince1970]) stringValue]];
    }
    __block int count = 0;

    self.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
//
    dispatch_time_t start = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.0 * NSEC_PER_SEC));
    uint64_t interval = (uint64_t)(1.0 * NSEC_PER_SEC);
    dispatch_source_set_timer(self.timer, start, interval, 0);
    
    // 设置回调
    dispatch_source_set_event_handler(self.timer, ^{
        count++;
        if (self.textField.text.length>0) {
            NSString *str = [@([[NSDate date] timeIntervalSince1970]) stringValue];
            [[YYServer shareInsatance] sendMessage: self.textField.text];
//            [self.server sendMessage:self.textField.text];
        }

        if (count == 10000) {
            // 取消定时器
            dispatch_cancel(self.timer);
            self.timer = nil;
        }
    });
    
    // 启动定时器
   // dispatch_resume(self.timer);
    
}
- (IBAction)stopClick:(id)sender {
    
    [[YYServer shareInsatance] stopServer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)startClick:(id)sender {
    
    [[YYServer shareInsatance] startServerWithName:@"teacher123"];
    

}

- (IBAction)singleSend:(id)sender {
    
    if (self.phoneText.text.length>0 && self.messageText.text.length>0) {
        [[YYServer shareInsatance] sendMessage:self.messageText.text toPhone:self.phoneText.text];
    }
    
}

@end
