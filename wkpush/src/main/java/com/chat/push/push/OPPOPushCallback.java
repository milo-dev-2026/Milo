package com.chat.push.push;

import android.text.TextUtils;
import android.util.Log;

import com.chat.push.WKPushApplication;
import com.heytap.msp.push.HeytapPushManager;
import com.heytap.msp.push.callback.ICallBackResultService;

/**
 * OPPO推送注册回调
 * 注册成功后获取regId并上报服务端
 */
public class OPPOPushCallback implements ICallBackResultService {
    private static final String TAG = "OPPOPushCallback";

    @Override
    public void onRegister(int responseCode, String registerID, String s2, String s3) {
        if (responseCode == 0) {
            Log.e(TAG, "OPPO推送注册成功: regId=" + registerID);
            if (!TextUtils.isEmpty(registerID)) {
                WKPushApplication.getInstance().registerToken(registerID, "OPPO");
            } else {
                String regId = HeytapPushManager.getRegisterID();
                if (!TextUtils.isEmpty(regId)) {
                    WKPushApplication.getInstance().registerToken(regId, "OPPO");
                }
            }
        } else {
            Log.e(TAG, "OPPO推送注册失败: code=" + responseCode + " msg=" + s2);
        }
    }

    @Override
    public void onUnRegister(int responseCode, String s, String s1) {
    }

    @Override
    public void onSetPushTime(int responseCode, String result) {
    }

    @Override
    public void onGetPushStatus(int responseCode, int status) {
    }

    @Override
    public void onGetNotificationStatus(int responseCode, int status) {
    }

    @Override
    public void onError(int responseCode, String s, String s1, String s2) {
        Log.e(TAG, "OPPO推送错误: code=" + responseCode + " msg=" + s);
    }
}
