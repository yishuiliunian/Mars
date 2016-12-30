//
// Created by baidu on 2016/12/29.
//

#import <Foundation/Foundation.h>



#define CMDID_GLOBAL_YOHE (1850004)

@class YHRequest;
@class YHReadBuffer;
@class YHSendMessage;

@interface MarsNetService : NSObject
+ (MarsNetService*) shareInstance;

- (void)startRequest:(YHRequest *)request;
- (NSArray<YHSendMessage*> *) decodeServerPack:(YHReadBuffer *)readBuffer serverBuffer:(uint8_t*)buffer serverLength:(int64_t)length restBuffer:(YHReadBuffer * __autoreleasing*)restBuffer

@end