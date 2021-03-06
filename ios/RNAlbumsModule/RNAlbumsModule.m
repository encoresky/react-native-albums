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
    NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:false];
    fetchOptions.sortDescriptors = [NSArray arrayWithObject:descriptor];
    
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
        NSArray<PHAssetResource *> *const assetResources = [PHAssetResource assetResourcesForAsset:asset];
        if ([assetResources firstObject]) {
            PHAssetResource *const _Nonnull resource = [assetResources firstObject];
            [image setObject:  resource.originalFilename forKey:@"filename"];
        }
        NSString *assetType = [asset mediaType] == PHAssetMediaTypeImage ? @"image" : @"video";
        [node setObject:assetType forKey:@"type"];
        
        
        if ([asset mediaType] == PHAssetMediaTypeVideo) {
            [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:nil resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                NSURL *url = (NSURL *)[[(AVURLAsset *)asset URL] fileReferenceURL];
                if ([url relativePath]) {
                    NSString *combined = [NSString stringWithFormat:@"file://%@", [url relativePath]];
                    [image setObject:combined forKey:@"uri"];
                    [image setObject:path forKey:@"thumburi"];
                    [node setObject:image forKey:@"image"];
                    [imageObj setObject:node forKey:@"node"];
                    [list addObject:imageObj];
                }
                if (results.count - 1 == idx) {
                        [resultDictionary setObject:albumArray forKey:@"albums"];
                        [resultDictionary setObject:list forKey:@"images"];
                        //                                    NSLog( @"list ===> %@ \n", resultDictionary);
                        resolve(resultDictionary);
                    }
            }];
        }else{
            [[PHImageManager defaultManager] requestImageDataForAsset:asset options:nil resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                NSString *uri = [info[@"PHImageFileURLKey"] absoluteString];
                if (uri) {
                    [image setObject:uri forKey:@"uri"];
                }else{
                    [image setObject:path forKey:@"uri"];
                }
                [node setObject:image forKey:@"image"];
                [imageObj setObject:node forKey:@"node"];
                [list addObject:imageObj];
                if (results.count - 1 == idx) {
                        [resultDictionary setObject:albumArray forKey:@"albums"];
                        [resultDictionary setObject:list forKey:@"images"];
                        resolve(resultDictionary);
                    }
            }];
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
        if (collectionResult.count == 0){
            resolve(list);
        }
        
        NSMutableArray<PHAsset *> *photos = [@[] mutableCopy];
        for(PHAsset *asset in collectionResult){
            [photos addObject:asset];
        }
        [photos sortUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"creationDate"
                                                                     ascending:NO
                                                                    comparator:^NSComparisonResult(NSDate *dateTime1, NSDate *dateTime2) {
            unsigned int flags = NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay;
            NSCalendar* calendar = [NSCalendar currentCalendar];
            
            NSDateComponents* components1 = [calendar components:flags fromDate:dateTime1];
            NSDate* date1 = [calendar dateFromComponents:components1];
            
            NSDateComponents* components2 = [calendar components:flags fromDate:dateTime2];
            NSDate* date2 = [calendar dateFromComponents:components2];
            
            NSComparisonResult comparedDates = [date1 compare:date2];
            if(comparedDates == NSOrderedSame)
            {
                return [dateTime2 compare:dateTime1];
            }
            return comparedDates;
        }
                                        ]]];
        
        [photos enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL *stop) {
            
            __block NSMutableDictionary *imageObj = [[NSMutableDictionary alloc] init];
            NSMutableDictionary *image = [[NSMutableDictionary alloc] init];
            NSMutableDictionary *node = [[NSMutableDictionary alloc] init];
            NSString *path = [NSString stringWithFormat:@"ph://%@", asset.localIdentifier];
            NSArray<PHAssetResource *> *const assetResources = [PHAssetResource assetResourcesForAsset:asset];
            if ([assetResources firstObject]) { 
                PHAssetResource *const _Nonnull resource = [assetResources firstObject];
                [image setObject:  resource.originalFilename forKey:@"filename"];
            }
            NSString *assetType = [asset mediaType] == PHAssetMediaTypeImage ? @"image" : @"video";
            [node setObject:assetType forKey:@"type"];
            if ([asset mediaType] == PHAssetMediaTypeVideo) {
                [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:nil resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                    NSURL *url = (NSURL *)[[(AVURLAsset *)asset URL] fileReferenceURL];
                    NSLog(@"url = %@", [url absoluteString]);
                    NSLog(@"url = %@", [url relativePath]);
                    NSString *combined = [NSString stringWithFormat:@"file://%@", [url relativePath]];
                    [image setObject:combined forKey:@"uri"];
                    [image setObject:path forKey:@"thumburi"];
                    [node setObject:image forKey:@"image"];
                    [imageObj setObject:node forKey:@"node"];
                    [list addObject:imageObj];
                    if (collectionResult.count - 1 == idx) {
                        resolve(list);
                    }
                }];
            }else{
                [[PHImageManager defaultManager] requestImageDataForAsset:asset options:nil resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                    NSString *uri = [info[@"PHImageFileURLKey"] absoluteString];
                    if (uri) {
                        [image setObject:uri forKey:@"uri"];
                    }else{
                        [image setObject:path forKey:@"uri"];
                    }
                    [node setObject:image forKey:@"image"];
                    [imageObj setObject:node forKey:@"node"];
                    [list addObject:imageObj];
                    if (collectionResult.count - 1 == idx) {
                        resolve(list);
                    }
                }];
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
