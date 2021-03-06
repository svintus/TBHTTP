//
//  TBSerialization.m
//  TBHTTP
//
//  Created by Marcus Osobase on 2016-08-21.
//  Copyright © 2016 TunnelBear. All rights reserved.
//

#import "TBSerialization.h"

#if TARGET_OS_IOS
#import <MobileCoreServices/MobileCoreServices.h>
#else
#import <CoreServices/CoreServices.h>
#endif

#pragma mark - TBHTTPRequestSerializer
//------------------------------------------------------------------------
static NSString * const TBHTTPMultipartFormBoundary = @"TBHTTPMultipartFormBoundary";
static NSString * const CRLF = @"\r\n";

static inline NSString * TBMultipartFormInitialBoundary(NSString *boundary) {
  return [NSString stringWithFormat:@"--%@%@", boundary, CRLF];
}

static inline NSString * TBMultipartFormInlineBoundary(NSString *boundary) {
  return [NSString stringWithFormat:@"%@--%@%@", CRLF, boundary, CRLF];
}

static inline NSString * TBMultipartFormFinalBoundary(NSString *boundary) {
  return [NSString stringWithFormat:@"%@--%@--%@", CRLF, boundary, CRLF];
}

@implementation TBHTTPRequestSerializer

+ (instancetype)serializer
{
  return [[self alloc] init];
}

-(instancetype)init
{
  if (!(self = [super init]))return nil;
  // Default headers? User agent?
  self.HTTPHeaderFields = [NSMutableDictionary new];
  self.stringEncoding = NSUTF8StringEncoding;
  return self;
}

-(NSURLRequest *)serializedRequestFromRequest:(NSMutableURLRequest *)request
                             multipartRequest: (BOOL)multipartRequest
                                   parameters:(id)parameters
                                        error:(NSError *__autoreleasing *)error
{
  [self.HTTPHeaderFields enumerateKeysAndObjectsUsingBlock:
   ^(NSString *field, NSString *value, BOOL *stop)
   {
     if (![request valueForHTTPHeaderField:field])
       [request setValue:value forHTTPHeaderField:field];
   }];
  
  if (!parameters) return request;
  
  if ([request.HTTPMethod isEqualToString:@"POST"])
  {
    if (multipartRequest)
      [self setupParameters:parameters forMultiPartPOSTRequest:request];
    else
      [self setupParameters:parameters forPOSTRequest:request];
  }
  else if ([request.HTTPMethod isEqualToString:@"GET"])
  {
    if([parameters isKindOfClass:[NSDictionary class]])
    {
      NSDictionary *parameterDict = (NSDictionary*)parameters;
      if(parameterDict.count > 0)
      {
        NSString *urlString =
        [NSString stringWithFormat:@"%@?%@", request.URL,
         [self parameterStringFromDictionary:parameters]];
        
        request.URL = [NSURL URLWithString:urlString];
      }
    }
    else
      [NSException raise:NSInvalidArgumentException
                  format:@"GET parameters must be provided as NSDictionary."];
  }
  else
  {
    [NSException raise:NSInvalidArgumentException
                format:@"Content type %@ is currently unimplemented in TBHTTP",
     request.HTTPMethod];
  }
  
  return request;
}

- (NSURLRequest *)requestWithURL:(NSURL *)url method:(NSString *)method
                      parameters:(id)parameters error:(NSError **)error
{
  NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
  [request setHTTPMethod:method];
  
  BOOL multipartRequest = NO;
  for (NSString *key in parameters)
  {
    id value = parameters[key];
    if ([value isKindOfClass:[NSData class]] ||
        [value isKindOfClass:[NSURL class]])
    {
      multipartRequest = YES;
    }
  }
  
  request = [[self serializedRequestFromRequest:request
                               multipartRequest:multipartRequest
                                     parameters:parameters
                                          error:error] mutableCopy];
  return request;
}

- (NSString *)parameterStringFromDictionary: (NSDictionary *)dictionary
{
  NSMutableArray *parameters = [NSMutableArray new];
  
  [dictionary enumerateKeysAndObjectsUsingBlock:
   ^(id key, id value, BOOL *stop)
   {
     if ([value isKindOfClass:[NSString class]])
     {
       value = percentEscapedString(value);
       [parameters addObject:[NSString stringWithFormat:@"%@=%@", key, value]];
     }
     else if ([value isKindOfClass:[NSNumber class]])
     {
       [parameters addObject:[NSString stringWithFormat:@"%@=%@", key, value]];
     }
     else
     {
       // NO
     }
   }];
  
  //  NSLog(@"%@", [parameters componentsJoinedByString:@"&"]);
  return [parameters componentsJoinedByString:@"&"];
}

static NSString * percentEscapedString(NSString *string)
{
  return [string stringByAddingPercentEncodingWithAllowedCharacters:
          [[NSCharacterSet characterSetWithCharactersInString:
            @":/=,!$&'()*+;[]@#?^%\"`<>{}\\|~ "] invertedSet]];
}

static NSString * mimeTypeFromFileExtension(NSString *extension)
{
  NSString *UTI = (__bridge_transfer NSString *)
  UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                        (__bridge CFStringRef)extension, NULL);
  NSString *contentType = (__bridge_transfer NSString *)
  UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI,
                                  kUTTagClassMIMEType);
  
  return contentType ?: @"application/octet-stream";
}

static NSString * mimeTypeFromData(NSData *data)
{
  uint8_t c;
  [data getBytes:&c length:1];
  
  switch (c) {
    case 0xFF:
      return @"image/jpeg";
      break;
    case 0x89:
      return @"image/png";
      break;
    case 0x47:
      return @"image/gif";
      break;
    case 0x49:
    case 0x4D:
      return @"image/tiff";
      break;
    case 0x25:
      return @"application/pdf";
      break;
    case 0x46:
      return @"text/plain";
    case 0x50:
      return @"application/zip";
      break;
    default:
      return @"application/octet-stream";
  }
}

- (void)setupParameters: (NSDictionary *) parameters
         forPOSTRequest: (NSMutableURLRequest *)request
{
  const char *parameterString =
  [[self parameterStringFromDictionary:parameters] UTF8String];
  
  NSMutableData *data =
  [NSMutableData dataWithBytes:parameterString length:strlen(parameterString)];
  [request setHTTPBody:data];
  
  [request setValue:@"application/x-www-form-urlencoded"
 forHTTPHeaderField:@"Content-Type"];
}

- (void)setupParameters: (NSDictionary *) parameters
forMultiPartPOSTRequest: (NSMutableURLRequest *)request
{
  int parameterCount = (int)[parameters count];
  __block int parameterIndex = 0;
  NSString *boundary = TBHTTPMultipartFormBoundary;
  NSString *contentType = [@"multipart/form-data; boundary="
                           stringByAppendingString:boundary];
  [request setValue:contentType forHTTPHeaderField:@"Content-Type"];
  
  NSMutableData *data = [NSMutableData new];
  [data appendData:[TBMultipartFormInitialBoundary(boundary)
                    dataUsingEncoding:self.stringEncoding]];
  @weakifySelf()
  [parameters enumerateKeysAndObjectsUsingBlock: ^(id key, id value, BOOL *stop)
   {
     @strongifySelf()
     if ([value isKindOfClass:[NSString class]] ||
         [value isKindOfClass:[NSNumber class]])
     {
       [data appendData:
        [[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"%@\"%@%@",
          key, CRLF, CRLF] dataUsingEncoding:self.stringEncoding]];
       
       [data appendData:[[NSString stringWithFormat:@"%@" ,value]
                         dataUsingEncoding:self.stringEncoding]];
     }
     else
     {
       NSString *fileName;
       NSData *fileData;
       NSString *contentType;
       
       if ([value isKindOfClass:[NSURL class]])
       {
         fileData = [NSData dataWithContentsOfURL:value];
         contentType = mimeTypeFromFileExtension([value pathExtension]);
         fileName = [value lastPathComponent];
       }
       else
       {
         fileData = value;
         contentType = mimeTypeFromData(fileData);
         
         NSString *extension = [contentType componentsSeparatedByString:@"/"][1];
         if ([extension isEqualToString:@"octet-stream"]) extension = @"";
         else extension = [@"." stringByAppendingString:extension];
         fileName = [@"TBHTTPUserFile" stringByAppendingString:extension];
       }
       
       [data appendData:
        [[NSString stringWithFormat:@"Content-Disposition: attachment;"
          " name=\"%@\"; filename=\"%@\"%@", key, fileName, CRLF]
         dataUsingEncoding:NSUTF8StringEncoding]];
       
       [data appendData:
        [[NSString stringWithFormat:@"Content-Type: %@%@%@",
          contentType, CRLF, CRLF] dataUsingEncoding:NSUTF8StringEncoding]];
       
       [data appendData:fileData];
     }
     
     parameterIndex ++;
     if (parameterIndex == parameterCount) return;
     [data appendData:[TBMultipartFormInlineBoundary(boundary)
                       dataUsingEncoding:self.stringEncoding]];
   }];
  
  [data appendData:[TBMultipartFormFinalBoundary(boundary)
                    dataUsingEncoding:self.stringEncoding]];
  //  NSString *altSring = [NSString stringWithUTF8String:[data bytes]];
  [request setHTTPBody:data];
}
@end

#pragma mark - TBHTTPResponseSerializer
//------------------------------------------------------------------------
@interface TBHTTPResponseSerializer()
@property (nonatomic) NSStringEncoding stringEncoding;
@property (nonatomic) NSString *MIMEType;
@end

@implementation TBHTTPResponseSerializer

+ (instancetype)serializer
{
  return [[self alloc] init];
}

-(instancetype)init
{
  if (!(self = [super init]))return nil;
  self.stringEncoding = NSUTF8StringEncoding;
  self.MIMEType = @"text/html";
  return self;
}

-(id)serializedResponseFromURLResponse:(NSURLResponse *)response
                                  data:(NSData *)data
                                 error:(NSError *__autoreleasing *)error
{
  return [NSString stringWithUTF8String:[data bytes]];
}
@end


#pragma mark - TBJSONRequestSerializer
//------------------------------------------------------------------------
@interface TBJSONRequestSerializer()
@end

@implementation TBJSONRequestSerializer

-(NSURLRequest *)serializedRequestFromRequest:(NSMutableURLRequest *)request
                             multipartRequest: (BOOL)multipartRequest
                                   parameters:(id)parameters
                                        error:(NSError *__autoreleasing *)error
{
  [self.HTTPHeaderFields enumerateKeysAndObjectsUsingBlock:
   ^(NSString *field, NSString *value, BOOL *stop)
   {
     if (![request valueForHTTPHeaderField:field])
       [request setValue:value forHTTPHeaderField:field];
   }];
  
  if (!parameters) return request;
  
  if ([request.HTTPMethod isEqualToString:@"POST"])
  {
    [self setupParameters:parameters forJSONRequest:request];
  }
  else
  {
    [NSException raise:NSInvalidArgumentException
                format:@"Content type %@ is currently unimplemented in TBHTTP",
     request.HTTPMethod];
  }
  
  return request;
}

- (void)setupParameters: (NSDictionary *) parameters
         forJSONRequest: (NSMutableURLRequest *)request
{
  NSError *error;
  NSData *jsonData =
  [NSJSONSerialization dataWithJSONObject:parameters
                                  options:NSJSONWritingPrettyPrinted
                                    error:&error];
  
  if (error) {
    NSLog(@"JSON Serialization error: %@", error);
  }
  else {
    NSString *parameterString =
    [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSData *data = [parameterString dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:data];
    
//    NSLog(@"JSON String: %@", parameterString);
    [request setValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request setValue:[NSString stringWithFormat:@"%lu",
                       (unsigned long)[jsonData length]]
   forHTTPHeaderField:@"Content-Length"];
  }
}

@end

#pragma mark - TBJSONResponseSerializer
//------------------------------------------------------------------------
@interface TBJSONResponseSerializer()

@end

@implementation TBJSONResponseSerializer

+ (instancetype)serializer
{
  return [[self alloc] init];
}

-(instancetype)init
{
  if (!(self = [super init]))return nil;
  self.stringEncoding = NSUTF8StringEncoding;
  self.MIMEType = @"application/json";
  return self;
}

-(id)serializedResponseFromURLResponse:(NSURLResponse *)response
                                  data:(NSData *)data
                                 error:(NSError *__autoreleasing *)error
{
  NSDictionary *json;
  NSError *serializationError = nil;
  
  json = [NSJSONSerialization
          JSONObjectWithData:data options:NSJSONReadingMutableContainers
          error:&serializationError];
  
  if (serializationError)
  {
    NSLog(@"JSON Serialization error: %@", serializationError);
    *error = serializationError;
    return nil;
  }
  
  return json;
}
@end
