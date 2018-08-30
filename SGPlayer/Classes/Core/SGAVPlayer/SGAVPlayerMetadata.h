//
//  SGAVPlayerMetadata.h
//  SGPlayer
//
//  Created by Artem Meleshko on 8/30/18.
//  Copyright © 2018 single. All rights reserved.
//

#import <Foundation/Foundation.h>

@class AVPlayerItem;
@class AVAsset;

@interface SGAVPlayerMetadata : NSObject

+ (BOOL)isMetadataLoadedForAVPlayerItem:(AVPlayerItem *)playerItem;
    
+ (NSDictionary *)commonMetaDataForAsset:(AVAsset *)asset error:(NSError **)outError;
    
+ (NSDictionary *)durationMetaDataForAsset:(AVAsset *)asset error:(NSError **)outError;
    
@end
