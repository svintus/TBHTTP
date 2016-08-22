//
//  TBSerialization.m
//  TBHTTP
//
//  Created by Marcus Osobase on 2016-08-21.
//  Copyright © 2016 TunnelBear. All rights reserved.
//

#import "TBSerialization.h"

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
  
  if (multipartRequest)
    [self setupParameters:parameters forMultiPartRequest:request];
  else
    [self setupParameters:parameters forRequest:request];
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

- (NSString *)parameterStringFromDictionarty: (NSDictionary *)dictionary
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
  
  NSLog(@"%@", [parameters componentsJoinedByString:@"&"]);
  return [parameters componentsJoinedByString:@"&"];
}

NSString * percentEscapedString(NSString *string)
{
  return [string stringByAddingPercentEncodingWithAllowedCharacters:
   [[NSCharacterSet characterSetWithCharactersInString:
     @":/=,!$&'()*+;[]@#?^%\"`<>{}\\|~ "] invertedSet]];
}

NSString * mimeTypeFromFileExtension(NSString *extension)
{
  NSString *UTI = (__bridge_transfer NSString *)
  UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                        (__bridge CFStringRef)extension, NULL);
  NSString *contentType = (__bridge_transfer NSString *)
  UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI,
                                  kUTTagClassMIMEType);
  
  return contentType ?: @"application/octet-stream";
}

- (void)setupParameters: (NSDictionary *) parameters
             forRequest: (NSMutableURLRequest *)request
{
  const char *parameterString =
  [[self parameterStringFromDictionarty:parameters] UTF8String];
  
  NSMutableData *data =
  [NSMutableData dataWithBytes:parameterString length:strlen(parameterString)];
  [request setHTTPBody:data];
  
  [request setValue:@"application/x-www-form-urlencoded"
 forHTTPHeaderField:@"Content-Type"];
}

- (void)setupParameters: (NSDictionary *) parameters
    forMultiPartRequest: (NSMutableURLRequest *)request
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
  
  [parameters enumerateKeysAndObjectsUsingBlock: ^(id key, id value, BOOL *stop)
   {
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
         fileName = [value lastPathComponent];
         fileData = [NSData dataWithContentsOfURL:value];
         contentType = mimeTypeFromFileExtension([value pathExtension]);
       }
       else
       {
         fileName = @"TBHTTPUserFile";
         fileData = value;
         contentType = @"application/octet-stream";
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
  NSLog(@"%@", [[NSString alloc] initWithData:data encoding:self.stringEncoding]);
//  NSString *altSring = [NSString stringWithUTF8String:[data bytes]];
  [request setHTTPBody:data];
}

@end
