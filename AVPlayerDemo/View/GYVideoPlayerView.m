//
//  GYVideoPlayerView.m
//  EduNews
//
//  Created by 高洋 on 2016/10/11.
//  Copyright © 2016年 gaoyang. All rights reserved.
//

#import <AVFoundation/AVFoundation.h>
#import "MBProgressHUD.h"
#import "GYVideoPlayerView.h"

#define weakify(x) typeof(x) __weak weak##x = x

#pragma mark -
#pragma mark - 全屏控制器类
@interface GYFullScreenController : UIViewController @end

@implementation GYFullScreenController
- (BOOL)shouldAutorotate
{
    return YES;
}
/**
 屏幕支持的方向

 @return 支持
 */
- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return UIInterfaceOrientationMaskLandscapeRight;
}

@end

#pragma mark -
#pragma mark - 播放器类
@interface GYVideoPlayerView ()

/** 播放器*/
@property (nonatomic, strong) AVPlayer *player;
/** 播放layer*/
@property (nonatomic, weak) AVPlayerLayer *playLayer;
/** 播放项目*/
@property (nonatomic, weak) AVPlayerItem *playItem;
/** 播放项目时长*/
@property (nonatomic, assign) CMTime duration;
/** 播放进度监听者*/
@property (nonatomic, strong) id playProgressObserver;

/** 播放背景*/
@property (nonatomic, weak) UIImageView *videioBgImgView;

/** 顶部工具条*/
@property (nonatomic, weak) UIView *playerTopToolView;
/** 时间label*/
@property (nonatomic, weak) UILabel *titleLabel;

/** 底部工具条*/
@property (nonatomic, weak) UIView *playerBottomToolView;
/** 播放暂停按钮*/
@property (nonatomic, weak) UIButton *playOrPauseBtn;
/** 全屏按钮*/
@property (nonatomic, weak) UIButton *fullScreenBtn;
/** slider*/
@property (nonatomic, weak) UISlider *slider;
/** slider*/
@property (nonatomic, weak) UIProgressView *progresser;
/** 总时间label*/
@property (nonatomic, weak) UILabel *totalTimeLabel;
/** 播放时间label*/
@property (nonatomic, weak) UILabel *currentTimeLabel;

/** 该播放控件小屏frame*/
@property (nonatomic, assign) CGRect shrinkScreenFrame;
/** 该播放控件的父控件*/
@property (nonatomic, weak) UIView *playerSuperView;

@end

@implementation GYVideoPlayerView

+ (instancetype)playerView
{
    return [[self alloc] init];
}

- (void)dealloc
{
    [self removePlayerObserver];
    printf("GYVideoPlayerView 销毁");
}

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame])
    {
        // 播放背景
        UIImageView *bg = [[UIImageView alloc] init];
        self.videioBgImgView = bg;
        [self addSubview:bg];
        bg.backgroundColor = [UIColor clearColor];
        bg.userInteractionEnabled = YES;
        // 添加单击手势
        UITapGestureRecognizer *gr = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(onPlayerBgTapped)];
        [bg addGestureRecognizer:gr];

        // 顶部工具条
        UIView *topToolView = [self componentBoxView];
        [self addSubview:topToolView];
        self.playerTopToolView = topToolView;

        // 视频标题
        UILabel *tl = [self labelWithFontSize:12];
        [topToolView addSubview:tl];
        self.titleLabel = tl;
        tl.textAlignment = NSTextAlignmentCenter;

        //底部工具条
        UIView *toolView = [self componentBoxView];
        [self addSubview:toolView];
        self.playerBottomToolView = toolView;

        // 播放暂停按钮
        UIButton *playBtn = [self buttonWithNormalPic:@"play" selectedPic:@"pause" targer:self action:@selector(onPlayOrPauseBtnClick)];
        playBtn.enabled = NO;
        [toolView addSubview:playBtn];
        self.playOrPauseBtn = playBtn;

        // 全屏按钮
        UIButton *fullBtn = [self buttonWithNormalPic:@"fullscreen"                                                                         selectedPic:@"shrinkscreen" targer:self action:@selector(onFullScreenBtnClick)];
        [toolView addSubview:fullBtn];
        self.fullScreenBtn = fullBtn;

        // 播放进度条
        UISlider *slider = [[UISlider alloc] init];
        self.slider = slider = slider;
        // 默认值设置为0
        slider.value = 0;
        [toolView addSubview:slider];
        [slider addTarget:self action:@selector(onSliderTouchDown:) forControlEvents:UIControlEventTouchDown];
        [slider addTarget:self action:@selector(onSliderTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
        [slider addTarget:self action:@selector(onSliderValueChange:) forControlEvents:UIControlEventValueChanged];
        [slider setThumbImage:[UIImage imageNamed:@"point"] forState:UIControlStateNormal];
        UIProgressView *pro = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        [slider addSubview:pro];
        self.progresser = pro;
        // 默认值设置为0
        pro.progress = 0;

        // 总时间label
        UILabel *totalLabel = [self labelWithFontSize:10];
        totalLabel.text = @"/00:00:00";
        totalLabel.textAlignment = NSTextAlignmentLeft;
        [toolView addSubview:totalLabel];
        self.totalTimeLabel = totalLabel;

        // 播放过的时间label
        UILabel *curLabel = [self labelWithFontSize:10];
        curLabel.text = @"00:00:00";
        [toolView addSubview:curLabel];
        curLabel.textAlignment = NSTextAlignmentRight;
        self.currentTimeLabel = curLabel;
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    CGSize selfSize = self.frame.size;
    CGSize btnSize = (CGSize){20, 30};
    CGSize labelSize = (CGSize){50, 35};
    CGFloat toolViewH = 35;
    CGFloat offsetX = 10;
    CGFloat sliderH = 20;
    // 背景
    _videioBgImgView.frame = self.bounds;
    _playLayer.frame = _videioBgImgView.bounds;
    // 顶部工具条
    _playerTopToolView.frame = CGRectMake(0, 0, selfSize.width, toolViewH);
    _titleLabel.frame = _playerTopToolView.bounds;
    // 底部工具条
    _playerBottomToolView.frame = CGRectMake(0, selfSize.height - toolViewH, selfSize.width, toolViewH);
    // 播放暂停按钮
    _playOrPauseBtn.frame = CGRectMake(offsetX, toolViewH / 2 - btnSize.height / 2, btnSize.width, btnSize.height);
    // 全屏按钮
    _fullScreenBtn.frame = CGRectMake(selfSize.width - offsetX - btnSize.width, toolViewH / 2 - btnSize.height / 2, btnSize.width, btnSize.height);
    // 总时间label
    _totalTimeLabel.frame = CGRectMake(selfSize.width - offsetX * 2 - btnSize.width - labelSize.width, toolViewH / 2 - labelSize.height / 2, labelSize.width, labelSize.height);
    // 播放过的时间label
    _currentTimeLabel.frame = CGRectMake(selfSize.width - offsetX * 2 - btnSize.width - labelSize.width * 2, toolViewH / 2 - labelSize.height / 2, labelSize.width, labelSize.height);
    _slider.frame = CGRectMake(btnSize.width + offsetX * 2, toolViewH / 2 - sliderH / 2, selfSize.width - btnSize.width * 2 - labelSize.width * 2 - offsetX * 4, sliderH);

    CGSize proSize = (CGSize){_slider.frame.size.width, 2};
    _progresser.frame = CGRectMake(0, _slider.frame.size.height / 2 - proSize.height / 2, proSize.width, proSize.height);

}
#pragma mark - 视图辅助方法

/**
 获取一个半透明背景的View
 */
- (UIView *)componentBoxView
{
    UIView *view = [[UIView alloc] init];
    // 深黑色，半透明
    view.backgroundColor = [UIColor colorWithRed:56/255.0 green:56/255.0 blue:55/255.0 alpha:.3];

    return view;
}

/**
 获取带有初始化设置的button
 */
- (UIButton *)buttonWithNormalPic:(NSString *)norPic
                      selectedPic:(NSString *)selectedPic
                           targer:(id)target action:(SEL)action
{
    UIButton *btn = [UIButton buttonWithType:UIButtonTypeCustom];
    [btn setImage:[UIImage imageNamed:norPic] forState:UIControlStateNormal];
    [btn setImage:[UIImage imageNamed:selectedPic] forState:UIControlStateSelected];
    [btn addTarget:target action:action forControlEvents:UIControlEventTouchUpInside];

    return btn;
}

- (UILabel *)labelWithFontSize:(CGFloat)size
{
    UILabel *label = [[UILabel alloc] init];
    label.font = [UIFont systemFontOfSize:size];
    label.backgroundColor = [UIColor clearColor];
    label.textColor = [UIColor whiteColor];

    return label;
}

#pragma mark - play

- (void)play
{
    [self.player play];
}

- (void)pause
{
    [self.player pause];
}

- (void)readyToPlay
{
    // 记录时长
    self.duration = self.playItem.duration;
    // 播放按钮可以点击
    self.playOrPauseBtn.enabled = YES;
    // 进度条的最大值
    [self readySlider];
    // 设置总时间label
    CGFloat totalTime = self.duration.value / self.duration.timescale; // 转换为秒
    self.totalTimeLabel.text = [NSString stringWithFormat:@"/%@", [self convertTime:totalTime]];
    // 监听播放时间进度, 在播放时间改变是，改变进度条和时间label
    weakify(self);
    self.playProgressObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMake(1, 1) queue:NULL usingBlock:^(CMTime time) {
        CGFloat currentSecond = weakself.playItem.currentTime.value / weakself.playItem.currentTime.timescale;
        NSString *secStr = [weakself convertTime:currentSecond];

        weakself.currentTimeLabel.text = secStr;
        [weakself.slider setValue:currentSecond animated:YES];
    }];

    [MBProgressHUD hideHUDForView:self animated:YES];
}

- (void)finishPlay
{
    [self.player seekToTime:CMTimeMake(0, 1)];
    [UIView animateWithDuration:.25 animations:^{
        [self resetToolViewState];
    }];
    self.playerTopToolView.hidden = NO;
    self.playerBottomToolView.hidden = NO;
}

#pragma mark - setter

- (void)setVideoURLStr:(NSString *)videoURLStr
{
    if (![MBProgressHUD HUDForView:self])
    {
        [MBProgressHUD showHUDAddedTo:self animated:YES];
    }

    _videoURLStr = videoURLStr;
    // 播放路径
    NSURL *url = [NSURL URLWithString:videoURLStr];

    // 播放项目
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:url];

    // 播放器
    if (_player == nil)
    {
        AVPlayer *player = [AVPlayer playerWithPlayerItem:playerItem];
        _player = player;
    }
    if (_playLayer == nil)
    {
        AVPlayerLayer *layer = [AVPlayerLayer playerLayerWithPlayer:_player];
        _playLayer = layer;
        _playLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
        [self.videioBgImgView.layer addSublayer:layer];
    }
    // 替换之前的播放选项
    if (_playItem) // 之前有过播放项目，完成其播放
    {
        [self removePlayerObserver];
        [self finishPlay];
        // 说明正在播放
        if (self.player.rate == 1)
        {
            // 播放状态
            self.playOrPauseBtn.selected = YES;
        }
    }

    [_player replaceCurrentItemWithPlayerItem:playerItem];
    self.playItem = playerItem;
    // 使用KVO监听当前playerItem的相关属性，完成进度同步
    [self addPlayerObserver];
}

- (void)setVideoTitleStr:(NSString *)videoTitleStr
{
    if (videoTitleStr == nil || videoTitleStr.length == 0)
    {
        videoTitleStr = @"该视频没有标题...";
    }
    _videoTitleStr = videoTitleStr;
    self.titleLabel.text = videoTitleStr;
}
#pragma mark - Observer

/**
 KVO的监听回调方法
 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context
{
    // 改变当前播放项目的状态
    if ([keyPath isEqualToString:@"status"])
    {
        if ([self.playItem status] == AVPlayerStatusReadyToPlay)
        {
            [self readyToPlay];
        }
        else if ([self.playItem status] == AVPlayerStatusFailed)
        {
            printf("播放失败！");
            [MBProgressHUD hideHUDForView:self animated:YES];
        }
    }
    // 当前播放项目的缓存进度
    else if ([keyPath isEqualToString:@"loadedTimeRanges"])
    {
        NSTimeInterval timeInterval = [self availableDuration];
        CGFloat totalInterval = CMTimeGetSeconds(self.duration);
        [self.progresser setProgress:timeInterval / totalInterval animated:YES];
    }
}

- (void)addPlayerObserver
{
    // 监听当前播放项目的状态，包括  可以播放，或者播放失败
    [self.playItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    // 监听缓存进度
    [self.playItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    // 添加播放完成后的监听
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishPlay) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playItem];
}

- (void)removePlayerObserver
{
    [self.playItem removeObserver:self forKeyPath:@"status"];
    [self.playItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.player removeTimeObserver:self.playProgressObserver];
    self.playProgressObserver = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.playItem];
}

#pragma mark - 事件响应

- (void)onPlayerBgTapped
{
    [self switchToolViewState];
}

- (void)onPlayOrPauseBtnClick
{
    self.playOrPauseBtn.selected = !self.playOrPauseBtn.selected;
    if (!self.playOrPauseBtn.selected)
    {
        [self pause];
    }
    else
    {
        [self play];
    }
}
- (void)onFullScreenBtnClick
{
    [self switchToolViewState];
    // 全屏按钮状态
    self.fullScreenBtn.selected = !self.fullScreenBtn.selected;
    UIViewController *currentController = [self currentViewController];
    if (self.fullScreenBtn.selected)
    {
        GYFullScreenController *fullVC = [[GYFullScreenController alloc] init];
        // 记录小屏的frame
        self.shrinkScreenFrame = self.frame;
        // 记录小屏的父控件
        self.playerSuperView = self.superview;
        [currentController presentViewController:fullVC animated:NO completion:^{
            // 播放视图添加到全屏控制器视图
            [fullVC.view addSubview:self];
            [UIView animateWithDuration:.25 delay:0. options:UIViewAnimationOptionLayoutSubviews animations:^{
                self.center = fullVC.view.center;
                self.frame = fullVC.view.bounds;
            } completion:nil];
        }];
    }
    else
    {
        [currentController dismissViewControllerAnimated:NO completion:^{
            [self.playerSuperView addSubview:self];
            self.frame = self.shrinkScreenFrame;
        }];
    }
}

/**
 slider按下
 */
- (void)onSliderTouchDown:(UISlider *)slider
{
    [self pause];
}
/**
  slider抬起
  */
- (void)onSliderTouchUpInside:(UISlider *)slider
{
    [self play];
}
/**
  slider值改变
  */
- (void)onSliderValueChange:(UISlider *)slider
{
    [self.playItem seekToTime:CMTimeMake(slider.value, 1)];
}
#pragma mark - private method

- (NSTimeInterval)availableDuration
{
    NSArray *loadedTimeRanges = [self.playItem loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}
/**
 设置slider的状态
 */
- (void)readySlider
{
    self.slider.maximumValue = CMTimeGetSeconds(self.duration);

    // 设置slider的进度图片
    UIGraphicsBeginImageContextWithOptions((CGSize){1,1}, NO, 0.f);
    UIImage *img = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [self.slider setMinimumTrackImage:img forState:UIControlStateNormal];
    [self.slider setMaximumTrackImage:img forState:UIControlStateNormal];
}
/**
 将时间格式化
 */
- (NSString *)convertTime:(CGFloat)timeInterval
{
    int minute = timeInterval / 60;
    int hour = minute / 60;
    int second = (int)round(timeInterval) % 60;
    NSString *timeString = [NSString stringWithFormat:@"%02d:%02d:%02d",hour,minute,second];

    return timeString;
}

/**
 获取播放控件的所在controller
 */
- (UIViewController *)currentViewController
{
    for (UIView* next = [self superview]; next; next = next.superview) {
        UIResponder* nextResponder = [next nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController*)nextResponder;
        }
    }
    return nil;
}


/**
 切换工具条的状态，隐藏或显示
 */
- (void)switchToolViewState
{
    self.playerTopToolView.hidden = !self.playerTopToolView.hidden;
    self.playerBottomToolView.hidden = !self.playerBottomToolView.hidden;
    // 若显示，则在5秒后将其隐藏
    if (!self.playerBottomToolView.hidden)
    {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(5. * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            self.playerTopToolView.hidden = YES;
            self.playerBottomToolView.hidden = YES;
        });
    }
}

/**
 重置工具条
 */
- (void)resetToolViewState
{
    self.slider.value = 0;
    self.progresser.progress = 0;
    self.playOrPauseBtn.selected = NO;
}

@end
