package com.chat.uikit.chat;

import android.app.Activity;
import android.content.ContentResolver;
import android.database.ContentObserver;
import android.database.Cursor;
import android.net.Uri;
import android.os.Build;
import android.os.Handler;
import android.os.Looper;
import android.provider.MediaStore;

import com.chat.base.config.WKConfig;
import com.chat.uikit.R;
import com.chat.uikit.chat.manager.WKSendMsgUtils;
import com.chat.uikit.chat.msgmodel.WKScreenshotContent;
import com.xinbida.wukongim.entity.WKChannelType;
import com.xinbida.wukongim.entity.WKMsg;
import com.xinbida.wukongim.msgmodel.WKTextContent;

public class ScreenShotHelper {
    private static ScreenShotHelper instance;
    private ContentObserver contentObserver;
    private Activity activity;
    private String channelId;
    private int channelType;
    // 截图提醒去重：同一频道5秒内只提醒一次，避免ContentObserver多次回调导致重复消息
    private static final long SCREENSHOT_NOTIFY_INTERVAL_MS = 5000;
    private long lastScreenshotNotifyTime = 0;
    private String lastScreenshotName = "";
    // 本机发出的截图消息 clientMsgNO：渲染时用于可靠判断「自己截图」，不依赖 msg.fromUID
    private static final java.util.Set<String> SELF_MSG_NOS =
            java.util.Collections.synchronizedSet(new java.util.HashSet<>());

    public static boolean isSelfScreenshotMsg(String clientMsgNO) {
        return clientMsgNO != null && !clientMsgNO.isEmpty() && SELF_MSG_NOS.contains(clientMsgNO);
    }

    private ScreenShotHelper() {}

    public static ScreenShotHelper getInstance() {
        if (instance == null) {
            synchronized (ScreenShotHelper.class) {
                if (instance == null) {
                    instance = new ScreenShotHelper();
                }
            }
        }
        return instance;
    }

    public void startMonitoring(Activity activity, String channelId, int channelType) {
        stopMonitoring();
        this.activity = activity;
        this.channelId = channelId;
        this.channelType = channelType;
        // 切换频道时重置去重状态
        lastScreenshotNotifyTime = 0;
        lastScreenshotName = "";

        Handler handler = new Handler(Looper.getMainLooper());
        contentObserver = new ContentObserver(handler) {
            @Override
            public void onChange(boolean selfChange, Uri uri) {
                super.onChange(selfChange, uri);
                checkScreenshot(uri);
            }
        };

        ContentResolver resolver = activity.getContentResolver();
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            resolver.registerContentObserver(
                    MediaStore.Images.Media.EXTERNAL_CONTENT_URI, true, contentObserver);
        } else {
            resolver.registerContentObserver(
                    MediaStore.Images.Media.EXTERNAL_CONTENT_URI, true, contentObserver);
        }
    }

    public void stopMonitoring() {
        if (contentObserver != null && activity != null && !activity.isDestroyed()) {
            try {
                activity.getContentResolver().unregisterContentObserver(contentObserver);
            } catch (Exception ignored) {
            }
        }
        contentObserver = null;
        activity = null;
        channelId = null;
        // 停止监听时重置去重状态
        lastScreenshotNotifyTime = 0;
        lastScreenshotName = "";
    }

    private void checkScreenshot(Uri uri) {
        if (activity == null || activity.isDestroyed() || channelId == null || channelId.isEmpty()) {
            return;
        }
        new Thread(() -> {
            Cursor cursor = null;
            try {
                String[] projection;
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                    projection = new String[]{MediaStore.Images.Media.DISPLAY_NAME,
                            MediaStore.Images.Media.RELATIVE_PATH};
                } else {
                    projection = new String[]{MediaStore.Images.Media.DISPLAY_NAME,
                            MediaStore.Images.Media.DATA};
                }
                cursor = activity.getContentResolver().query(uri, projection, null, null, null);
                if (cursor != null && cursor.moveToFirst()) {
                    String name = cursor.getString(cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DISPLAY_NAME));
                    String path;
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
                        path = cursor.getString(cursor.getColumnIndexOrThrow(MediaStore.Images.Media.RELATIVE_PATH));
                    } else {
                        path = cursor.getString(cursor.getColumnIndexOrThrow(MediaStore.Images.Media.DATA));
                    }
                    String combined = (name != null ? name : "") + " " + (path != null ? path : "");
                    if (combined.toLowerCase().contains("screenshot") || combined.toLowerCase().contains("截图") || combined.toLowerCase().contains("screenshots")) {
                        // 去重：同一张截图图片（同名）或5秒内只提醒一次
                        long now = System.currentTimeMillis();
                        if (name != null && name.equals(lastScreenshotName)) {
                            return;
                        }
                        if (now - lastScreenshotNotifyTime < SCREENSHOT_NOTIFY_INTERVAL_MS) {
                            return;
                        }
                        lastScreenshotNotifyTime = now;
                        lastScreenshotName = name != null ? name : "";
                        sendScreenshotNotification();
                    }
                }
            } catch (Exception ignored) {
            } finally {
                if (cursor != null) cursor.close();
            }
        }).start();
    }

    /**
     * 以居中系统提示形式展示在会话窗口内（type=WKContentType.screenshot=20）。
     * 不再产生独立会话提醒/文本气泡。
     * 群聊显示「xxx截图了页面」，单聊显示「对方已截图」。
     */
    private void sendScreenshotNotification() {
        new Handler(Looper.getMainLooper()).post(() -> {
            try {
                if (activity == null || activity.isDestroyed() || channelId == null || channelId.isEmpty()) {
                    return;
                }
                String tip;
                if (channelType == WKChannelType.GROUP) {
                    String name = WKConfig.getInstance().getUserName();
                    if (name == null || name.isEmpty()) {
                        name = activity.getString(R.string.app_name);
                    }
                    tip = name + activity.getString(R.string.screenshot_group_suffix);
                } else {
                    tip = activity.getString(R.string.screenshot_single_text);
                }
                WKScreenshotContent screenshotContent = new WKScreenshotContent(tip);
                // 携带发送者 uid，接收端据此显示「你已截图 / 对方已截图」
                screenshotContent.fromUid = WKConfig.getInstance().getUid();
                WKMsg wkMsg = new WKMsg();
                wkMsg.clientMsgNO = java.util.UUID.randomUUID().toString().replace("-", "");
                SELF_MSG_NOS.add(wkMsg.clientMsgNO);
                wkMsg.channelID = channelId;
                wkMsg.channelType = (byte) channelType;
                wkMsg.type = screenshotContent.type;
                wkMsg.baseContentMsgModel = screenshotContent;
                WKSendMsgUtils.getInstance().sendMessage(wkMsg);
            } catch (Exception ignored) {
            }
        });
    }
}
