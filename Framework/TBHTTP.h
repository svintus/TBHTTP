//
//  TBHTTP.h
//  TBHTTP
//
//  Created by Marcus Osobase on 2016-08-26.
//  Copyright © 2016 TunnelBear. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for TBHTTP.
FOUNDATION_EXPORT double TBHTTPVersionNumber;

//! Project version string for TBHTTP.
FOUNDATION_EXPORT const unsigned char TBHTTPVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <TBHTTP/PublicHeader.h>


#import <TargetConditionals.h>

#ifndef _TBHTTP_
#define _TBHTTP_

#import <TBHTTP/TBHTTPSessionManager.h>
#import <TBHTTP/TBSerialization.h>
#import <TBHTTP/TBURLSessionManager.h>

#endif
