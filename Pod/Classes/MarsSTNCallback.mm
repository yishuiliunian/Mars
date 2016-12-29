//
// Created by baidu on 2016/12/29.
//

#include "MarsSTNCallback.h"
#import "YHRefreshNormalHeader.h"
#import "YHRequest.h"
#import "YHSendMessage.h"
#import "YHCodecWrapper.h"

namespace mars {
    namespace stn {
        MarsSTNCallback* MarsSTNCallback::_shareInstance = NULL;
        MarsSTNCallback* MarsSTNCallback::ShareInstance() {
            if (_shareInstance == NULL) {
                _shareInstance = new MarsSTNCallback();
            }
            return _shareInstance;
        }

        //实现Mars的纯虚函数
         bool MarsSTNCallback::MakesureAuthed()
        {
            return true;
        }
        void MarsSTNCallback::OnPush(int32_t cmdid, const AutoBuffer &msgpayload) {

        }

        bool MarsSTNCallback::Req2Buf(int32_t taskid, void *const user_context, AutoBuffer &outbuffer, int &error_code, const int channel_select) {

            YHSendMessage * request = (__bridge YHSendMessage *)user_context;
            NSData* data = [YHCodecWrapper encode:request];
            outbuffer.AllocWrite(data.length, true);
            outbuffer.Write(data.bytes, data.length);
            return data.length > 0;
        }

        int MarsSTNCallback::Buf2Resp(int32_t taskid, void *const user_context, const AutoBuffer &inbuffer, int &error_code, const int channel_select) {

            return mars::stn::kTaskFailHandleDefault;
        }

        int MarsSTNCallback::OnTaskEnd(int32_t taskid, void *const user_context, int error_type, int error_code) {

            return 0;
        }

        void MarsSTNCallback::ReportConnectStatus(int status, int longlink_status) {

        }

        void MarsSTNCallback::ReportFlow(int32_t wifi_recv, int32_t wifi_send, int32_t mobile_recv, int32_t mobile_send) {

        }


        bool MarsSTNCallback::OnLonglinkIdentifyResponse(const AutoBuffer &response_buffer, const AutoBuffer &identify_buffer_hash) {
            return false;
        }

        int MarsSTNCallback::GetLonglinkIdentifyCheckBuffer(AutoBuffer &identify_buffer, AutoBuffer &buffer_hash, int32_t &cmdid) {
            return IdentifyMode::kCheckNever;
        }

        void MarsSTNCallback::RequestSync() {

        }

        bool MarsSTNCallback::IsLogoned() {
            return true;
        }
    }
}