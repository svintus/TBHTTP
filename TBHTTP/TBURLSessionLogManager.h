//
//  TBURLSessionLogManager.h
//  TBHTTP
//
//  Created by Marcus Osobase on 2016-09-28.
//  Copyright © 2016 TunnelBear. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^TBURLSessionLoggingBlock) (NSString *logOutput);

typedef NS_ENUM(NSUInteger, TBLogLevel)
{
  TBLogLevelOff = 0,
  TBLogLevelLight,
  TBLogLevelVerbose
};

@interface TBURLSessionLogManager : NSObject
@property (nonatomic) TBLogLevel logLevel;
@property (nonatomic) TBURLSessionLoggingBlock logger;

- (void)logInfo: (NSString *)info;
- (void)logVerbose: (NSString *)output;

- (void)logError: (NSError *)error;
- (void)logRequest: (NSURLRequest *)request;
- (void)logResponse: (NSHTTPURLResponse *)response responseObject: (id)object;
@end
