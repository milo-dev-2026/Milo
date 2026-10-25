package com.chat.push;

import android.app.Activity;
import android.app.Application;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.Context;
import android.media.RingtoneManager;
import android.net.Uri;
import android.os.Build;
import android.text.TextUtils;
import android.util.Log;

import com.chat.base.WKBaseApplication;
import com.chat.base.config.WKConstants;
import com.chat.base.endpoint.EndpointCategory;
import com.chat.base.endpoint.EndpointManager;
import com.chat.base.endpoint.entity.LoginMenu;
import com.chat.base.ui.Theme;
import com.chat.base.utils.WKDialogUtils;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.systembar.WKOSUtils;
import com.chat.push.push.OPPOPushCallback;
import com.chat.push.service.PushModel;
import com.chat.push.task.DeviceTokenRegisterTaskManager;
import com.huawei.hms.aaid.HmsInstanceId;
import com.heytap.msp.push.HeytapPushManager;
import com.xiaomi.mipush.sdk.MiPushClient;

import java.lang.ref.WeakReference;

/**
 * 推送管理（厂商通道直连：小米/华为/OPPO/Vivo）
 * 直接使用各厂商推送SDK，不经过友盟聚合
 */
public class WKPushApplication {
    private static final String TAG = "WKPush";

    private WKPushApplication() {
    }

    private static class PushApplicationBinder {
        static final WKPushApplication push = new WKPushApplication();
    }

    private WeakReference<Context> mContext;
    public String pushBundleID;
    private String currentDeviceType = "";

    public static WKPushApplication getInstance() {
        return PushApplicationBinder.push;
    }

    public void init(String pushBundleID, final Context context) {
        this.pushBundleID = pushBundleID;
        this.mContext = new WeakReference<>(context);
        addListener();
        initPush();
        EndpointManager.getInstance().setMethod("wk_push_init", EndpointCategory.loginMenus, object -> new LoginMenu(this::initPush));
    }

    private void initPush() {
        if (mContext == null || mContext.get() == null) return;
        Context context = mContext.get();
        // 提前创建通知渠道，确保推送消息到达时渠道已存在
        if (context instanceof Application) {
            notifyChannel((Application) context);
        }

        if (OsUtils.isMiui()) {
            currentDeviceType = "MI";
            initXiaoMiPush(context);
        } else if (OsUtils.isEmui()) {
            currentDeviceType = "HMS";
            initHuaWeiPush(context);
        } else if (OsUtils.isVivo()) {
            currentDeviceType = "VIVO";
            initVivoPush(context);
        } else if (OsUtils.isOppo()) {
            currentDeviceType = "OPPO";
            initOppoPush(context);
        } else {
            currentDeviceType = "MI";
            initXiaoMiPush(context);
        }

        Log.e(TAG, "推送初始化完成，设备类型: " + currentDeviceType);
    }

    /**
     * 初始化小米推送
     */
    private void initXiaoMiPush(Context context) {
        try {
            String xiaomiAppId = PushKeys.xiaoMiAppID;
            String xiaomiAppKey = PushKeys.xiaoMiAppKey;
            MiPushClient.registerPush(context.getApplicationContext(), xiaomiAppId, xiaomiAppKey);
            Log.e(TAG, "小米推送注册中: appId=" + xiaomiAppId);
        } catch (Exception e) {
            Log.e(TAG, "小米推送初始化失败", e);
        }
    }

    /**
     * 初始化华为推送
     */
    private void initHuaWeiPush(final Context context) {
        new Thread(() -> {
            try {
                HmsInstanceId hmsInstanceId = HmsInstanceId.getInstance(context);
                String token = hmsInstanceId.getToken(PushKeys.huaweiAPPID, "HCM");
                if (!TextUtils.isEmpty(token)) {
                    Log.e(TAG, "华为推送注册成功: token=" + token);
                    registerToken(token, "HMS");
                } else {
                    // token为空时延迟重试（HMS可能需要时间初始化）
                    Log.e(TAG, "华为推送token为空，5秒后重试...");
                    Thread.sleep(5000);
                    token = hmsInstanceId.getToken(PushKeys.huaweiAPPID, "HCM");
                    if (!TextUtils.isEmpty(token)) {
                        Log.e(TAG, "华为推送重试成功: token=" + token);
                        registerToken(token, "HMS");
                    } else {
                        Log.e(TAG, "华为推送token仍为空，等待onNewToken回调");
                    }
                }
            } catch (Exception e) {
                Log.e(TAG, "华为推送初始化失败", e);
            }
        }, "HmsPushInit").start();
    }

    /**
     * 初始化Vivo推送
     */
    private void initVivoPush(Context context) {
        try {
            com.vivo.push.PushClient.getInstance(context.getApplicationContext()).turnOnPush(new com.vivo.push.IPushActionListener() {
                @Override
                public void onStateChanged(int state) {
                    if (state == 0) {
                        Log.e(TAG, "Vivo推送开启成功，等待regId回调...");
                        // regId 通过 VivoPushMessageReceiverImpl.onReceiveRegId 回调获取
                    } else {
                        Log.e(TAG, "Vivo推送开启失败: state=" + state);
                    }
                }
            });
            Log.e(TAG, "Vivo推送初始化完成，等待regId回调...");
        } catch (Exception e) {
            Log.e(TAG, "Vivo推送初始化失败", e);
        }
    }

    /**
     * 初始化OPPO推送
     */
    private void initOppoPush(Context context) {
        try {
            HeytapPushManager.init(context.getApplicationContext(), true);
            HeytapPushManager.register(context.getApplicationContext(),
                    PushKeys.oppoAppKey, PushKeys.oppoAppSecret, new OPPOPushCallback());

            String regId = HeytapPushManager.getRegisterID();
            if (!TextUtils.isEmpty(regId)) {
                Log.e(TAG, "OPPO推送注册成功: regId=" + regId);
                registerToken(regId, "OPPO");
            }
        } catch (Exception e) {
            Log.e(TAG, "OPPO推送初始化失败", e);
        }
    }

    /**
     * 上报推送token到服务端（通过DeviceTokenRegisterTaskManager提供重试机制）
     */
    public void registerToken(String token, String deviceType) {
        if (TextUtils.isEmpty(token) || TextUtils.isEmpty(pushBundleID)) return;
        currentDeviceType = deviceType;
        DeviceTokenRegisterTaskManager.getInstance().registerToken(token, pushBundleID, deviceType, "WKPushApplication");
    }

    /**
     * 获取当前设备推送类型
     */
    public String getCurrentDeviceType() {
        return currentDeviceType;
    }

    private static void notifyChannel(Application context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationManager nm = (NotificationManager) context.getSystemService(Activity.NOTIFICATION_SERVICE);

            String channelId = WKConstants.newMsgChannelID;
            String channelName = "新消息通知";
            String channelDescription = "this is default channel!";
            NotificationChannel mNotificationChannel = new NotificationChannel(channelId, channelName, NotificationManager.IMPORTANCE_HIGH);
            mNotificationChannel.setDescription(channelDescription);
            mNotificationChannel.enableVibration(true);
            mNotificationChannel.enableLights(true);
            mNotificationChannel.setShowBadge(true);
            // 来消息提示音：使用 utalk 的 msg_notify 音频（渠道创建后声音不可改，故配合渠道 ID 升级生效）
            try {
                Uri newMsgSound = Uri.parse("android.resource://" + context.getPackageName() + "/" + com.chat.base.R.raw.msg_notify);
                mNotificationChannel.setSound(newMsgSound, new android.media.AudioAttributes.Builder()
                        .setUsage(android.media.AudioAttributes.USAGE_NOTIFICATION)
                        .setContentType(android.media.AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build());
            } catch (Exception e) {
                Log.e(TAG, "设置来消息提示音失败: " + e.getMessage());
            }
            mNotificationChannel.setLockscreenVisibility(android.app.Notification.VISIBILITY_PUBLIC);
            nm.createNotificationChannel(mNotificationChannel);

            String rtcChannelId = WKConstants.newRTCChannelID;
            String rtcChannelName = "语音通话提醒";
            String rtcChannelDescription = "voice and video call notification channel";
            NotificationChannel rtcChannel = new NotificationChannel(rtcChannelId, rtcChannelName, NotificationManager.IMPORTANCE_HIGH);
            rtcChannel.setDescription(rtcChannelDescription);
            rtcChannel.enableVibration(true);
            rtcChannel.setVibrationPattern(new long[]{0, 4000, 2000, 4000});
            rtcChannel.enableLights(true);
            rtcChannel.setShowBadge(true);
            // 语音通话使用系统默认来电铃声
            try {
                Uri ringtone = RingtoneManager.getDefaultUri(RingtoneManager.TYPE_RINGTONE);
                rtcChannel.setSound(ringtone, new android.media.AudioAttributes.Builder()
                        .setUsage(android.media.AudioAttributes.USAGE_NOTIFICATION_RINGTONE)
                        .setContentType(android.media.AudioAttributes.CONTENT_TYPE_SONIFICATION)
                        .build());
            } catch (Exception e) {
                Log.e(TAG, "设置来电铃声失败: " + e.getMessage());
            }
            rtcChannel.setLockscreenVisibility(android.app.Notification.VISIBILITY_PUBLIC);
            nm.createNotificationChannel(rtcChannel);

            // 清理历史版本的旧渠道，避免系统设置里出现多个重复的“新消息通知/语音通话提醒”
            try {
                nm.deleteNotificationChannel("wk_new_msg_notification_v2");
                nm.deleteNotificationChannel("wk_new_msg_notification_v3");
                nm.deleteNotificationChannel("wk_new_rtc_notification_v2");
            } catch (Exception e) {
                Log.e(TAG, "清理旧通知渠道失败: " + e.getMessage());
            }
        }
    }

    private void addListener() {
        EndpointManager.getInstance().setMethod("show_open_notification_dialog", object -> {
            if (!(object instanceof Context)) return null;
            Context context = (Context) object;
            WKDialogUtils.getInstance().showDialog(context, context.getString(R.string.open_notification_title), context.getString(R.string.open_notification_content), true, "", context.getString(R.string.open_setting), 0, Theme.colorAccount, index -> {
                if (index == 1) {
                    WKOSUtils.openChannelSetting(context, WKConstants.newMsgChannelID);
                }
            });
            return null;
        });
        // 注销推送
        EndpointManager.getInstance().setMethod("wk_logout", object -> {
            OsUtils.setBadge(WKBaseApplication.getInstance().getContext(), 0);
            DeviceTokenRegisterTaskManager.getInstance().unregisterToken();
            return null;
        });

        // 设置桌面红点数量
        EndpointManager.getInstance().setMethod("push_update_device_badge", object -> {
            if (!(object instanceof Integer)) return null;
            int num = (Integer) object;
            PushModel.getInstance().registerBadge(num);
            OsUtils.setBadge(WKBaseApplication.getInstance().getContext(), num);
            return null;
        });
    }
}
