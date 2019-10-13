//
//  RNAlbumsModule.m
//  RNAlbumsModule
//
//  Created by edison on 22/02/2017.
//  Copyright © 2017 edison. All rights reserved.
//

#import "RNAlbumsModule.h"
#import "RNAlbumOptions.h"
#import <Photos/Photos.h>
#import <React/RCTBridge.h>
#import <React/RCTUtils.h>
#import <PhotosUI/PhotosUI.h>

#pragma mark - declaration
static NSString *albumNameFromType(PHAssetCollectionSubtype type);
static BOOL isAlbumTypeSupported(PHAssetCollectionSubtype type);

@implementation RNAlbumsModule
NSMutableArray *albumName;
NSMutableDictionary *dictionary;
NSMutableArray *albumWithData;
ALAssetsLibrary *library;
NSArray *imageArray;
NSMutableArray *mutableArray;
static int count=0;
RCT_EXPORT_MODULE();

RCT_EXPORT_METHOD(getAllAlbumWithData:(NSDictionary *)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    [RNAlbumsModule authorize:^(BOOL authorized) {
        if (authorized) {
            PHFetchResult *result;
            albumName = [NSMutableArray array];
            albumWithData = [NSMutableArray array];
            dictionary = [[NSMutableDictionary alloc] init];

            result = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
            for (PHAssetCollection *obj in result) {
                [albumName addObject:obj.localizedTitle];
                PHFetchResult *collectionResult = [PHAsset fetchAssetsInAssetCollection:obj options:nil];
                if (collectionResult.count != 0) {
                    [albumWithData addObject:obj.localizedTitle];
                }else{
                    __block NSMutableArray *list = [NSMutableArray array];
                    [dictionary setObject:list forKey:obj.localizedTitle];
                }
            }
            
            for (int i = 0; i < albumWithData.count; i++) {
                __block PHAssetCollection *collection;
                PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
                fetchOptions.predicate = [NSPredicate predicateWithFormat:@"title = %@", albumWithData[i]];
                collection = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                                                                      subtype:PHAssetCollectionSubtypeAny
                                                                      options:fetchOptions].firstObject;
                
                NSMutableDictionary *albums = [[NSMutableDictionary alloc] init];
                PHFetchResult *collectionResult = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
                __block NSMutableArray *list = [NSMutableArray array];
                
                [collectionResult enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
                    
                    
                    __block NSMutableDictionary *imageObj = [[NSMutableDictionary alloc] init];
                    NSMutableDictionary *image = [[NSMutableDictionary alloc] init];
                    NSMutableDictionary *node = [[NSMutableDictionary alloc] init];
                    
                    NSString *path = [NSString stringWithFormat:@"ph://%@", asset.localIdentifier];
                    
                    NSString *assetType = [asset mediaType] == PHAssetMediaTypeImage ? @"image" : @"video";
                    [image setObject:path forKey:@"uri"];
                    [node setObject:assetType forKey:@"type"];
                    [node setObject:image forKey:@"image"];
                    [imageObj setObject:node forKey:@"node"];
                    [list addObject:imageObj];
                    if (collectionResult.count - 1 == idx) {
                        [dictionary setObject:list forKey:albumWithData[i]];
                        if (i == albumWithData.count - 1) {
                            NSMutableDictionary *resultDictionary = [[NSMutableDictionary alloc] init];
                            [resultDictionary setObject:albumName forKey:@"albums"];
                            [resultDictionary setObject:dictionary forKey:@"images"];
                            resolve(resultDictionary);
                        }
                    }
                }];
            }
        } else {
            NSString *errorMessage = @"Access Photos Permission Denied";
            NSError *error = RCTErrorWithMessage(errorMessage);
            reject(@(error.code), errorMessage, error);
        }
    }];
}



RCT_EXPORT_METHOD(getAllImageList:(NSDictionary *)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    imageArray=[[NSArray alloc] init];
    __block NSMutableArray *albumArray = [NSMutableArray array];
    PHFetchResult *result = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (PHAssetCollection *obj in result) {
        [albumArray addObject:obj.localizedTitle];
    }
    NSMutableDictionary *resultDictionary = [[NSMutableDictionary alloc] init];
    PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
    PHFetchResult *results = [PHAsset fetchAssetsWithOptions:fetchOptions];
    __block NSMutableArray *list = [NSMutableArray array];
    
    if (results.count == 0){
        [resultDictionary setObject:albumArray forKey:@"albums"];
        [resultDictionary setObject:list forKey:@"images"];
        resolve(resultDictionary);
    }
    
    [results enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL * _Nonnull stop) {
        __block NSMutableDictionary *imageObj = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *image = [[NSMutableDictionary alloc] init];
        NSMutableDictionary *node = [[NSMutableDictionary alloc] init];
        
        NSString *path = [NSString stringWithFormat:@"ph://%@", asset.localIdentifier];
        NSString *assetType = [asset mediaType] == PHAssetMediaTypeImage ? @"image" : @"video";
        [image setObject:path forKey:@"uri"];
        [node setObject:assetType forKey:@"type"];
        [node setObject:image forKey:@"image"];
        [imageObj setObject:node forKey:@"node"];
        [list addObject:imageObj];
        
        if (results.count - 1 == idx) {
            [resultDictionary setObject:albumArray forKey:@"albums"];
            [resultDictionary setObject:list forKey:@"images"];
            //                                    NSLog( @"list ===> %@ \n", resultDictionary);
            resolve(resultDictionary);
        }
    }];
}

RCT_EXPORT_METHOD(getImagesByAlbumName:(NSDictionary *)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejecter:(RCTPromiseRejectBlock)reject)
{
    if(options && [options objectForKey:@"albumName"]){
        __block NSString *albumName = options[@"albumName"];
        __block PHAssetCollection *collection;
        PHFetchOptions *fetchOptions = [[PHFetchOptions alloc] init];
        fetchOptions.predicate = [NSPredicate predicateWithFormat:@"title = %@", albumName];
        collection = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum
                                                              subtype:PHAssetCollectionSubtypeAny
                                                              options:fetchOptions].firstObject;
        
        NSMutableDictionary *albums = [[NSMutableDictionary alloc] init];
        PHFetchResult *collectionResult = [PHAsset fetchAssetsInAssetCollection:collection options:nil];
        __block NSMutableArray *list = [NSMutableArray array];
        NSLog(@"DATA %d", collectionResult.count);
        if (collectionResult.count == 0){
            resolve(list);
        }
        [collectionResult enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
            
            __block NSMutableDictionary *imageObj = [[NSMutableDictionary alloc] init];
            NSMutableDictionary *image = [[NSMutableDictionary alloc] init];
            NSMutableDictionary *node = [[NSMutableDictionary alloc] init];
            NSString *path = [NSString stringWithFormat:@"ph://%@", asset.localIdentifier];
            
            NSString *assetType = [asset mediaType] == PHAssetMediaTypeImage ? @"image" : @"video";
            [image setObject:path forKey:@"uri"];
            [node setObject:assetType forKey:@"type"];
            [node setObject:image forKey:@"image"];
            [imageObj setObject:node forKey:@"node"];
            [list addObject:imageObj];
            if (collectionResult.count - 1 == idx) {
                resolve(list);
            }
            
        }];
    }else{
        
    }
}


typedef void (^authorizeCompletion)(BOOL);

+ (void)authorize:(authorizeCompletion)completion {
    switch ([PHPhotoLibrary authorizationStatus]) {
        case PHAuthorizationStatusAuthorized: {
            // 已授权
            completion(YES);
            break;
        }
        case PHAuthorizationStatusNotDetermined: {
            // 没有申请过权限，开始申请权限
            [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
                [RNAlbumsModule authorize:completion];
            }];
            break;
        }
        default: {
            // Restricted or Denied, 没有授权
            completion(NO);
            break;
        }
    }
}

@end

#pragma mark - 

static NSString *albumNameFromType(PHAssetCollectionSubtype type) {
    switch (type) {
        case PHAssetCollectionSubtypeSmartAlbumUserLibrary: return @"UserLibrary";
        case PHAssetCollectionSubtypeSmartAlbumSelfPortraits: return @"SelfPortraits";
        case PHAssetCollectionSubtypeSmartAlbumRecentlyAdded: return @"RecentlyAdded";
        case PHAssetCollectionSubtypeSmartAlbumTimelapses: return @"Timelapses";
        case PHAssetCollectionSubtypeSmartAlbumPanoramas: return @"Panoramas";
        case PHAssetCollectionSubtypeSmartAlbumFavorites: return @"Favorites";
        case PHAssetCollectionSubtypeSmartAlbumScreenshots: return @"Screenshots";
        case PHAssetCollectionSubtypeSmartAlbumBursts: return @"Bursts";
        case PHAssetCollectionSubtypeSmartAlbumVideos: return @"Videos";
        case PHAssetCollectionSubtypeSmartAlbumSlomoVideos: return @"SlomoVideos";
        case PHAssetCollectionSubtypeSmartAlbumDepthEffect: return @"DepthEffect";
        default: return @"null";
    }
}

static BOOL isAlbumTypeSupported(PHAssetCollectionSubtype type) {
    switch (type) {
        case PHAssetCollectionSubtypeSmartAlbumUserLibrary:
        case PHAssetCollectionSubtypeSmartAlbumSelfPortraits:
        case PHAssetCollectionSubtypeSmartAlbumRecentlyAdded:
        case PHAssetCollectionSubtypeSmartAlbumTimelapses:
        case PHAssetCollectionSubtypeSmartAlbumPanoramas:
        case PHAssetCollectionSubtypeSmartAlbumFavorites:
        case PHAssetCollectionSubtypeSmartAlbumScreenshots:
        case PHAssetCollectionSubtypeSmartAlbumBursts:
        case PHAssetCollectionSubtypeSmartAlbumDepthEffect:
            return YES;
        default:
            return NO;
    }
}
