//
//  TBHTTPSessionManager.m
//  TBHTTP
//
//  Created by Marcus Osobase on 2016-08-20.
//  Copyright © 2016 TunnelBear. All rights reserved.
//

#import "TBHTTPSessionManager.h"

#pragma mark - TBHTTPSessionManager
//------------------------------------------------------------------------
@interface TBHTTPSessionManager()

@end

@implementation TBHTTPSessionManager

#pragma mark - Init

+ (instancetype)sessionManager
{
  return [[[self class] alloc] initWithBaseURL:nil];
}

- (instancetype)init
{
  return [self initWithBaseURL:nil];
}

- (instancetype)initWithBaseURL:(NSURL *)url
{
  return [self initWithBaseURL:url sessionConfiguration:nil];
}

- (instancetype)initWithSessionConfiguration:(NSURLSessionConfiguration *)config
{
  return [self initWithBaseURL:nil sessionConfiguration:config];
}

- (instancetype)initWithBaseURL:(NSURL *)url
           sessionConfiguration:(NSURLSessionConfiguration *)config
{
  if (!(self = [super initWithSessionConfiguration:config])) return nil;
  self.HTTPHeaderFields = [NSMutableDictionary new];
  self.baseURL = url;
  self.requestSerializer = [TBHTTPRequestSerializer serializer];
  self.responseSerializer = [TBJSONResponseSerializer serializer];
  self.challengeHandler = [TBChallengeHandler new];
  return self;
}

- (void)setRequestSerializer:(TBHTTPRequestSerializer *)requestSerializer
{
  _requestSerializer = requestSerializer;
}

-(void)setResponseSerializer:(TBHTTPResponseSerializer *)responseSerializer
{
  [super setResponseSerializer:responseSerializer];
}

-(void)setChallengeHandler:(TBChallengeHandler *)challengeHandler
{
  [super setChallengeHandler:challengeHandler];
}

#pragma mark - Public Methods

- (void)POST:(NSString *)path parameters:(NSDictionary *)parameters
  completion:(TBHTTPCompletion)completion
{
  NSError *serializationError = nil;
  NSURLRequest *request =
    [self.requestSerializer requestWithURL: [self requestURLWithPath: path]
                                    method: @"POST"
                                parameters: parameters
                                     error: &serializationError];
  
  if (serializationError)
  {
    NSLog(@"POST Serialization error: %@", serializationError);
    return;
  }
  
  [self performRequest:request withCompeletion:completion];
}

-  (void)GET:(NSString *)path parameters:(NSDictionary *)parameters
  completion:(TBHTTPCompletion)completion
{
  NSError *serializationError = nil;
  NSURLRequest *request =
    [self.requestSerializer requestWithURL: [self requestURLWithPath: path]
                                    method: @"GET"
                                parameters: parameters
                                     error: &serializationError];
  
  if (serializationError)
  {
    NSLog(@"GET Serialization error: %@", serializationError);
    return;
  }
  
  [self performRequest:request withCompeletion:completion];
}

#pragma mark -

-(void)setHTTPHeaderFields:(NSMutableDictionary *)HTTPHeaderFields
{
  _HTTPHeaderFields = HTTPHeaderFields;
  self.requestSerializer.HTTPHeaderFields = HTTPHeaderFields;
}

- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field
{
  [self.HTTPHeaderFields setValue:value forKey:field];
  self.requestSerializer.HTTPHeaderFields = self.HTTPHeaderFields;
}

- (void)performRequest: (NSURLRequest *)request
       withCompeletion:(TBHTTPCompletion)completion
{
  NSURLSessionDataTask *dataTask =
  [self dataTaskWithRequest:request completion:completion];
  [dataTask resume];
}

- (void)authorizeRequestsWithUsername: (NSString *)username
                             password: (NSString *)password
{
  NSData *credentials = [[NSString stringWithFormat:@"%@:%@", username,password]
                         dataUsingEncoding:NSUTF8StringEncoding];
  NSString *base64AuthString = [credentials base64EncodedStringWithOptions:
                                NSDataBase64Encoding64CharacterLineLength];
  NSString *headerValue = [NSString stringWithFormat:@"Basic %@",
                           base64AuthString];
  
  [self setValue: headerValue forHTTPHeaderField:@"Authorization"];
}

#pragma mark -

- (void)routeLogsToBlock:(TBURLSessionLoggingBlock)logger
                logLevel:(TBLogLevel)logLevel
{
  [super routeLogsToBlock:logger logLevel:logLevel];
}

//------------------------------------------------------------------------
#pragma mark - Private Methods

- (NSURL *)requestURLWithPath: (NSString *)path
{
  if (self.baseURL) {
    return
      [NSURL URLWithString:
        [self.baseURL.absoluteString stringByAppendingPathComponent: path]];
  }
  else {
    return [NSURL URLWithString: path];
  }
}

@end
