//
//  SGAVPlayerMetadata.m
//  SGPlayer
//
//  Created by Artem Meleshko on 8/30/18.
//  Copyright © 2018 single. All rights reserved.
//

#import "SGAVPlayerMetadata.h"
#import <AVFoundation/AVFoundation.h>
#import <Endian.h>

@interface NSString (SGAVPlayerMetadata)
    
- (NSString *)trim;

- (NSString *)stringByDeletingNonPrintableCharacters;
    
@end
    
@implementation SGAVPlayerMetadata
    
+ (NSDictionary *)commonMetaDataForAsset:(AVAsset *)asset error:(NSError **)outError{
    
    if(asset){
        
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        NSError *error = nil;
        AVKeyValueStatus status = [asset statusOfValueForKey:@"commonMetadata" error:&error];
        
        if(status == AVKeyValueStatusLoaded || status == AVKeyValueStatusUnknown){
            
            NSArray *commonMetadata = [asset commonMetadata];
            NSArray *id3MetaData = [asset metadataForFormat:AVMetadataFormatID3Metadata];
            NSArray *iTunesMetaData = [asset metadataForFormat:AVMetadataFormatiTunesMetadata];
            NSArray *quickTimeMetadata = [asset metadataForFormat:AVMetadataFormatQuickTimeMetadata];
            NSArray *isoUserData = [asset metadataForFormat:AVMetadataFormatISOUserData];
            NSArray *quickTimeUserData = [asset metadataForFormat:AVMetadataFormatQuickTimeUserData];
            
            for (AVMetadataItem *metaItem in commonMetadata) {
                
                NSString *commonKey = metaItem.commonKey;
                
                if (commonKey.length == 0) {
                    if ([metaItem.key isKindOfClass:[NSNumber class]]==NO) {
                        continue;
                    }
                    NSUInteger uiKey = [(NSNumber *)metaItem.key unsignedIntegerValue];
                    NSMutableString *keyString = [[NSMutableString alloc] initWithCapacity:4];
                    unsigned char currentKeyChar;
                    for (int i = 0; i < 4; i++) {
                        currentKeyChar = (uiKey & (0xFF000000 >> i*8)) >> ((3 - i) * 8);
                        if (currentKeyChar != 0){
                            [keyString appendFormat:@"%.1s",&currentKeyChar];
                        }
                    }
                    if ([keyString isEqualToString:@"PIC"]){
                        commonKey = AVMetadataCommonKeyArtwork;
                    }
                    else if ([keyString isEqualToString:@"TAL"]){
                        commonKey = AVMetadataCommonKeyAlbumName;
                    }
                    else if ([keyString isEqualToString:@"TP1"]){
                        commonKey = AVMetadataCommonKeyArtist;
                    }
                }
                
                if([commonKey isEqualToString:AVMetadataCommonKeyTitle]){
                    NSString * str =[[self class] stringValueFromMetaDataItem:metaItem];
                    if (str.length > 0) {
                        [dic setObject:str forKey:commonKey];
                    }
                }
                else if([commonKey isEqualToString:AVMetadataCommonKeyAlbumName]){
                    NSString * str =[[self class] stringValueFromMetaDataItem:metaItem];
                    if (str.length > 0) {
                        [dic setObject:str forKey:commonKey];
                    }
                }
                else if([commonKey isEqualToString:AVMetadataCommonKeyArtist]){
                    NSString * str =[[self class] stringValueFromMetaDataItem:metaItem];
                    if (str.length > 0) {
                        [dic setObject:str forKey:commonKey];
                    }
                }
                else if([commonKey isEqualToString:AVMetadataCommonKeyDescription]){
                    NSString * str =[[self class] stringValueFromMetaDataItem:metaItem];
                    if (str.length > 0) {
                        [dic setObject:str forKey:commonKey];
                    }
                }
                else if([commonKey isEqualToString:AVMetadataCommonKeyCreationDate]){
                    NSDate * date = [[self class] dateValueFromMetaDataItem:metaItem];
                    if (date) {
                        NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitDay | NSCalendarUnitMonth | NSCalendarUnitYear fromDate:date];
                        NSInteger year = [components year];
                        if(year>0){
                            [dic setObject:@(year) forKey:commonKey];
                        }
                    }
                }
                else if ([commonKey isEqualToString:@"type"]){
                    NSString * str =[[self class] stringValueFromMetaDataItem:metaItem];
                    if (str.length > 0) {
                        [dic setObject:str forKey:commonKey];
                    }
                }
                else if([commonKey isEqualToString:AVMetadataCommonKeyArtwork]){
                    NSData *artworkData = nil;
                    @try{
                        if ([metaItem.value isKindOfClass:[NSDictionary class]]){
                            NSData *data = (NSData *)[(NSDictionary *)metaItem.value objectForKey:@"data"];
                            artworkData = data;
                        }
                        else if ([metaItem.value isKindOfClass:[NSData class]]){
                            artworkData = metaItem.dataValue;
                        }
                    }
                    @catch(NSException *exc){}
                    if(artworkData){
                        [dic setObject:artworkData forKey:commonKey];
                    }
                }
            }
            
            //Get metadata in other formats
            
            //ID3
            [[self class] readMetadataItemFromArray:id3MetaData key:AVMetadataID3MetadataKeyTitleDescription keySpace:AVMetadataKeySpaceID3 toDictionary:dic withKey:AVMetadataID3MetadataKeyTitleDescription];
            [[self class] readMetadataItemFromArray:id3MetaData key:AVMetadataID3MetadataKeyAlbumTitle keySpace:AVMetadataKeySpaceID3 toDictionary:dic withKey:AVMetadataID3MetadataKeyAlbumTitle];
            [[self class] readMetadataItemFromArray:id3MetaData key:AVMetadataID3MetadataKeyOriginalAlbumTitle keySpace:AVMetadataKeySpaceID3 toDictionary:dic withKey:AVMetadataID3MetadataKeyOriginalAlbumTitle];
            [[self class] readMetadataItemFromArray:id3MetaData key:AVMetadataID3MetadataKeyOriginalArtist keySpace:AVMetadataKeySpaceID3 toDictionary:dic withKey:AVMetadataID3MetadataKeyOriginalArtist];
            [[self class] readMetadataItemFromArray:id3MetaData key:AVMetadataID3MetadataKeyComments keySpace:AVMetadataKeySpaceID3 toDictionary:dic withKey:AVMetadataID3MetadataKeyComments];
            
            //iTunes
            [[self class] readMetadataItemFromArray:iTunesMetaData key:AVMetadataiTunesMetadataKeySongName keySpace:AVMetadataFormatiTunesMetadata toDictionary:dic withKey:AVMetadataiTunesMetadataKeySongName];
            [[self class] readMetadataItemFromArray:iTunesMetaData key:AVMetadataiTunesMetadataKeyAlbum keySpace:AVMetadataFormatiTunesMetadata toDictionary:dic withKey:AVMetadataiTunesMetadataKeyAlbum];
            [[self class] readMetadataItemFromArray:iTunesMetaData key:AVMetadataiTunesMetadataKeyArtist keySpace:AVMetadataFormatiTunesMetadata toDictionary:dic withKey:AVMetadataiTunesMetadataKeyArtist];
            [[self class] readMetadataItemFromArray:iTunesMetaData key:AVMetadataiTunesMetadataKeyDescription keySpace:AVMetadataFormatiTunesMetadata toDictionary:dic withKey:AVMetadataiTunesMetadataKeyDescription];
            [[self class] readMetadataItemFromArray:iTunesMetaData key:AVMetadataiTunesMetadataKeyUserGenre keySpace:AVMetadataFormatiTunesMetadata toDictionary:dic withKey:AVMetadataiTunesMetadataKeyUserGenre];
            
            //Quick time metadata
            [[self class] readMetadataItemFromArray:quickTimeMetadata key:AVMetadataQuickTimeMetadataKeyTitle keySpace:AVMetadataFormatQuickTimeMetadata toDictionary:dic withKey:AVMetadataQuickTimeMetadataKeyTitle];
            [[self class] readMetadataItemFromArray:quickTimeMetadata key:AVMetadataQuickTimeMetadataKeyAlbum keySpace:AVMetadataFormatQuickTimeMetadata toDictionary:dic withKey:AVMetadataQuickTimeMetadataKeyAlbum];
            [[self class] readMetadataItemFromArray:quickTimeMetadata key:AVMetadataQuickTimeMetadataKeyArtist keySpace:AVMetadataFormatQuickTimeMetadata toDictionary:dic withKey:AVMetadataQuickTimeMetadataKeyArtist];
            [[self class] readMetadataItemFromArray:quickTimeMetadata key:AVMetadataQuickTimeMetadataKeyComment keySpace:AVMetadataFormatQuickTimeMetadata toDictionary:dic withKey:AVMetadataQuickTimeMetadataKeyComment];
            [[self class] readMetadataItemFromArray:quickTimeMetadata key:AVMetadataQuickTimeMetadataKeyGenre keySpace:AVMetadataFormatQuickTimeMetadata toDictionary:dic withKey:AVMetadataQuickTimeMetadataKeyGenre];
            
            //ISO User Data
            [[self class] readMetadataItemFromArray:isoUserData key:AVMetadata3GPUserDataKeyTitle keySpace:AVMetadataKeySpaceISOUserData toDictionary:dic withKey:AVMetadata3GPUserDataKeyTitle];
            [[self class] readMetadataItemFromArray:isoUserData key:AVMetadata3GPUserDataKeyAlbumAndTrack keySpace:AVMetadataKeySpaceISOUserData toDictionary:dic withKey:AVMetadata3GPUserDataKeyAlbumAndTrack];
            [[self class] readMetadataItemFromArray:isoUserData key:AVMetadata3GPUserDataKeyPerformer keySpace:AVMetadataKeySpaceISOUserData toDictionary:dic withKey:AVMetadata3GPUserDataKeyPerformer];
            [[self class] readMetadataItemFromArray:isoUserData key:AVMetadata3GPUserDataKeyAuthor keySpace:AVMetadataKeySpaceISOUserData toDictionary:dic withKey:AVMetadata3GPUserDataKeyAuthor];
            [[self class] readMetadataItemFromArray:isoUserData key:AVMetadata3GPUserDataKeyDescription keySpace:AVMetadataKeySpaceISOUserData toDictionary:dic withKey:AVMetadata3GPUserDataKeyDescription];
            [[self class] readMetadataItemFromArray:isoUserData key:AVMetadata3GPUserDataKeyGenre keySpace:AVMetadataKeySpaceISOUserData toDictionary:dic withKey:AVMetadata3GPUserDataKeyGenre];
            
            //Quick Time User Data
            [[self class] readMetadataItemFromArray:quickTimeUserData key:AVMetadataQuickTimeUserDataKeyTrackName keySpace:AVMetadataKeySpaceQuickTimeUserData toDictionary:dic withKey:AVMetadataQuickTimeUserDataKeyTrackName];
            [[self class] readMetadataItemFromArray:quickTimeUserData key:AVMetadataQuickTimeUserDataKeyTrack keySpace:AVMetadataKeySpaceQuickTimeUserData toDictionary:dic withKey:AVMetadataQuickTimeUserDataKeyTrack];
            [[self class] readMetadataItemFromArray:quickTimeUserData key:AVMetadataQuickTimeUserDataKeyAlbum keySpace:AVMetadataKeySpaceQuickTimeUserData toDictionary:dic withKey:AVMetadataQuickTimeUserDataKeyAlbum];
            [[self class] readMetadataItemFromArray:quickTimeUserData key:AVMetadataQuickTimeUserDataKeyArtist keySpace:AVMetadataKeySpaceQuickTimeUserData toDictionary:dic withKey:AVMetadataQuickTimeUserDataKeyArtist];
            [[self class] readMetadataItemFromArray:quickTimeUserData key:AVMetadataQuickTimeUserDataKeyComment keySpace:AVMetadataKeySpaceQuickTimeUserData toDictionary:dic withKey:AVMetadataQuickTimeUserDataKeyComment];
            [[self class] readMetadataItemFromArray:quickTimeUserData key:AVMetadataQuickTimeUserDataKeyGenre keySpace:AVMetadataKeySpaceQuickTimeUserData toDictionary:dic withKey:AVMetadataQuickTimeUserDataKeyGenre];
            
            //Get TrackNumber and DiskNumber
            
            NSNumber *discNumber = nil;
            NSNumber *trackNumber = nil;
            
            @try {
                
                AVMetadataItem *trackNumberItem = [[AVMetadataItem metadataItemsFromArray:iTunesMetaData withKey:AVMetadataiTunesMetadataKeyTrackNumber keySpace:AVMetadataKeySpaceiTunes] lastObject];
                
                if (trackNumberItem != nil) {
                    // This is an MP4 atom
                    NSData *data = [trackNumberItem dataValue];
                    
                    if (data.length == 8) {
                        UInt16 *values = (UInt16 *)[[trackNumberItem dataValue] bytes];
                        UInt16 track = EndianU16_BtoN(values[1]);
                        //UInt16 trackOf = EndianU16_BtoN(values[2]);
                        trackNumber = [NSNumber numberWithUnsignedInt:track];
                    }
                }
                
                if (trackNumber == nil) {
                    // No atom metadata, maybe ID3
                    trackNumberItem = [[AVMetadataItem metadataItemsFromArray:id3MetaData withKey:AVMetadataID3MetadataKeyTrackNumber keySpace:AVMetadataKeySpaceID3] lastObject];
                    NSString *trackNumberString = [trackNumberItem stringValue];
                    NSRange trackNumberDividerRange = [trackNumberString rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"/-"]];
                    
                    if (trackNumberDividerRange.location == NSNotFound) {
                        trackNumber = [NSNumber numberWithInteger:[trackNumberString integerValue]];
                    } else {
                        trackNumber = [NSNumber numberWithInteger:[[trackNumberString substringToIndex:trackNumberDividerRange.location] integerValue]];
                    }
                }
                
                AVMetadataItem *discNumberItem = [[AVMetadataItem metadataItemsFromArray:iTunesMetaData withKey:AVMetadataiTunesMetadataKeyDiscNumber keySpace:AVMetadataKeySpaceiTunes] lastObject];
                
                if (discNumberItem != nil) {
                    // This is an MP4 atom
                    NSData *data = [discNumberItem dataValue];
                    
                    if (data.length == 6) {
                        UInt16 *values = (UInt16 *)[[discNumberItem dataValue] bytes];
                        UInt16 disc = EndianU16_BtoN(values[1]);
                        //UInt16 discOf = EndianU16_BtoN(values[2]);
                        discNumber = [NSNumber numberWithUnsignedInt:disc];
                    }
                }
                
                if (discNumber == nil) {
                    // No atom metadata, maybe ID3
                    discNumberItem = [[AVMetadataItem metadataItemsFromArray:id3MetaData withKey:AVMetadataID3MetadataKeyPartOfASet keySpace:AVMetadataKeySpaceID3] lastObject];
                    NSString *discNumberString = [discNumberItem stringValue];
                    NSRange discNumberDividerRange = [discNumberString rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"/-"]];
                    
                    if (discNumberDividerRange.location == NSNotFound) {
                        discNumber = [NSNumber numberWithInteger:[discNumberString integerValue]];
                    } else {
                        discNumber = [NSNumber numberWithInteger:[[discNumberString substringToIndex:discNumberDividerRange.location] integerValue]];
                    }
                }
            }
            @catch (NSException *exception) {}
            
            if([trackNumber unsignedLongLongValue]>0){
                [dic setObject:trackNumber forKey:@"tracknumber"];
            }
            
            if([discNumber unsignedLongLongValue]>0){
                [dic setObject:discNumber forKey:@"discnumber"];
            }
            
        }
        else{
            if(outError){
                *outError = error;
            }
            return nil;
        }
        
        NSDictionary *resultMeta = dic;
        return resultMeta;
        
    }
    
    return nil;
}
    
+ (void)readMetadataItemFromArray:(NSArray *)metadataArray
                              key:(NSString *)key
                         keySpace:(NSString *)keyspace
                     toDictionary:(NSMutableDictionary *)dictionary
                          withKey:(NSString *)dictionaryKey{
    AVMetadataItem *metaItem = [[AVMetadataItem metadataItemsFromArray:metadataArray withKey:key keySpace:keyspace] lastObject];
    NSString * str = [[self class] stringValueFromMetaDataItem:metaItem];
    if (str.length > 0 && [dictionary objectForKey:dictionaryKey]==nil) {
        [dictionary setObject:str forKey:dictionaryKey];
    }
}
    
    
+ (BOOL)isMetadataLoadedForAVPlayerItem:(AVPlayerItem *)playerItem{
    BOOL commonMetadataLoaded = NO;
    BOOL durationMetadataLoaded = NO;
    AVAsset *asset = nil;
    if(playerItem!=nil && playerItem!=(id)[NSNull null]){
        asset = playerItem.asset;
    }
    if(asset){
        NSError *error = nil;
        AVKeyValueStatus statusCommon = [asset statusOfValueForKey:@"commonMetadata" error:&error];
        if(statusCommon == AVKeyValueStatusLoaded){
            commonMetadataLoaded = YES;
        }
        AVKeyValueStatus statusDuration = [asset statusOfValueForKey:@"duration" error:&error];
        if(statusDuration == AVKeyValueStatusLoaded){
            durationMetadataLoaded = YES;
        }
    }
    return commonMetadataLoaded && durationMetadataLoaded;
}
    
+ (NSDictionary *)durationMetaDataForAsset:(AVAsset *)asset error:(NSError **)outError{
    if(asset){
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        NSError *error = nil;
        AVKeyValueStatus status = [asset statusOfValueForKey:@"duration" error:&error];
        if(status == AVKeyValueStatusLoaded){
            [dic setObject:@(CMTimeGetSeconds([asset duration])) forKey:@"duration"];
        }
        else{
            if(outError){
                *outError = error;
            }
            return nil;
        }
        return dic;
    }
    return nil;
}
    
+ (NSString *)stringValueFromMetaDataItem:(AVMetadataItem *)meta{
    NSString *result = @"";
    @try {
        NSString *theString = [meta stringValue];
        if(theString && [theString isKindOfClass:[NSString class]]){
            theString = [theString stringByDeletingNonPrintableCharacters];
            result = [theString trim];
        }
    } @catch (NSException *exception) {}
    return result;
}
    
+ (NSDate *)dateValueFromMetaDataItem:(AVMetadataItem *)meta{
    NSDate *result = nil;
    @try {
        NSDate *theDate = [meta dateValue];
        if(theDate && [theDate isKindOfClass:[NSDate class]]){
            result = theDate;
        }
    } @catch (NSException *exception) {}
    return result;
}
    
    
@end

@implementation NSString (SGAVPlayerMetadata)


- (NSString *)trim{
    return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (BOOL)isEqualToAnyStringFromSet:(NSSet *)setOfStrings{
    __block BOOL success = NO;
    [setOfStrings enumerateObjectsUsingBlock:^(id  _Nonnull obj, BOOL * _Nonnull stop) {
        NSCParameterAssert([obj isKindOfClass:[NSString class]]);
        if([obj isKindOfClass:[NSString class]]){
            NSString *compareStr = (NSString *)obj;
            if([compareStr isEqualToString:self]){
                success = YES;
                *stop = YES;
            }
        }
    }];
    return success;
}

+ (NSCharacterSet *)nonPrintableCharactersSet{
    static dispatch_once_t onceToken;
    static NSCharacterSet *nonPrintableSet = nil;
    dispatch_once(&onceToken, ^{
        NSMutableString *nonPrintableCharacters = [NSMutableString string];
        NSSet *escape = [NSSet setWithArray:@[@(8),//Backspace
                                              @(9),//Horizontal Tab
                                              @(10),//Line Feed
                                              @(11),//Vertical Tab
                                              @(12),//Form Feed
                                              @(13),//Carriage Return
                                              ]];
        for (char i = 1; i <= 31; i++)  {
            if([escape containsObject:@(i)]){
                continue;
            }
            [nonPrintableCharacters appendFormat:@"%c", i];
        }
        nonPrintableSet = [NSCharacterSet characterSetWithCharactersInString:nonPrintableCharacters];
    });
    return nonPrintableSet;
}

- (NSString *)stringByDeletingNonPrintableCharacters{
    NSString *strippedReplacement = [[self componentsSeparatedByCharactersInSet:[[self class] nonPrintableCharactersSet]] componentsJoinedByString:@""];
    return strippedReplacement;
}

@end
