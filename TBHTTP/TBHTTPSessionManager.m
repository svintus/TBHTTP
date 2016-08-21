//
//  TBHTTPSessionManager.m
//  TBHTTP
//
//  Created by Marcus Osobase on 2016-08-20.
//  Copyright © 2016 TunnelBear. All rights reserved.
//

#import "TBHTTPSessionManager.h"

@interface TBHTTPSessionManager()
@property (nonatomic) NSMutableDictionary *HTTPHeaderFields;
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
  return self;
}

#pragma mark - Public Methods

- (void)POST:(NSString *)path parameters:(NSDictionary *)parameters
  completion:(TBHTTPCompletion)completion
{
  NSURL *requestURL = [NSURL URLWithString:path relativeToURL: self.baseURL];
  
  NSMutableURLRequest *request =
  [NSMutableURLRequest requestWithURL:requestURL];
  [request setHTTPMethod:@"POST"];
  [self setupParameters:parameters forRequest:request];
  
  [request setValue:@"application/x-www-form-urlencoded" forHTTPHeaderField:@"Content-Type"];
  
  [self performRequest:request withCompeletion:completion];
}

#pragma mark -
- (void)setValue:(NSString *)value forHTTPHeaderField:(NSString *)field
{
  [self.HTTPHeaderFields setValue:value forKey:field];
}


#pragma mark -
- (NSString *)parameterStringFromDictionarty: (NSDictionary *)dictionary
{
  NSMutableArray *parameters = [NSMutableArray new];
  
  for (NSString *key in dictionary)
  {
    if ([dictionary[key] isKindOfClass:[NSString class]])
    {
      // Percent escaped
      NSString *encodedValue = dictionary[key];
      encodedValue =
      [encodedValue stringByAddingPercentEncodingWithAllowedCharacters:
       [[NSCharacterSet characterSetWithCharactersInString:
         @":/=,!$&'()*+;[]@#?^%\"`<>{}\\|~ "] invertedSet]];
      
      // Query string
      [parameters addObject:
       [NSString stringWithFormat:@"%@=%@", key, encodedValue]];
    }
  }
  
  NSLog(@"%@", [parameters componentsJoinedByString:@"&"]);
  return [parameters componentsJoinedByString:@"&"];
}

- (void)setupParameters: (NSDictionary *) parameters
             forRequest: (NSMutableURLRequest *)request
{
  // sending data
  //  NSString *boundary = @"TBHTTPReqeustBounday";
  //  NSString *contentType = [@"multipart/form-data; boundary="
  //                           stringByAppendingString:boundary];
  
  const char *parameterString =
  [[self parameterStringFromDictionarty:parameters] UTF8String];
  
  NSMutableData *data =
  [NSMutableData dataWithBytes:parameterString length:strlen(parameterString)];
  
  [self.HTTPHeaderFields enumerateKeysAndObjectsUsingBlock:
   ^(NSString *field, NSString *value, BOOL *stop)
  {
    if (![request valueForHTTPHeaderField:field])
      [request setValue:value forHTTPHeaderField:field];
  }];
  
  [request setHTTPBody:data];
}

- (void)performRequest: (NSMutableURLRequest *)request
       withCompeletion:(TBHTTPCompletion)completion
{
  NSURLSessionDataTask *dataTask =
  [self dataTaskWithRequest:request completion:completion];
  [dataTask resume];
}

@end
