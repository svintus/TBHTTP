//
//  utils.h
//  TBHTTP
//
//  Created by Marcus Osobase on 2016-09-14.
//  Copyright © 2016 TunnelBear. All rights reserved.
//

#ifndef utils_h
#define utils_h

#pragma mark - Convenience

#define weakifySelf() \
try {} @finally {} \
__weak __typeof__(self) self_weak_ = self; \


#define strongifySelf() \
try {} @finally {} \
__strong __typeof__(self) self = self_weak_; \

#endif /* utils_h */
