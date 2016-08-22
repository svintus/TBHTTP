//
//  TBURLSessionManager.h
//  TBHTTP
//
//  Created by Marcus Osobase on 2016-08-20.
//  Copyright © 2016 TunnelBear. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TBSerialization.h"

typedef void (^TBURLSessionTaskBlock)
(NSURLResponse *response, id responseObject, NSError *error);

@interface TBURLSessionManager : NSObject
<NSURLSessionDelegate, NSURLSessionTaskDelegate,
NSURLSessionDataDelegate, NSURLSessionDownloadDelegate>

@property (nonatomic) TBHTTPResponseSerializer *responseSerializer;

-(instancetype)initWithSessionConfiguration: (NSURLSessionConfiguration*)config;


- (NSURLSessionDataTask *)dataTaskWithRequest: (NSURLRequest *)request
                                   completion: (TBURLSessionTaskBlock)completion;

@end
