//
//  OSDataManger.m
//  OpenSilo
//
//  Created by Elmir Kouliev on 7/16/14.
//  Copyright (c) 2014 OpenSilo, Inc. All rights reserved
//

#import "OSDataManager.h"
#import "OSWebServiceMacro.h"
#import "OSSession.h"

@implementation OSDataManager

+ (OSDataManager *)sharedManager
{
    static OSDataManager *manager = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        NSURL *baseURL = [NSURL URLWithString:API_HOME];
        manager = [[OSDataManager alloc] initWithBaseURL:baseURL sessionConfiguration:[[self class] OSSessionConfiguration]];
        manager.requestSerializer = [AFJSONRequestSerializer serializer];
    });
    return manager;
}

+ (NSURLSessionConfiguration *)OSSessionConfiguration
{
    NSURLSessionConfiguration* configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    return configuration;
}

- (void)postApiRequest:(NSString*)path params:(NSDictionary *)params setAuthHeader:(BOOL)setAuthHeader responseBlock:(OSAPIResponseBlock)responseBlock{
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    if(setAuthHeader)
        [self.requestSerializer setValue:[OSSession getInstance].token forHTTPHeaderField:@"Authorization"];
    
    [self POST:path parameters:params
     
       success:^(NSURLSessionDataTask *operation, id responseObject) {
           [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
           if (responseBlock) responseBlock(responseObject, nil);
       }
       failure:^(NSURLSessionDataTask *operation, NSError *error) {
           [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
       }
     ];
    
}

- (void)getApiRequest:(NSString*)path params:(NSDictionary *)params setAuthHeader:(BOOL)setAuthHeader responseBlock:(OSAPIResponseBlock)responseBlock{

    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    if(setAuthHeader)
        [self.requestSerializer setValue:[OSSession getInstance].token forHTTPHeaderField:@"Authorization"];
    
    [self.requestSerializer setValue:@"application/json" forHTTPHeaderField:@"Content-type"];

    [self GET:path parameters:params
     
       success:^(NSURLSessionDataTask *operation, id responseObject) {
           [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
           if (responseBlock) responseBlock(responseObject, nil);
       }
     
       failure:^(NSURLSessionDataTask *operation, NSError *error) {
           [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
       }];
}

- (void)patchApiRequest:(NSString*)path params:(NSDictionary *)params setAuthHeader:(BOOL)setAuthHeader responseBlock:(OSAPIResponseBlock)responseBlock{
    
    [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    
    if(setAuthHeader)
        [self.requestSerializer setValue:[OSSession getInstance].token forHTTPHeaderField:@"Authorization"];
    
    [self PATCH:path parameters:params
     
       success:^(NSURLSessionDataTask *operation, id responseObject) {
           [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
           if (responseBlock) responseBlock(responseObject, nil);
       }
       failure:^(NSURLSessionDataTask *operation, NSError *error) {
           [[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
       }
     ];
    
}



@end
