package com.chat.push.push;

import android.content.Context;
import android.util.Log;

import com.chat.push.WKPushApplication;
import com.vivo.push.model.UPSNotificationMessage;
import com.vivo.push.sdk.OpenClientPushMessageReceiver;

/**
 * Vivo推送广播接收器
 * token通过WKPushApplication上报到服务端（带重试机制）
 */
public class VivoPushMessageReceiverImpl extends OpenClientPushMessageReceiver {

    @Override
    public void onReceiveRegId(Context context, String regId) {
        super.onReceiveRegId(context, regId);
        Log.e("VivoPush", "Vivo推送注册成功: regId=" + regId);
        if (regId != null && !regId.isEmpty()) {
            WKPushApplication.getInstance().registerToken(regId, "VIVO");
        }
    }

    @Override
    public void onNotificationMessageClicked(Context context, UPSNotificationMessage msg) {
        super.onNotificationMessageClicked(context, msg);
    }
}
