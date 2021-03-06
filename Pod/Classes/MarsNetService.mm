//
// Created by baidu on 2016/12/29.
//

#import <mars/stn/stn_logic.h>
#import <mars/comm/autobuffer.h>
#import <mars/baseevent/base_logic.h>
#import "MarsNetService.h"
#import "YHRequest.h"
#import "MarsAppCallback.h"
#import "MarsSTNCallback.h"
#import "YHSendMessage.h"
#import "stnproto_logic.h"
#import "YHCmd.h"
#import "YHReadBuffer.h"
#import <YHNetCore/YHDNS.h>
#import <YHNetCore/YHSendMessage.h>
#import <YHProtoBuff/GPBMessage.h>
#import <mars/app/app_logic.h>
#import <mars/baseevent/base_logic.h>
#import <mars/xlog/xlogger.h>
#import <mars/xlog/xloggerbase.h>
#import <mars/xlog/appender.h>
#import <mars/xlog/preprocessor.h>
#import <Mars/mars/stn/stn.h>
#import <sys/xattr.h>
#import <DZFileUtils.h>
#import "YHReadBuffer.h"
#import "YHCodecWrapper.h"

@interface MarsNetService ()
{
     NSMutableDictionary * _requestCache;
     NSRecursiveLock * _lock;
     YHReadBuffer * _readBuffer;
}
@end

@implementation MarsNetService

+ (MarsNetService*) shareInstance
{
     static MarsNetService * shareInstance = nil;
     static dispatch_once_t  once;
     dispatch_once(&once, ^{
         shareInstance = [[MarsNetService alloc] init];
     });
     return shareInstance;
}

- (void) startLog
{
     NSString * logPath = DZPathJoin(DZApplicationDocumentsPath(), @"com.mars.logs");
// set do not backup for logpath
     const char* attrName = "com.apple.MobileBackup";
     u_int8_t attrValue = 1;
     setxattr([logPath UTF8String], attrName, &attrValue, sizeof(attrValue), 0, 0);

// init xlog
#if DEBUG
     xlogger_SetLevel(kLevelDebug);
     appender_set_console_log(true);
#else
     xlogger_SetLevel(kLevelInfo);
appender_set_console_log(false);
#endif
     appender_open(kAppednerAsync, [logPath UTF8String], "Test");
}

- (instancetype)init {
     self = [super init];
     if (!self) {
          return self;
     }
     _requestCache = [NSMutableDictionary new];
     _lock = [NSRecursiveLock new];
     //
     [self startLog];
     //
     mars::stn::SetCallback(mars::stn::MarsSTNCallback::ShareInstance());
     mars::app::SetCallback(mars::app::MarsAppCallback::ShareInstance());
     mars::baseevent::OnCreate();
     mars::stn::SetClientVersion(1);
     YHHost * yhHost = [YHDNS shareDNS].yaoheHost;
     std::vector<uint16_t> ports;
     ports.push_back([[yhHost port] intValue]);
     mars::stn::SetLonglinkSvrAddr([yhHost hostName].UTF8String, ports);
     mars::baseevent::OnForeground(YES);
     mars::stn::MakesureLonglinkConnected();
     return self;
}

- (void) cacheRequest:(YHSendMessage*)request
{
     if (!request)
     {
          return;;
     }
     [_lock lock];
     _requestCache[@(request.seq)] = request;
     [_lock unlock];
}

- (void) startRequest:(YHRequest*)request
{
     YHCmd* cmd = [YHCmd cmdWithServant:request.servant method:request.method];
     YHSendMessage* sendMsg = [YHSendMessage new];
     sendMsg.seq = [YHSendMessage getNextSEQ];
     sendMsg.cmd = cmd;
     sendMsg.dataBuffer = request.requestData.data;
     sendMsg.headers = request.requestHeader;

     mars::stn::Task task;
    task.cmdid = 1;
     task.taskid = sendMsg.seq;
    task.channel_strategy = mars::stn::Task::kChannelNormalStrategy;
    task.channel_select = mars::stn::Task::kChannelLong;
     task.user_context = (__bridge void*)sendMsg;
    [self cacheRequest:sendMsg];
    mars::stn::StartTask(task);
}

- (NSArray<YHSendMessage*> *) decodeServerPack:(YHReadBuffer *)readBuffer serverBuffer:(uint8_t*)buffer serverLength:(int64_t)length restBuffer:(YHReadBuffer * __autoreleasing*)restBuffer
{
    int packHeadLength = 4;
    uint8_t * readBufferPoint = buffer;
    uint32_t  aimLength = 0;
    if (readBuffer.aimDataLength == 0) {
        aimLength = byteToInt2(buffer);
        readBufferPoint = readBufferPoint +  packHeadLength;
        aimLength -= packHeadLength;
        length -= packHeadLength;
        readBuffer.aimDataLength = aimLength;
    } else
    {
        aimLength = readBuffer.aimDataLength;
    }
    NSMutableArray * msgs = [NSMutableArray new];

    YHFromMessage * (^BuildMessage)(YHReadBuffer * buffer) = ^(YHReadBuffer * buffer) {
        if (buffer.isFull) {
            YHFromMessage * msg = [YHCodecWrapper decode:buffer.bufferData];
            msg.originDataLength = buffer.receivedDataLength;
            return msg;
        } else {
            return (YHFromMessage *)nil;
        }
    };

    if (readBuffer.receivedDataLength + length < aimLength) {
        [readBuffer appendBytes:readBufferPoint length:length];
    } else (readBuffer.receivedDataLength + length == aimLength) {
        [readBuffer appendBytes:readBufferPoint length:length];
        YHFromMessage * fromMessage = BuildMessage(readBuffer);
        if (fromMessage) {
            [msgs addObject:fromMessage];
        }
    } else {
        int32_t readLength = (aimLength - readBuffer.receivedDataLength);
        [readBuffer appendBytes:readBufferPoint length:readLength];
        YHFromMessage * fromMessage = BuildMessage(readBuffer);
        if (fromMessage) {
            [msgs addObject:fromMessage];
        }

        uint8_t * restBufferPoint = readBufferPoint + readLength;
        int64_t  restBufferLength = length - readLength;

        uint32_t nextFrameLength = byteToInt2(restBufferPoint);
        if (nextFrameLength > restBufferLength) {
            if (restBuffer != NULL) {
                *restBuffer= [YHReadBuffer new];
                restBufferPoint = restBufferPoint +  packHeadLength;
                nextFrameLength -= packHeadLength;
                readBuffer.aimDataLength = aimLength;
                [*restBuffer setAimDataLength:nextFrameLength];
                [*restBuffer appendBytes:restBufferPoint length:restBufferLength];
            }
        } else {
            YHReadBuffer * appendBuffer = [YHReadBuffer new];
            NSArray * messages = [self decodeServerPack:appendBuffer serverBuffer:readBufferPoint+readLength serverLength:length - readLength restBuffer:restBuffer];
            if (messages.count) {
                [msgs addObjectsFromArray:messages];
            }
        }
    }
}
@end