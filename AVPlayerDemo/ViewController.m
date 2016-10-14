//
//  ViewController.m
//  AVPlayerDemo
//
//  Created by 高洋 on 2016/10/11.
//  Copyright © 2016年 gaoyang. All rights reserved.
//

#import "ViewController.h"
#import "GYVideoPlayerView.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *play1Btn;
@property (weak, nonatomic) IBOutlet UIButton *play2Btn;

@property (weak, nonatomic) GYVideoPlayerView *player;

@end

@implementation ViewController

- (void)viewDidLoad
{
    self.view.backgroundColor = [UIColor grayColor];
    self.play1Btn.hidden = YES;
    self.play2Btn.hidden = YES;
}
- (IBAction)playVideo1:(id)sender {
    // 视频资源
    self.player.videoTitleStr = @"视频1";
    self.player.videoURLStr = @"http://v1.mukewang.com/19954d8f-e2c2-4c0a-b8c1-a4c826b5ca8b/L.mp4";

    self.play1Btn.enabled = NO;
    self.play2Btn.enabled = YES;
}
- (IBAction)playVideo2:(id)sender {

    // 视频资源
    self.player.videoTitleStr = @"视频2";
    self.player.videoURLStr = @"http://svideo.spriteapp.com/video/2016/0915/8224a236-7ac8-11e6-ba32-90b11c479401cut_wpd.mp4";

    self.play1Btn.enabled = YES;
    self.play2Btn.enabled = NO;
}
- (IBAction)addPlayer:(id)sender {
    if (self.player == nil)
    {
        // 实例化
        GYVideoPlayerView *player = [GYVideoPlayerView playerView];
        // 设置父视图
        [self.view addSubview:player];
        self.player = player;
        player.frame = CGRectMake(10, 100, self.view.frame.size.width - 20, (self.view.frame.size.width - 20) / 16. * 9);

        self.play1Btn.hidden = NO;
        self.play2Btn.hidden = NO;
    }

}
- (IBAction)deletePlayer:(id)sender {
    [self.player removeFromSuperview];
    self.play1Btn.hidden = YES;
    self.play2Btn.hidden = YES;
}


@end
