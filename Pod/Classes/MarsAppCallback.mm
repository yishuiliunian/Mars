//
// Created by baidu on 2016/12/29.
//

#include "MarsAppCallback.h"
#import <DZFileUtils.h>
namespace mars {
    namespace app {
        MarsAppCallback* MarsAppCallback::_shareInstance = NULL;

        MarsAppCallback* MarsAppCallback::ShareInstance() {
            if (_shareInstance == NULL) {
                _shareInstance = new MarsAppCallback();
            }
            return _shareInstance;
        }

        // return your app path
        std::string MarsAppCallback::GetAppFilePath(){
            return std::string([DZApplicationDocumentsPath() UTF8String]);
        }

        AccountInfo MarsAppCallback::GetAccountInfo() {
            AccountInfo info;

            return info;
        }

        unsigned int MarsAppCallback::GetClientVersion() {

            return 0;
        }

        DeviceInfo MarsAppCallback::GetDeviceInfo() {
            DeviceInfo info;

            info.devicename = "";
            info.devicetype = 1;

            return info;
        }
    }
}