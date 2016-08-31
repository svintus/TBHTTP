//
//  TBURLSessionManager.h
//  TBHTTP
//
//  Created by Marcus Osobase on 2016-08-20.
//  Copyright © 2016 TunnelBear. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TBSerialization.h"

NS_ASSUME_NONNULL_BEGIN
typedef void (^TBURLSessionTaskBlock)
(NSURLResponse *response, id _Nullable responseObject, NSError * _Nullable error);

@interface TBChallengeHandler: NSObject

typedef NS_ENUM(NSUInteger, TBSSLPinningMode) {
  TBSSLPinningModeNone,
  TBSSLPinningModeCertificate
};

@property (nonatomic, readonly) TBSSLPinningMode SSLPinningMode;
@property (nonatomic) BOOL validateDomain;
@property (nonatomic, copy) NSArray <NSString *> *pinnedCertificatePaths;

- (BOOL)authorizeCredentialsForChallenge: (NSURLAuthenticationChallenge *)challenge;
- (void)excludeTrustedHosts: (NSArray <NSString *> *)trustedHosts;

+ (NSMutableArray *)retrieveCertificatePathsInBundle:(NSBundle *)bundle;

+ (instancetype)challengeHandlerWithSSLPinningMode: (TBSSLPinningMode)mode;
+ (instancetype)challengeHandlerWithSSLPinningMode: (TBSSLPinningMode)mode
                            pinnedCertificatePaths: (NSArray <NSString*> *)pinnedCerts;

@end

@interface TBURLSessionManager : NSObject
<NSURLSessionDelegate, NSURLSessionTaskDelegate,
NSURLSessionDataDelegate, NSURLSessionDownloadDelegate>

@property (nonatomic) TBHTTPResponseSerializer *responseSerializer;
@property (nonatomic) TBChallengeHandler *challengeHandler;

-(instancetype)initWithSessionConfiguration: (nullable NSURLSessionConfiguration*)config;


- (NSURLSessionDataTask *)dataTaskWithRequest: (NSURLRequest *)request
                                   completion: (TBURLSessionTaskBlock)completion;

@end
NS_ASSUME_NONNULL_END
