//
//  TBURLSessionManager.m
//  TBHTTP
//
//  Created by Marcus Osobase on 2016-08-20.
//  Copyright © 2016 TunnelBear. All rights reserved.
//

#import "TBURLSessionManager.h"

#pragma mark - TBURLSessionManagerTaskDelegate
//------------------------------------------------------------------------

@interface TBURLSessionManagerTaskDelegate: NSObject
<NSURLSessionDataDelegate, NSURLSessionTaskDelegate, NSURLDownloadDelegate>

@property (nonatomic) NSMutableData *mutableData;
@property (nonatomic, weak) TBURLSessionManager *sessionManager;
@property (nonatomic, copy) TBURLSessionTaskBlock completion;
@end

@implementation TBURLSessionManagerTaskDelegate

-(instancetype)init
{
  if (!(self = [super init])) return nil;
  self.mutableData = [NSMutableData new];
  return self;
}

-(void)URLSession:(NSURLSession *)session
         dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
  if (data)
  {
    [self.mutableData appendData:data];
  }
}

-(void)URLSession:(NSURLSession *)session
             task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
  id responseObject = nil;
  
  if (!error)
  {
    NSError *serializationError = nil;
    responseObject = [self.sessionManager.responseSerializer
                      serializedResponseFromURLResponse:task.response
                      data:self.mutableData error:&serializationError];
    
    if (serializationError)
    {
      TBHTTPResponseSerializer *httpSerializer =
      [TBHTTPResponseSerializer serializer];
      if ([[task.response MIMEType] isEqualToString:httpSerializer.MIMEType])
      {
        NSError *httpSerializationError = nil;
        responseObject = [httpSerializer
                          serializedResponseFromURLResponse:task.response
                          data:self.mutableData error:&httpSerializationError];
        
        if (httpSerializationError)
        {
          responseObject = nil;
          NSLog(@"Errr...");
        }
      }
    }
  }
  
  self.completion(task.response, responseObject, error);
}

@end

#pragma mark - TBChallengeHandler
//------------------------------------------------------------------------
@interface TBChallengeHandler()
@property (nonatomic) TBSSLPinningMode SSLPinningMode;
@property (nonatomic) BOOL excludeTrustedHosts;
@property (nonatomic) NSArray *trustedHosts;
@end

@implementation TBChallengeHandler

-(instancetype)init
{
  if (!(self = [super init])) return nil;
  self.SSLPinningMode = TBSSLPinningModeNone;
  self.pinnedCertificatePaths = [NSMutableArray new];
  return self;
}

+ (instancetype)challengeHandlerWithSSLPinningMode: (TBSSLPinningMode)mode
{
  TBChallengeHandler *challengeHanlder = [self new];
  challengeHanlder.SSLPinningMode = mode;
  return challengeHanlder;
}

+ (instancetype)challengeHandlerWithSSLPinningMode: (TBSSLPinningMode)mode
                          pinnedCertificatatePaths: (NSArray <NSString*> *)pinnedCerts
{
  TBChallengeHandler *challengeHanlder =
  [self challengeHandlerWithSSLPinningMode:mode];
  challengeHanlder.pinnedCertificatePaths = pinnedCerts;
  return challengeHanlder;
}

+ (NSArray *)validCertTypes
{
  return @[@"cer", @"der"];
}

+ (NSMutableArray *)retrieveCertificatePathsInBundle:(NSBundle *)bundle
{
  NSMutableArray *certPaths = [NSMutableArray new];
  NSArray *certTypes = [self validCertTypes];
  
  for (NSString *types in certTypes)
  {
    [certPaths addObjectsFromArray:
     [bundle pathsForResourcesOfType:types inDirectory:nil]];
  }

  return certPaths;
}

-(void)setPinnedCertificatePaths:(NSMutableArray<NSString *> *)pinnedCertificatePaths
{
  for (NSString *path in pinnedCertificatePaths)
  {
    [self validateFilePathForCert:path];
  }
  
  NSLog(@"%@", pinnedCertificatePaths);
  _pinnedCertificatePaths = pinnedCertificatePaths;
}

- (void)validateFilePathForCert: (NSString *)path
{
  BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:path
                                                     isDirectory:nil];
  NSAssert(exists,
           ([NSString stringWithFormat:@"%@ is not a valid file path", path]));
  
  NSURL *fileURL = [NSURL fileURLWithPath:path];
  NSString *extention = [fileURL pathExtension];
  NSString *assertError =
  [NSString stringWithFormat:@"%@ is not a valid certificate type."
   " Please convert ""%@"" to one of the following: %@", extention,
   [fileURL lastPathComponent], [TBChallengeHandler validCertTypes]];
  NSAssert([[TBChallengeHandler validCertTypes] containsObject:extention],
           assertError);
}

- (void)excludeTrustedHosts:(NSArray<NSString *> *)trustedHosts
{
  self.trustedHosts = trustedHosts;
  self.excludeTrustedHosts = trustedHosts.count > 0;
}

- (NSArray *)getPinnedCertificates
{
  NSMutableArray *pinnedCerts = [NSMutableArray new];
  for (NSString *path in self.pinnedCertificatePaths)
  {
    SecCertificateRef certRef = [self certificateRefFromCertAtPath:path];
    [pinnedCerts addObject:(__bridge id _Nonnull)(certRef)];
  }
  
  return pinnedCerts;
}

- (SecCertificateRef)certificateRefFromCertAtPath: (NSString *)path
{
  NSData *certData = [NSData dataWithContentsOfFile:path];
  SecCertificateRef certRef =
  SecCertificateCreateWithData(NULL, (__bridge CFDataRef)(certData));
  return certRef;
}

- (BOOL)authorizeCredentialsForChallenge:(NSURLAuthenticationChallenge *)challenge
{
  SecTrustRef serverTrust = challenge.protectionSpace.serverTrust;
  NSString *domain = challenge.protectionSpace.host;
  
  BOOL excludeTrustedHost = NO;
  if (self.excludeTrustedHosts)
  {
    for (NSString *host in self.trustedHosts)
    {
      if ([domain containsString:host])
      {
        excludeTrustedHost = YES;
        break;
      }
    }
  }
  
  if (excludeTrustedHost || self.SSLPinningMode == TBSSLPinningModeNone)
  {
    return YES;
  }
  
  NSMutableArray *policies = [NSMutableArray array];
  if (self.validateDomain) {
    [policies addObject:(__bridge_transfer id)
     SecPolicyCreateSSL(true, (__bridge CFStringRef)domain)];
  } else {
    [policies addObject:(__bridge_transfer id)SecPolicyCreateBasicX509()];
  }
  
  
  NSArray *pinnedCertificates = [self getPinnedCertificates];
  SecTrustSetPolicies(serverTrust, (__bridge CFArrayRef)policies);
  SecTrustSetAnchorCertificates(serverTrust, (__bridge CFArrayRef)pinnedCertificates);
  CFIndex certificateCount = SecTrustGetCertificateCount(serverTrust);
  if (!certificateCount) return NO;
  
  SecTrustResultType result;
  SecTrustEvaluate(serverTrust, &result);
  BOOL certificateIsValid =
  (result == kSecTrustResultUnspecified || result == kSecTrustResultProceed);
  if (!certificateIsValid) return NO;
  
  NSMutableArray *trustChain =
  [NSMutableArray arrayWithCapacity:(NSUInteger)certificateCount];
  
  for (CFIndex i = 0; i < certificateCount; i++) {
    SecCertificateRef certificate = SecTrustGetCertificateAtIndex(serverTrust, i);
    NSLog(@"%@", certificate);
    [trustChain addObject:(__bridge id _Nonnull)(certificate)];
  }
  
  for (NSData *trustChainCertificate in trustChain)
  {
    if ([pinnedCertificates containsObject:trustChainCertificate]) {
      return YES;
    }
  }
  
  return NO;
}

@end


#pragma mark - TBURLSessionManager
//------------------------------------------------------------------------
@interface TBURLSessionManager()
@property (nonatomic) NSURLSession *session;
@property (nonatomic) NSURLSessionConfiguration *sessionConfig;
@property (nonatomic) NSOperationQueue *operationQueue;
@property (nonatomic) NSMutableDictionary *taskDelegates;
@property (nonatomic) NSLock *lock;
@end

@implementation TBURLSessionManager

-(instancetype)init
{
  return [self initWithSessionConfiguration:nil];
}

-(instancetype)initWithSessionConfiguration: (NSURLSessionConfiguration*)config
{
  if (!(self = [super init])) return nil;
  
  if (!config) config = [NSURLSessionConfiguration defaultSessionConfiguration];
  self.sessionConfig = config;
  
  self.operationQueue = [NSOperationQueue new];
  self.operationQueue.maxConcurrentOperationCount = 1;
  
  self.session = [NSURLSession
                  sessionWithConfiguration:self.sessionConfig
                  delegate:self delegateQueue:self.operationQueue];
  
  self.taskDelegates = [NSMutableDictionary new];
  self.lock = [NSLock new];
  
  return self;
}

-(void)URLSession:(NSURLSession *)session
     downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
  
}

#pragma mark -

- (NSURLSessionDataTask *)dataTaskWithRequest: (NSURLRequest *)request
                                   completion: (TBURLSessionTaskBlock)completion
{
  NSURLSessionDataTask *dataTask = [self.session dataTaskWithRequest:request];
  [self addDelegateForDataTask:dataTask withCompletion:completion];
  return dataTask;
}

#pragma mark -

- (void)addDelegateForDataTask:(NSURLSessionDataTask *)datatask
                withCompletion:(TBURLSessionTaskBlock)completion
{
  TBURLSessionManagerTaskDelegate *delegate =
  [TBURLSessionManagerTaskDelegate new];
  
  delegate.sessionManager = self;
  delegate.completion = completion;
  [self setDelegate:delegate forTask:datatask];
}

- (void)setDelegate:(TBURLSessionManagerTaskDelegate *)delegate
            forTask:(NSURLSessionTask *)task
{
  [self.lock lock];
  self.taskDelegates[@(task.taskIdentifier)] = delegate;
  [self.lock unlock];
}

- (TBURLSessionManagerTaskDelegate *)delegateForTask: (NSURLSessionTask *)task
{
  return self.taskDelegates[@(task.taskIdentifier)];
}

- (void)removeDelegateForTask: (NSURLSessionTask *)task
{
  [self.lock lock];
  [self.taskDelegates removeObjectForKey:@(task.taskIdentifier)];
  [self.lock unlock];
}

#pragma mark - Delegation

-(void)URLSession:(NSURLSession *)session
         dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
  TBURLSessionManagerTaskDelegate *delegate = [self delegateForTask:dataTask];
  [delegate URLSession:session dataTask:dataTask didReceiveData:data];
}

-(void)URLSession:(NSURLSession *)session
             task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
  TBURLSessionManagerTaskDelegate *delegate = [self delegateForTask:task];
  [delegate URLSession:session task:task didCompleteWithError:error];
  
  [self removeDelegateForTask:task];
}

-(void)URLSession:(NSURLSession *)session
didReceiveChallenge:(NSURLAuthenticationChallenge *)challenge
completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition,
                            NSURLCredential * _Nullable))completionHandler
{
  if (![challenge.protectionSpace.authenticationMethod
        isEqualTo:NSURLAuthenticationMethodServerTrust])
  {
    completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
    return;
  }
  
  
  if ([self.challengeHandler authorizeCredentialsForChallenge:challenge])
  {
    NSURLCredential *credential =
    [NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust];
    if (credential)
      completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
    else
      completionHandler(NSURLSessionAuthChallengePerformDefaultHandling, nil);
  }
  else
  {
    completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
  }
}


@end
