//
//  OSDataManger.h
//  OpenSilo
//
//  Created by Elmir Kouliev on 7/16/14.
//  Copyright (c) 2014 OpenSilo, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AFNetworking/AFNetworking.h>

typedef void(^OSAPIResponseBlock)(id responseObject, NSError *error);

@interface OSDataManager : AFHTTPSessionManager

+ (OSDataManager *)sharedManager;

+ (NSURLSessionConfiguration *)OSSessionConfiguration;

- (void)postApiRequest:(NSString*)path params:(NSDictionary *)params setAuthHeader:(BOOL)setAuthHeader responseBlock:(OSAPIResponseBlock)responseBlock;

- (void)getApiRequest:(NSString*)path params:(NSDictionary *)params setAuthHeader:(BOOL)setAuthHeader responseBlock:(OSAPIResponseBlock)responseBlock;

- (void)patchApiRequest:(NSString*)path params:(NSDictionary *)params setAuthHeader:(BOOL)setAuthHeader responseBlock:(OSAPIResponseBlock)responseBlock;

@end
