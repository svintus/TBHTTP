//
//  TBSerialization.h
//  TBHTTP
//
//  Created by Marcus Osobase on 2016-08-21.
//  Copyright © 2016 TunnelBear. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TBURLRequestSerialization
- (NSURLRequest *)serializedRequestFromRequest: (NSURLRequest *)request
                              multipartRequest: (BOOL)multipartRequest
                                    parameters: (id)parameters
                                         error: (NSError **)error;
@end

@protocol TBURLResponseSerialization
@end


@interface TBHTTPRequestSerializer : NSObject <TBURLRequestSerialization>
@property (nonatomic) NSDictionary *HTTPHeaderFields;
@property (nonatomic) NSStringEncoding stringEncoding;

+ (instancetype)serializer;

- (NSURLRequest *)requestWithURL:(NSURL *)url method:(NSString *)method
                      parameters:(id)parameters error:(NSError **)error;

@end

@interface TBJSONRequestSerializer : TBHTTPRequestSerializer

@end

@interface TBHTTPResponseSerializer

@end
