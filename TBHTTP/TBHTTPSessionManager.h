//
//  TBHTTPSessionManager.h
//  TBHTTP
//
//  Created by Marcus Osobase on 2016-08-20.
//  Copyright © 2016 TunnelBear. All rights reserved.
//

#import "TBURLSessionManager.h"

typedef void (^TBHTTPCompletion)
(NSURLResponse *response, id responseObject, NSError *error);

@interface TBHTTPSessionManager : TBURLSessionManager

@property (nonatomic) NSURL *baseURL;
@property (nonatomic) TBHTTPRequestSerializer  *requestSerializer;

+ (instancetype)sessionManager;
- (instancetype)initWithBaseURL:(NSURL *)url;
- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)config;
- (instancetype)initWithBaseURL:(NSURL *)url
           sessionConfiguration:(NSURLSessionConfiguration *)config;

- (void)POST:(NSString *)path parameters:(NSDictionary *)parameters
  completion:(TBHTTPCompletion)completion;

- (void)GET:(NSString *)path parameters:(NSDictionary *)parameters
 completion:(TBHTTPCompletion)completion;

- (void)setValuesForHTTPHeaderFieldsFromDictionary: (NSDictionary *)dictionary;

- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field;

- (void)authorizeRequestsWithUsername: (NSString *)username
                             password: (NSString *)password;

@end
