//
//  GYVideoPlayerView.h
//  EduNews
//
//  Created by 高洋 on 2016/10/11.
//  Copyright © 2016年 gaoyang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface GYVideoPlayerView : UIView

/** 播放路径*/
@property (nonatomic, copy) NSString *videoURLStr;
/** 视频标题*/
@property (nonatomic, copy) NSString *videoTitleStr;

+ (instancetype)playerView;

/** 开始播放*/
- (void)play;
/** 暂停播放*/
- (void)pause;

@end
