package com.chat.base.utils;

import android.app.Activity;
import android.app.NotificationChannel;
import android.app.NotificationManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.PowerManager;
import android.provider.Settings;

import androidx.core.app.NotificationManagerCompat;

import com.chat.base.config.WKConstants;
import com.chat.base.utils.systembar.WKOSUtils;

import java.lang.reflect.Method;

/**
 * 权限检测工具类
 * 全部采用系统API真实检测，无手动确认、无弹窗、无跳转标记fallback
 */
public class PermissionHelper {

    /**
     * 确保通知渠道存在（跳转设置页前调用，确保用户进去能看到）
     */
    public static void ensureNotificationChannel(Context context, String channelId, String channelName, int importance) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationManager manager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
            if (manager != null) {
                NotificationChannel channel = manager.getNotificationChannel(channelId);
                if (channel == null) {
                    channel = new NotificationChannel(channelId, channelName, importance);
                    channel.enableVibration(true);
                    channel.enableLights(true);
                    channel.setShowBadge(true);
                    manager.createNotificationChannel(channel);
                }
            }
        }
    }

    // ==================== 通知权限 ====================

    public static boolean isNotificationEnabled(Context context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationManager manager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
            if (manager != null) {
                return manager.areNotificationsEnabled();
            }
            return false;
        } else {
            return NotificationManagerCompat.from(context).areNotificationsEnabled();
        }
    }

    public static void openNotificationSetting(Context context) {
        try {
            Intent intent = new Intent();
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                intent.setAction(Settings.ACTION_APP_NOTIFICATION_SETTINGS);
                intent.putExtra(Settings.EXTRA_APP_PACKAGE, context.getPackageName());
            } else {
                intent.setAction(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
                intent.setData(Uri.fromParts("package", context.getPackageName(), null));
            }
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            context.startActivity(intent);
        } catch (Exception e) {
            WKOSUtils.gotoSet(context);
        }
    }

    // ==================== 电池优化白名单 ====================

    public static boolean isBatteryOptimizationIgnored(Context context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PowerManager pm = (PowerManager) context.getSystemService(Context.POWER_SERVICE);
            if (pm != null) {
                return pm.isIgnoringBatteryOptimizations(context.getPackageName());
            }
            return false;
        }
        return true;
    }

    public static void openBatteryOptimizationSetting(Context context) {
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                Intent intent = new Intent(Settings.ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS);
                intent.setData(Uri.fromParts("package", context.getPackageName(), null));
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                context.startActivity(intent);
            } else {
                WKOSUtils.gotoSet(context);
            }
        } catch (Exception e) {
            WKOSUtils.gotoSet(context);
        }
    }

    // ==================== 自启动权限 ====================

    public static boolean isAutoStartEnabled(Context context) {
        if (WKOSUtils.isMiui()) {
            return checkAppOpsMode(context, 10008); // MIUI自启动权限op码（已验证）
        } else if (WKOSUtils.isEmui()) {
            return checkAppOpsMode(context, 10020);
        } else if (WKOSUtils.isVivo() || WKOSUtils.isOppo()) {
            return checkAppOpsMode(context, 10001);
        } else {
            return checkAppOpsMode(context, 10001);
        }
    }

    public static void openAutoStartSetting(Context context) {
        Intent intent = getAutoStartIntent(context);
        try {
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            context.startActivity(intent);
        } catch (Exception e) {
            WKOSUtils.gotoSet(context);
        }
    }

    private static Intent getAutoStartIntent(Context context) {
        if (WKOSUtils.isMiui()) {
            String[][] miuiTargets = {
                {"com.miui.securitycenter", "com.miui.permcenter.autostart.AutoStartManagementActivity"},
                {"com.miui.securitycenter", "com.miui.permcenter.startup.AutoStartManagementActivity"},
            };
            Intent intent = tryComponents(context, miuiTargets);
            if (intent != null) return intent;
        } else if (WKOSUtils.isEmui()) {
            String[][] huaweiTargets = {
                {"com.huawei.systemmanager", "com.huawei.systemmanager.startupmgr.StartupManagementActivity"},
                {"com.huawei.systemmanager", "com.huawei.systemmanager.optimize.process.ProtectActivity"},
            };
            Intent intent = tryComponents(context, huaweiTargets);
            if (intent != null) return intent;
        } else if (WKOSUtils.isVivo()) {
            String[][] vivoTargets = {
                {"com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.BgStartUpManager"},
                {"com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"},
            };
            Intent intent = tryComponents(context, vivoTargets);
            if (intent != null) return intent;
        } else if (WKOSUtils.isOppo()) {
            String[][] oppoTargets = {
                {"com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity"},
                {"com.oplus.safecenter", "com.oplus.safecenter.permission.startup.StartupAppListActivity"},
            };
            Intent intent = tryComponents(context, oppoTargets);
            if (intent != null) return intent;
        }
        Intent intent = new Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS);
        intent.setData(Uri.fromParts("package", context.getPackageName(), null));
        return intent;
    }

    private static Intent tryComponents(Context context, String[][] targets) {
        for (String[] target : targets) {
            Intent intent = new Intent();
            intent.setComponent(new ComponentName(target[0], target[1]));
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            if (isIntentAvailable(context, intent)) {
                return intent;
            }
        }
        return null;
    }

    private static boolean isIntentAvailable(Context context, Intent intent) {
        try {
            return intent.resolveActivity(context.getPackageManager()) != null;
        } catch (Exception e) {
            return false;
        }
    }

    /**
     * 通过AppOpsManager检测权限状态
     * @return true表示允许，false表示拒绝或检测失败
     */
    private static boolean checkAppOpsMode(Context context, int op) {
        try {
            Class<?> appOpsClass = Class.forName("android.app.AppOpsManager");
            Object appOps = context.getSystemService(Context.APP_OPS_SERVICE);
            if (appOps == null) return false;

            int uid = context.getApplicationInfo().uid;
            String pkg = context.getPackageName();

            Method checkOpMethod = appOpsClass.getMethod("checkOpNoThrow", int.class, int.class, String.class);
            int result = (int) checkOpMethod.invoke(appOps, op, uid, pkg);

            return result == 0; // MODE_ALLOWED = 0
        } catch (Exception e) {
            return false;
        }
    }

    // ==================== 锁屏显示权限 ====================

    /**
     * 检测锁屏显示权限是否开启
     * MIUI手机：通过AppOps检测op=10020（MIUI自定义锁屏显示权限）
     * 其他手机：检测通知渠道的lockscreenVisibility
     */
    public static boolean isLockScreenNotificationEnabled(Context context, String channelId) {
        if (WKOSUtils.isMiui()) {
            // MIUI：用AppOps op=10020 检测锁屏显示权限
            return checkAppOpsMode(context, 10020);
        }
        // 其他手机：检测通知渠道
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationManager manager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
            if (manager != null) {
                NotificationChannel channel = manager.getNotificationChannel(channelId);
                if (channel != null) {
                    int visibility = channel.getLockscreenVisibility();
                    return visibility == android.app.Notification.VISIBILITY_PUBLIC
                            || visibility == android.app.Notification.VISIBILITY_PRIVATE;
                }
            }
            return false;
        }
        return true;
    }

    /**
     * 跳转到锁屏显示权限设置页
     * 小米手机：跳转到权限管理页（用户在里面点"其他权限"→"锁屏显示"设置）
     * 注：更深的页面（OtherPermissionsActivity/PermissionAppsModifyActivity）不是公开的，第三方APP无法直接跳转
     * 其他手机：跳转到通知渠道设置页
     */
    public static void openLockScreenNotificationSetting(Context context, String channelId) {
        if (WKOSUtils.isMiui()) {
            // 小米：跳转到权限管理页（这是最深的公开页面）
            try {
                Intent intent = new Intent();
                intent.setComponent(new ComponentName(
                        "com.miui.securitycenter",
                        "com.miui.permcenter.permissions.PermissionsEditorActivity"));
                intent.putExtra("extra_pkgname", context.getPackageName());
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
                context.startActivity(intent);
                return;
            } catch (Exception e) {
                // fallback到下面
            }
        }

        // fallback：跳转通知渠道设置页
        ensureNotificationChannel(context, channelId, "新消息通知", NotificationManager.IMPORTANCE_HIGH);
        try {
            Intent intent = new Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS);
            intent.putExtra(Settings.EXTRA_APP_PACKAGE, context.getPackageName());
            intent.putExtra(Settings.EXTRA_CHANNEL_ID, channelId);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            context.startActivity(intent);
        } catch (Exception e) {
            openNotificationSetting(context);
        }
    }

    // ==================== 语音通知权限 ====================

    /**
     * 检测语音通知权限是否开启
     * 真实检测：通知总开关 + RTC渠道importance >= HIGH
     * 注意：检测时不创建渠道，渠道不存在返回false
     */
    public static boolean isVoiceNotificationEnabled(Context context, String rtcChannelId) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            // 先检查通知总开关
            if (!isNotificationEnabled(context)) {
                return false;
            }
            NotificationManager manager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
            if (manager != null) {
                NotificationChannel channel = manager.getNotificationChannel(rtcChannelId);
                if (channel != null) {
                    return channel.getImportance() >= NotificationManager.IMPORTANCE_HIGH;
                }
            }
            return false; // 渠道不存在，视为未开启
        }
        return true;
    }

    /**
     * 跳转到语音通知设置页
     */
    public static void openVoiceNotificationSetting(Context context, String rtcChannelId) {
        // 跳转前确保渠道存在
        ensureNotificationChannel(context, rtcChannelId, "语音通话通知", NotificationManager.IMPORTANCE_HIGH);
        try {
            Intent intent = new Intent(Settings.ACTION_CHANNEL_NOTIFICATION_SETTINGS);
            intent.putExtra(Settings.EXTRA_APP_PACKAGE, context.getPackageName());
            intent.putExtra(Settings.EXTRA_CHANNEL_ID, rtcChannelId);
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK);
            context.startActivity(intent);
        } catch (Exception e) {
            openNotificationSetting(context);
        }
    }

    // ==================== 综合检测 ====================

    public static boolean areAllPermissionsEnabled(Context context, String rtcChannelId) {
        return isNotificationEnabled(context)
                && isBatteryOptimizationIgnored(context)
                && isAutoStartEnabled(context)
                && isVoiceNotificationEnabled(context, rtcChannelId)
                && isLockScreenNotificationEnabled(context, WKConstants.newMsgChannelID);
    }
}
