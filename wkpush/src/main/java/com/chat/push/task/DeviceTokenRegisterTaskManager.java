package com.chat.push.task;

import android.text.TextUtils;
import android.util.Log;

import com.chat.base.config.WKConfig;
import com.chat.push.OsUtils;
import com.chat.push.service.PushModel;

import java.util.concurrent.atomic.AtomicBoolean;

/**
 * 设备Token注册任务管理器
 * 对齐UTalk的DeviceTokenRegisterTaskManager，提供重试机制和并发控制
 */
public class DeviceTokenRegisterTaskManager {
    private static final String TAG = "DeviceTokenRegister";
    private static final int MAX_RETRY_COUNT = 5;
    private static final long RETRY_DELAY_MS = 1000;

    private static volatile DeviceTokenRegisterTaskManager instance;

    private final AtomicBoolean registering = new AtomicBoolean(false);
    private final AtomicBoolean pending = new AtomicBoolean(false);

    private volatile String lastToken = "";
    private volatile String lastBundleId = "";
    private volatile String lastDeviceType = "";
    private volatile String lastFrom = "";

    private DeviceTokenRegisterTaskManager() {
    }

    public static DeviceTokenRegisterTaskManager getInstance() {
        if (instance == null) {
            synchronized (DeviceTokenRegisterTaskManager.class) {
                if (instance == null) {
                    instance = new DeviceTokenRegisterTaskManager();
                }
            }
        }
        return instance;
    }

    /**
     * 获取当前设备推送类型标识
     */
    public String getDeviceType() {
        if (OsUtils.isEmui()) {
            return "HMS";
        } else if (OsUtils.isMiui()) {
            return "MI";
        } else if (OsUtils.isVivo()) {
            return "VIVO";
        } else if (OsUtils.isOppo()) {
            return "OPPO";
        }
        return "";
    }

    /**
     * 规范化设备类型，确保与服务端常量一致
     * 服务端期望值: MI, HMS, VIVO, OPPO, IOS, FIREBASE
     */
    private String normalizeDeviceType(String deviceType) {
        if (TextUtils.isEmpty(deviceType)) {
            return "";
        }
        String type = deviceType.trim().toLowerCase();
        // 处理各种可能的输入格式
        if (type.contains("mi") || type.contains("xiaomi") || type.contains("小米")) {
            return "MI";
        } else if (type.contains("hms") || type.contains("huawei") || type.contains("华为") || type.contains("emui")) {
            return "HMS";
        } else if (type.contains("vivo")) {
            return "VIVO";
        } else if (type.contains("oppo") || type.contains("heytap") || type.contains("coloros")) {
            return "OPPO";
        } else if (type.contains("ios") || type.contains("apple") || type.contains("apns")) {
            return "IOS";
        } else if (type.contains("firebase") || type.contains("fcm") || type.contains("google")) {
            return "FIREBASE";
        }
        // 默认返回大写形式
        return deviceType.toUpperCase();
    }

    /**
     * 注册设备推送token（带重试机制）
     *
     * @param token      推送token
     * @param bundleId   应用包名
     * @param deviceType 设备类型
     * @param from       调用来源（用于日志追踪）
     */
    public void registerToken(final String token, final String bundleId, final String deviceType, final String from) {
        if (TextUtils.isEmpty(token) || TextUtils.isEmpty(bundleId)) {
            return;
        }
        // 规范化设备类型，确保与服务端常量一致（MI/HMS/VIVO/OPPO/IOS/FIREBASE）
        final String normalizedDeviceType = normalizeDeviceType(deviceType);

        // 检查用户是否已登录
        if (TextUtils.isEmpty(WKConfig.getInstance().getToken())) {
            Log.e(TAG, "用户未登录，跳过推送注册 from=" + from);
            // 延迟重试，等用户登录完成
            new Thread(() -> {
                try {
                    Thread.sleep(3000);
                    if (!TextUtils.isEmpty(WKConfig.getInstance().getToken())) {
                        Log.e(TAG, "用户已登录，重试推送注册 from=" + from);
                        registerToken(token, bundleId, normalizedDeviceType, from + "_retry");
                    }
                } catch (InterruptedException e) {
                    Thread.currentThread().interrupt();
                }
            }, "PushTokenDelay").start();
            return;
        }

        synchronized (this) {
            lastToken = token;
            lastBundleId = bundleId;
            lastDeviceType = normalizedDeviceType;
            lastFrom = from;
        }

        Log.e(TAG, "推送注册请求: token=" + token + " deviceType=" + normalizedDeviceType + " (原始=" + deviceType + ") from=" + from);

        if (registering.compareAndSet(false, true)) {
            new Thread(this::doRegisterWithRetry).start();
        } else {
            pending.set(true);
        }
    }

    /**
     * 注销设备推送token
     */
    public void unregisterToken() {
        PushModel.getInstance().unRegisterDeviceToken((code, msg) -> {
            Log.e(TAG, "注销推送token: code=" + code + " msg=" + msg);
        });
    }

    private void doRegisterWithRetry() {
        int attempt = 0;
        boolean success = false;

        String token, bundleId, deviceType, from;
        synchronized (DeviceTokenRegisterTaskManager.this) {
            token = lastToken;
            bundleId = lastBundleId;
            deviceType = lastDeviceType;
            from = lastFrom;
        }

        while (attempt < MAX_RETRY_COUNT && !success) {
            attempt++;
            try {
                if (attempt > 1) {
                    Thread.sleep(RETRY_DELAY_MS);
                }

                Log.e(TAG, "注册推送token attempt=" + attempt + " from=" + from);

                PushModel.getInstance().registerDeviceToken(token, bundleId, deviceType);
                success = true;
                Log.e(TAG, "推送token注册成功 attempt=" + attempt);
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                Log.e(TAG, "推送注册被中断");
                break;
            } catch (Exception e) {
                Log.e(TAG, "推送注册失败 attempt=" + attempt + " error=" + e.getMessage());
                if (attempt < MAX_RETRY_COUNT) {
                    Log.e(TAG, "将在" + RETRY_DELAY_MS + "ms后重试...");
                }
            }
        }

        if (!success) {
            Log.e(TAG, "推送token注册失败，已达最大重试次数=" + MAX_RETRY_COUNT);
        }

        registering.set(false);

        // 如果在注册期间有新的请求进来，处理pending请求
        if (pending.compareAndSet(true, false)) {
            registerToken(lastToken, lastBundleId, lastDeviceType, lastFrom + "_pending");
        }
    }

    public String getLastToken() {
        return lastToken;
    }

    public String getLastBundleId() {
        return lastBundleId;
    }
}
