//
// Created by baidu on 2016/12/29.
//

#ifndef PODS_MARSAPPCALLBACK_H
#define PODS_MARSAPPCALLBACK_H

#import <mars/app/app.h>
#import <mars/app/app_logic.h>
using namespace std;
namespace mars {
    namespace app {
        class MarsAppCallback : public Callback {
        private:
            static MarsAppCallback* _shareInstance;
        private:
            MarsAppCallback() {}
            ~MarsAppCallback() {}
            MarsAppCallback(MarsAppCallback&);
            MarsAppCallback&operator = (MarsAppCallback&);

        public:
            static MarsAppCallback* ShareInstance();
            //
            virtual std::string GetAppFilePath();

            virtual AccountInfo GetAccountInfo();

            virtual unsigned int GetClientVersion();

            virtual DeviceInfo GetDeviceInfo();

        };
    }
}


#endif //PODS_MARSAPPCALLBACK_H
