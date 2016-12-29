//
// Created by baidu on 2016/12/29.
//

#import <Foundation/Foundation.h>

@class YHRequest;

@interface MarsNetService : NSObject
+ (MarsNetService*) shareInstance;

- (void)startRequest:(YHRequest *)request;

@end