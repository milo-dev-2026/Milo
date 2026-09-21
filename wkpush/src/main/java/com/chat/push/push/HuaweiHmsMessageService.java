package com.chat.push.push;

import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;

import com.chat.base.WKBaseApplication;
import com.chat.base.utils.WKDeviceUtils;
import com.chat.push.WKPushApplication;
import com.huawei.hms.push.HmsMessageService;

/**
 * 华为推送服务
 * token变更时通过WKPushApplication上报到服务端（带重试机制）
 */
public class HuaweiHmsMessageService extends HmsMessageService {
    @Override
    public void onNewToken(String s, Bundle bundle) {
        super.onNewToken(s, bundle);
        if (!TextUtils.isEmpty(s)) {
            Log.e("HuaweiPush", "华为推送token更新: " + s);
            WKPushApplication.getInstance().registerToken(s, "HMS");
        }
    }
}
