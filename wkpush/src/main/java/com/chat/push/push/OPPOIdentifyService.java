package com.chat.push.push;

import android.app.Service;
import android.content.Intent;
import android.os.IBinder;
import android.util.Log;

import com.chat.push.WKPushApplication;

/**
 * OPPO推送注册ID回调服务
 * 用于接收OPPO推送注册成功后的regId
 */
public class OPPOIdentifyService extends Service {
    private static final String TAG = "OPPOIdentifyService";

    @Override
    public void onCreate() {
        super.onCreate();
        try {
            Class<?> pushManagerClass = Class.forName("com.heytap.msp.push.HeytapPushManager");
            java.lang.reflect.Method getInstanceMethod = pushManagerClass.getMethod("getInstance");
            Object pushManager = getInstanceMethod.invoke(null);
            java.lang.reflect.Method getRegisterIDMethod = pushManagerClass.getMethod("getRegisterID");
            String regId = (String) getRegisterIDMethod.invoke(pushManager);
            if (regId != null && !regId.isEmpty()) {
                Log.e(TAG, "OPPO推送注册成功: regId=" + regId);
                WKPushApplication.getInstance().registerToken(regId, "OPPO");
            }
        } catch (Exception e) {
            Log.e(TAG, "获取OPPO regId失败", e);
        }
    }

    @Override
    public IBinder onBind(Intent intent) {
        return null;
    }

    @Override
    public int onStartCommand(Intent intent, int flags, int startId) {
        if (intent != null) {
            String regId = intent.getStringExtra("registerID");
            if (regId != null && !regId.isEmpty()) {
                Log.e(TAG, "OPPO推送注册回调: regId=" + regId);
                WKPushApplication.getInstance().registerToken(regId, "OPPO");
            }
        }
        return super.onStartCommand(intent, flags, startId);
    }
}
