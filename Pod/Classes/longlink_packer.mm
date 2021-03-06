// Tencent is pleased to support the open source community by making GAutomator available.
// Copyright (C) 2016 THL A29 Limited, a Tencent company. All rights reserved.

// Licensed under the MIT License (the "License"); you may not use this file except in 
// compliance with the License. You may obtain a copy of the License at
// http://opensource.org/licenses/MIT

// Unless required by applicable law or agreed to in writing, software distributed under the License is
// distributed on an "AS IS" basis, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND,
// either express or implied. See the License for the specific language governing permissions and
// limitations under the License.


/*
 * longlink_packer.cc
 *
 *  Created on: 2012-7-18
 *      Author: yerungui, caoshaokun
 */

#import <Mars/mars/stn/stn.h>
#include "longlink_packer.h"
#define LONGLINK_UNPACK_NEXTFRAME  (-11)

#ifdef __APPLE__
#include "mars/comm/autobuffer.h"
#include "mars/xlog/xlogger.h"
#import "YHSendMessage.h"
#import "YHCmd.h"
#import "YHCodecWrapper.h"
#import "MarsNetService.h"
#import "YHReadBuffer.h"
#import "YHFromMessage.h"

#else
#include "comm/autobuffer.h"
#include "comm/xlogger/xlogger.h"
#include "comm/socket/unix_socket.h"
#endif



static uint32_t sg_client_version = 0;
#define NOOP_CMDID 6
#pragma pack(push, 1)
struct __STNetMsgXpHeader
{
    uint32_t    head_length;
    uint32_t    client_version;
    uint32_t    cmdid;
    uint32_t    seq;
    uint32_t	body_length;
};
#pragma pack(pop)

namespace mars {
namespace stn {
	void SetClientVersion(uint32_t _client_version)  {
		sg_client_version = _client_version;
	}
}
}


@interface


static int __unpack_test(const void* _packed, size_t _packed_len, uint32_t& _cmdid, uint32_t& _seq, size_t& _package_len, size_t& _body_len)
{
    _seq=mars::stn::Task::kNoopTaskID;
    _cmdid = NOOP_CMDID;
    _package_len = _packed_len;
    return LONGLINK_UNPACK_OK;
}




void longlink_pack(uint32_t _cmdid, uint32_t _seq, const void* _raw, size_t _raw_len, AutoBuffer& _packed)
{
    if (NULL != _raw) _packed.Write(_raw, _raw_len);
    _packed.Seek(0, AutoBuffer::ESeekStart);
}


int longlink_unpack(const AutoBuffer& _packed, uint32_t& _cmdid, uint32_t& _seq, size_t& _package_len, AutoBuffer& _body) {
    //
    static NSRecursiveLock * lock;
    static NSMutableArray * decodeMsgs;
    static YHReadBuffer * restReadBuffer;
    //
    static  dispatch_once_t once;
    dispatch_once(&once, ^{
        lock = [NSRecursiveLock new];
        decodeMsgs = [NSMutableArray new];
    });
    //

    YHFromMessage* msg = nil;
    int restMsgCount = 0;
    [lock lock];
    if (decodeMsgs.count) {
        msg = [decodeMsgs firstObject];
        [decodeMsgs removeObjectAtIndex:0];
        restMsgCount = decodeMsgs.count;
    }
    [lock unlock];
    //
    if (msg) {
        _cmdid = CMDID_GLOBAL_YOHE;
        _seq = msg.seq;
        _package_len = msg.originDataLength;
        _body.AllocWrite(msg.data.length);
        _body.Write(msg.data.bytes, msg.data.length);
        if (restMsgCount == 0) {
            return LONGLINK_UNPACK_OK;
        } else {
            return LONGLINK_UNPACK_NEXTFRAME;
        }
    } else if (restReadBuffer) {
        _cmdid = CMDID_GLOBAL_YOHE;
        _package_len = restReadBuffer.receivedDataLength + 4;
        _body.AllocWrite(_packed.Length());
        _body.Write(_packed.Pos(), _packed.Length());
        return LONGLINK_UNPACK_CONTINUE;
    } else {
        YHReadBuffer * buffer = [YHReadBuffer new];
        YHReadBuffer * restBuffer = nil;
        NSArray <YHFromMessage*>* msgs = [[MarsNetService shareInstance] decodeServerPack:buffer serverBuffer:_packed.Ptr(0) serverLength:_packed.Length() restBuffer:&restBuffer];
        if (msgs.count > 0) {
            [lock lock];
            [decodeMsgs addObjectsFromArray:msgs];
            [lock unlock];
        }
        return LONGLINK_UNPACK_NEXTFRAME;
    }

}

/**
 * nooping param
 */

uint32_t longlink_noop_cmdid() {return NOOP_CMDID;}
uint32_t longlink_noop_resp_cmdid() {return NOOP_CMDID;}
void longlink_noop_req_body(AutoBuffer& _body) {

    YHSendMessage * msg = [YHSendMessage new];
    YHCmd *cmd = [YHCmd cmdWithServant:@"Comm.DispatchServer.DispatchObj" method:@""];
    msg.cmd = cmd;
    msg.seq = [YHSendMessage getNextSEQ];
    NSData * data = [YHCodecWrapper encode:msg];
    _body.AllocWrite(data.length, true);
    _body.Write(data.bytes, data.length);


}
void longlink_noop_resp_body(AutoBuffer& _body) {


}
