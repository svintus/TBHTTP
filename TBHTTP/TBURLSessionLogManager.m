//
//  TBURLSessionLogManager.m
//  TBHTTP
//
//  Created by Marcus Osobase on 2016-09-28.
//  Copyright © 2016 TunnelBear. All rights reserved.
//

#import "TBURLSessionLogManager.h"

@implementation TBURLSessionLogManager

static inline NSString * logHeaders(NSDictionary *headers)
{
  __block NSString *headerString = @"";
  
  [headers enumerateKeysAndObjectsUsingBlock:
   ^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
     headerString = [headerString stringByAppendingString:
      [NSString stringWithFormat:@"%@ : %@\n", key, obj]];
   }];
  
  headerString =
  [headerString stringByReplacingCharactersInRange:
   [headerString rangeOfString:@"\n" options:NSBackwardsSearch] withString:@""];
  
  return [NSString stringWithFormat:@"\n\nHeaders: [\n%@ ]", headerString];
}


- (void)logInfo: (NSString *)info
{
  if (!info || self.logLevel == TBLogLevelOff) return;
  if (self.logger) self.logger(info);
}

- (void)logVerbose: (NSString *)output
{
  if (!output || self.logLevel != TBLogLevelVerbose) return;
  if (self.logger) self.logger(output);
}

- (void)logError: (NSError *)error
{
  if (!error || self.logLevel == TBLogLevelOff) return;
  
  NSString *output =
  [NSString stringWithFormat:@"Error: %@", error.localizedDescription];
  
  if (self.logger) self.logger(output);
}

- (void)logRequest: (NSURLRequest *)request
{
  if (!request || self.logLevel == TBLogLevelOff) return;
  
  NSString *output =
  [NSString stringWithFormat:@"\n\nRequest: %@ %@",
   request.HTTPMethod, request.URL];
  
  if (self.logLevel == TBLogLevelVerbose)
  {
    output = [output stringByAppendingString:
              logHeaders(request.allHTTPHeaderFields)];
  }
  
  if (self.logger) self.logger(output);
}

- (void)logResponse: (NSHTTPURLResponse *)response responseObject: (id)object
{
  if (!response || self.logLevel == TBLogLevelOff) return;
  
    NSString *output =
    [NSString stringWithFormat:@"\n\nResponse: %@ Status: %ld", response.URL,
     (long)response.statusCode];
  
  if (self.logLevel == TBLogLevelVerbose)
  {
    output = [output stringByAppendingString:logHeaders(response.allHeaderFields)];
    output = [output stringByAppendingString:
     [NSString stringWithFormat:@"\nResponse Object: %@\n", object ?: @"nil"]];
  }
  
  if (self.logger) self.logger(output);
}

@end
