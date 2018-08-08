//
//  SGFFPlayer.h
//  SGPlayer
//
//  Created by Single on 03/01/2017.
//  Copyright © 2017 single. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <UIKit/UIKit.h>

#if __has_include(<SGPlayer/SGPlayer.h>)
FOUNDATION_EXPORT double SGPlayerVersionNumber;
FOUNDATION_EXPORT const unsigned char SGPlayerVersionString[];
#import <SGPlayer/SGDefines.h>
#else
#import "SGDefines.h"
#endif

@class SGPlayer;

@protocol SGFFPlayerDelegate <NSObject>

- (void)player:(SGPlayer *)player didChangePlaybackState:(SGPlaybackState)playbackState;
- (void)player:(SGPlayer *)player didChangeLoadingState:(SGLoadingState)loadingState;
- (void)player:(SGPlayer *)player didChangePlaybackTime:(CMTime)playbackTime;
- (void)player:(SGPlayer *)player didChangeLoadedTime:(CMTime)loadedTime;

@end

@interface SGPlayer : NSObject

@property (nonatomic, assign) NSInteger tag;
@property (nonatomic, strong) id object;

@property (nonatomic, weak) id <SGFFPlayerDelegate> delegate;

@property (nonatomic, copy, readonly) NSURL * URL;
- (void)replaceWithURL:(NSURL *)URL;

@property (nonatomic, assign, readonly) SGPlaybackState playbackState;
@property (nonatomic, assign, readonly) SGLoadingState loadingState;
@property (nonatomic, assign, readonly) CMTime playbackTime;
@property (nonatomic, assign, readonly) CMTime loadedTime;
@property (nonatomic, assign, readonly) CMTime duration;

@property (nonatomic, copy, readonly) NSError * error;

@property (nonatomic, strong) UIView * view;

- (void)play;
- (void)pause;
- (void)stop;

- (BOOL)seekable;
- (BOOL)seekToTime:(CMTime)time;
- (BOOL)seekToTime:(CMTime)time completionHandler:(void(^)(BOOL success, CMTime time))completionHandler;

@end