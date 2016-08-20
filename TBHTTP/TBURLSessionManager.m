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

-(void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data
{
  if (data)
  {
    [self.mutableData appendData:data];
  }
}

-(void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error
{
  NSDictionary *json;
  if (error)
  {
    NSLog(@"%@", error);
    return;
  }
  
  error = nil;
  
  if (self.mutableData)
  {
    json = [NSJSONSerialization JSONObjectWithData:self.mutableData options:NSJSONReadingMutableContainers error:&error];
  }
  
  if (error)
  {
    NSLog(@"\nERROR\n\n");
    NSLog(@"%@", error.localizedDescription);
  }
  
  self.completion(task.response, json, error);
}

@end


#pragma mark - TBURLSessionManager
//------------------------------------------------------------------------
@interface TBURLSessionManager()
@property (nonatomic) NSURLSession *session;
@property (nonatomic) NSURLSessionConfiguration *sessionConfig;
@property (nonatomic) NSOperationQueue *operationQueue;
@property (nonatomic) NSMutableDictionary *taskDelegates;
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
  
  return self;
}

-(void)URLSession:(NSURLSession *)session
     downloadTask:(NSURLSessionDownloadTask *)downloadTask
didFinishDownloadingToURL:(NSURL *)location
{
  
}

#pragma mark -

- (NSURLSessionDataTask *)dataTaskWithRequest: (NSMutableURLRequest *)request
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
  // TODO: Probably not safe
  self.taskDelegates[@(task.taskIdentifier)] = delegate;
}

- (TBURLSessionManagerTaskDelegate *)delegateForTask: (NSURLSessionTask *)task
{
  return self.taskDelegates[@(task.taskIdentifier)];
}

- (void)removeDelegateForTask: (NSURLSessionTask *)task
{
  // TODO: Also unsafe
  [self.taskDelegates removeObjectForKey:@(task.taskIdentifier)];
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

@end
