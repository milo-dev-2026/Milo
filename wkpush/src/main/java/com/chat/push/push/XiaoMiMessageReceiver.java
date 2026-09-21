package com.chat.push.push;

import android.app.NotificationManager;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Bundle;
import android.text.TextUtils;
import android.util.Log;

import com.chat.base.WKBaseApplication;
import com.chat.base.config.WKConstants;
import com.chat.base.utils.NotificationCompatUtil;
import com.chat.push.WKPushApplication;
import com.xiaomi.mipush.sdk.ErrorCode;
import com.xiaomi.mipush.sdk.MiPushClient;
import com.xiaomi.mipush.sdk.MiPushCommandMessage;
import com.xiaomi.mipush.sdk.MiPushMessage;
import com.xiaomi.mipush.sdk.PushMessageReceiver;

import org.json.JSONObject;

import java.util.List;

/**
 * 小米推送广播接收器
 * token通过WKPushApplication上报到服务端（带重试机制）
 * 透传消息：直接在通知栏显示（模拟通知栏消息效果）
 */
public class XiaoMiMessageReceiver extends PushMessageReceiver {
    private static final String TAG = "XiaoMiPush";
    private String mRegId;

    /**
     * 透传消息到达（服务器发送的是透传消息时触发）
     * 需要手动显示通知（通知栏消息由小米SDK自动显示，透传消息需要自己处理）
     */
    @Override
    public void onReceivePassThroughMessage(Context context, MiPushMessage message) {
        if (message == null) return;
        Log.d(TAG, "onReceivePassThroughMessage: " + message.getContent());

        String title = message.getTitle();
        String content = message.getDescription();
        if (TextUtils.isEmpty(content)) {
            content = message.getContent();
        }
        if (TextUtils.isEmpty(title)) {
            title = "新消息";
        }

        // 解析 extra 数据，获取消息相关信息
        String channelID = "";
        String channelType = "1";
        try {
            if (message.getExtra() != null && !message.getExtra().isEmpty()) {
                String extraStr = new JSONObject(message.getExtra()).toString();
                Log.d(TAG, "pass-through extra: " + extraStr);
                // 尝试从 extra 中解析频道信息
                JSONObject extraJson = new JSONObject(message.getExtra());
                if (extraJson.has("channel_id")) {
                    channelID = extraJson.getString("channel_id");
                }
                if (extraJson.has("channel_type")) {
                    channelType = extraJson.getString("channel_type");
                }
            }
        } catch (Exception e) {
            Log.e(TAG, "parse pass-through extra error", e);
        }

        // 显示通知（使用 v2 通道，确保声音设置正确）
        showNotification(context, title, content, channelID, channelType);
    }

    /**
     * 通知栏消息被点击（服务器发送的是通知栏消息时触发）
     */
    @Override
    public void onNotificationMessageClicked(Context context, MiPushMessage message) {
        Log.d(TAG, "onNotificationMessageClicked: " + message.getMessageId());
    }

    /**
     * 通知栏消息到达（服务器发送的是通知栏消息时触发）
     * 通知由小米SDK自动显示，此处仅记录日志
     */
    @Override
    public void onNotificationMessageArrived(Context context, MiPushMessage message) {
        Log.d(TAG, "onNotificationMessageArrived: " + message.getMessageId());
    }

    @Override
    public void onCommandResult(Context context, MiPushCommandMessage message) {
        String command = message.getCommand();
        List<String> arguments = message.getCommandArguments();
        String cmdArg1 = ((arguments != null && arguments.size() > 0) ? arguments.get(0) : null);
        if (MiPushClient.COMMAND_REGISTER.equals(command)) {
            if (message.getResultCode() == ErrorCode.SUCCESS) {
                mRegId = cmdArg1;
                if (!TextUtils.isEmpty(mRegId) && !TextUtils.isEmpty(WKPushApplication.getInstance().pushBundleID)) {
                    Log.e(TAG, "小米推送注册成功: regId=" + mRegId);
                    WKPushApplication.getInstance().registerToken(mRegId, "MI");
                }
            } else {
                Log.e(TAG, "小米推送注册失败: code=" + message.getResultCode() + ", reason=" + message.getReason());
            }
        }
    }

    @Override
    public void onReceiveRegisterResult(Context context, MiPushCommandMessage message) {
        String command = message.getCommand();
        List<String> arguments = message.getCommandArguments();
        String cmdArg1 = ((arguments != null && arguments.size() > 0) ? arguments.get(0) : null);
        if (MiPushClient.COMMAND_REGISTER.equals(command)) {
            if (message.getResultCode() == ErrorCode.SUCCESS) {
                mRegId = cmdArg1;
                if (!TextUtils.isEmpty(mRegId) && !TextUtils.isEmpty(WKPushApplication.getInstance().pushBundleID)) {
                    Log.e(TAG, "小米推送注册回调: regId=" + mRegId);
                    WKPushApplication.getInstance().registerToken(mRegId, "MI");
                }
            }
        }
    }

    /**
     * 显示透传消息通知
     */
    private void showNotification(Context context, String title, String content, String channelID, String channelType) {
        try {
            // 创建通知渠道（消息通知渠道，带自定义声音）
            NotificationCompatUtil.Channel msgChannel = new NotificationCompatUtil.Channel(
                    WKConstants.newMsgChannelID,
                    "新消息通知",
                    NotificationManager.IMPORTANCE_HIGH,
                    "收到新消息时的通知",
                    androidx.core.app.NotificationCompat.VISIBILITY_PUBLIC,
                    new long[]{0, 200},
                    null  // 使用系统默认通知铃声，wkpush模块没有自定义raw资源
            );

            // 生成唯一通知ID
            int notifyId;
            if (!TextUtils.isEmpty(channelID)) {
                notifyId = Math.abs((channelID + "_" + channelType).hashCode());
            } else {
                notifyId = (int) (System.currentTimeMillis() % 10000);
            }

            // 点击通知打开主页面
            Intent intent = context.getPackageManager().getLaunchIntentForPackage(context.getPackageName());
            if (intent != null) {
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TOP);
            }

            android.app.Notification notification = NotificationCompatUtil.Companion.createNotificationBuilder(
                    context, msgChannel, title, content, intent, 0
            ).build();

            NotificationCompatUtil.Companion.notify(context, notifyId, notification);
            Log.d(TAG, "pass-through notification shown: " + title);
        } catch (Exception e) {
            Log.e(TAG, "show pass-through notification error", e);
        }
    }
}
