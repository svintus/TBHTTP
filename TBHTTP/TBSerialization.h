//
//  TBSerialization.h
//  TBHTTP
//
//  Created by Marcus Osobase on 2016-08-21.
//  Copyright © 2016 TunnelBear. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "utils.h"

NS_ASSUME_NONNULL_BEGIN
//------------------------------------------------------------------------
@protocol TBURLRequestSerialization
- (NSURLRequest *)serializedRequestFromRequest: (NSURLRequest *)request
                              multipartRequest: (BOOL)multipartRequest
                                    parameters: (nullable id)parameters
                                         error: (NSError **)error;
@end

@interface TBHTTPRequestSerializer : NSObject <TBURLRequestSerialization>
+ (instancetype)serializer;
- (NSURLRequest *)requestWithURL:(NSURL *)url method:(NSString *)method
                      parameters:(nullable id)parameters
                           error:(NSError **)error;

@property (nonatomic) NSDictionary *HTTPHeaderFields;
@property (nonatomic) NSStringEncoding stringEncoding;

@end

@interface TBJSONRequestSerializer : TBHTTPRequestSerializer

@end

//------------------------------------------------------------------------
@protocol TBURLResponseSerialization
-(id)serializedResponseFromURLResponse:(NSURLResponse *)response
                                  data:(NSData *)data
                                 error:(NSError **)error;

@end

@interface TBHTTPResponseSerializer: NSObject <TBURLResponseSerialization>
+ (instancetype)serializer;

@property (nonatomic, readonly) NSString *MIMEType;
@end

@interface TBJSONResponseSerializer : TBHTTPResponseSerializer

@end
NS_ASSUME_NONNULL_END
