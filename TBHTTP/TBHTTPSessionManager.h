//
//  TBHTTPSessionManager.h
//  TBHTTP
//
//  Created by Marcus Osobase on 2016-08-20.
//  Copyright © 2016 TunnelBear. All rights reserved.
//

#import "TBURLSessionManager.h"

NS_ASSUME_NONNULL_BEGIN
typedef void (^TBHTTPCompletion)
(NSURLResponse *response, id _Nullable responseObject, NSError * _Nullable error);

@interface TBHTTPSessionManager : TBURLSessionManager

@property (nonatomic, nullable) NSURL *baseURL;
@property (nonatomic, nullable, copy) NSMutableDictionary *HTTPHeaderFields;
@property (nonatomic) TBHTTPRequestSerializer *requestSerializer;

+ (instancetype)sessionManager;
- (instancetype)initWithBaseURL:(nullable NSURL *)url;
- (instancetype)initWithSessionConfiguration:(nullable NSURLSessionConfiguration *)config;
- (instancetype)initWithBaseURL:(nullable NSURL *)url
           sessionConfiguration:(nullable NSURLSessionConfiguration *)config;

- (void)POST:(NSString *)path parameters:(nullable NSDictionary *)parameters
  completion:(TBHTTPCompletion)completion;

- (void)GET:(NSString *)path parameters:(nullable NSDictionary *)parameters
 completion:(TBHTTPCompletion)completion;

- (void)setValue:(nullable NSString *)value forHTTPHeaderField:(NSString *)field;

- (void)authorizeRequestsWithUsername: (NSString *)username
                             password: (NSString *)password;

@end
NS_ASSUME_NONNULL_END
