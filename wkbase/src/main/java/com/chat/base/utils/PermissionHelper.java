package com.chat.base.utils;

import android.app.Activity;
import android.app.AlertDialog;
import android.app.NotificationManager;
import android.content.ComponentName;
import android.content.Context;
import android.content.DialogInterface;
import android.content.Intent;
import android.net.Uri;
import android.os.Build;
import android.os.PowerManager;
import android.provider.Settings;
import android.text.TextUtils;

import androidx.core.app.NotificationManagerCompat;

import com.chat.base.utils.systembar.WKOSUtils;

import java.lang.reflect.Method;
import java.util.Collections;
import java.util.HashSet;
import java.util.Set;

/**
 * 权限检测工具类
 * 检测：通知权限、电池优化白名单、自启动权限
 */
public class PermissionHelper {

    /**
     * 检测通知权限是否开启
     */
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

    /**
     * 跳转到通知权限设置页
     */
    public static void openNotificationSetting(Context context) {
        context.getSharedPreferences("wkSharedPreferences", Context.MODE_PRIVATE)
                .edit()
                .putBoolean("permission_notification_opened", true)
                .apply();
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

    /**
     * 检测电池优化白名单（是否已忽略电池优化）
     * 优先用系统API检测，如果系统检测不到再用跳转标记
     */
    public static boolean isBatteryOptimizationIgnored(Context context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
            PowerManager pm = (PowerManager) context.getSystemService(Context.POWER_SERVICE);
            if (pm != null && pm.isIgnoringBatteryOptimizations(context.getPackageName())) {
                return true;
            }
            // 系统API未检测到，检查用户是否已跳转过设置页
            return context.getSharedPreferences("wkSharedPreferences", Context.MODE_PRIVATE)
                    .getBoolean("permission_battery_opened", false);
        }
        return true; // 6.0以下默认返回true
    }

    /**
     * 跳转到电池优化设置页
     */
    public static void openBatteryOptimizationSetting(Context context) {
        // 标记用户已跳转过电池优化设置页
        context.getSharedPreferences("wkSharedPreferences", Context.MODE_PRIVATE)
                .edit()
                .putBoolean("permission_battery_opened", true)
                .apply();
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

    /**
     * 检测自启动权限是否开启
     * 不同ROM检测方式不同，由于系统API限制，采用"用户已跳转过设置页"的标记方式
     * 一旦用户跳转过自启动设置页，即视为已开启
     */
    public static boolean isAutoStartEnabled(Context context) {
        // 自启动权限无法通过标准API可靠检测
        // 采用标记方式：用户跳转过设置页即视为已处理
        return context.getSharedPreferences("wkSharedPreferences", Context.MODE_PRIVATE)
                .getBoolean("permission_auto_start_opened", false);
    }

    /**
     * 跳转到自启动权限设置页
     */
    public static void openAutoStartSetting(Context context) {
        // 标记用户已跳转过自启动设置页
        context.getSharedPreferences("wkSharedPreferences", Context.MODE_PRIVATE)
                .edit()
                .putBoolean("permission_auto_start_opened", true)
                .apply();
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
                {"com.miui.securitycenter", "com.miui.permcenter.permissions.PermissionsEditorActivity"},
            };
            Intent miuiIntent = tryComponents(context, miuiTargets);
            if (miuiIntent != null) return miuiIntent;
        } else if (WKOSUtils.isEmui()) {
            String[][] huaweiTargets = {
                {"com.huawei.systemmanager", "com.huawei.systemmanager.startupmgr.StartupManagementActivity"},
                {"com.huawei.systemmanager", "com.huawei.systemmanager.optimize.process.ProtectActivity"},
                {"com.huawei.systemmanager", "com.huawei.systemmanager.appcontrol.HidingAppListActivity"},
            };
            Intent huaweiIntent = tryComponents(context, huaweiTargets);
            if (huaweiIntent != null) return huaweiIntent;
        } else if (WKOSUtils.isVivo()) {
            String[][] vivoTargets = {
                {"com.iqoo.secure", "com.iqoo.secure.ui.phoneoptimize.BgStartUpManager"},
                {"com.vivo.permissionmanager", "com.vivo.permissionmanager.activity.BgStartUpManagerActivity"},
                {"com.iqoo.secure", "com.iqoo.secure.safeguard.FakeTopActivity"},
            };
            Intent vivoIntent = tryComponents(context, vivoTargets);
            if (vivoIntent != null) return vivoIntent;
        } else if (WKOSUtils.isOppo()) {
            String[][] oppoTargets = {
                {"com.coloros.safecenter", "com.coloros.safecenter.permission.startup.StartupAppListActivity"},
                {"com.oplus.safecenter", "com.oplus.safecenter.permission.startup.StartupAppListActivity"},
                {"com.coloros.safecenter", "com.coloros.safecenter.startupapp.StartupAppListActivity"},
                {"com.oppo.safe", "com.oppo.safe.permission.startup.StartupAppListActivity"},
            };
            Intent oppoIntent = tryComponents(context, oppoTargets);
            if (oppoIntent != null) return oppoIntent;
        } else {
            String manufacturer = android.os.Build.MANUFACTURER.toLowerCase();
            if (manufacturer.contains("samsung")) {
                String[][] samsungTargets = {
                    {"com.samsung.android.sm", "com.samsung.android.sm.ui.battery.BatteryActivity"},
                    {"com.samsung.android.lool", "com.samsung.android.sm.ui.battery.BatteryActivity"},
                };
                Intent samsungIntent = tryComponents(context, samsungTargets);
                if (samsungIntent != null) return samsungIntent;
            } else if (manufacturer.contains("meizu")) {
                String[][] meizuTargets = {
                    {"com.meizu.safe", "com.meizu.safe.security.SHOW_APPSEC"},
                    {"com.meizu.privacy", "com.meizu.privacy.AppSecActivity"},
                };
                Intent meizuIntent = tryComponents(context, meizuTargets);
                if (meizuIntent != null) return meizuIntent;
            }
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

    // 小米自启动检测
    private static boolean isMiuiAutoStartEnabled(Context context) {
        try {
            // MIUI 9+ 通过AppOpsManager检测
            return checkAppOpsMode(context, 10001); // OP_BACKGROUND_START
        } catch (Exception e) {
            return true;
        }
    }

    // 华为自启动检测
    private static boolean isEmuiAutoStartEnabled(Context context) {
        try {
            return checkAppOpsMode(context, 10020); // OP_BOOT_BROADCAST
        } catch (Exception e) {
            return true;
        }
    }

    // Vivo自启动检测
    private static boolean isVivoAutoStartEnabled(Context context) {
        try {
            return checkAppOpsMode(context, 10001);
        } catch (Exception e) {
            return true;
        }
    }

    // OPPO自启动检测
    private static boolean isOppoAutoStartEnabled(Context context) {
        try {
            return checkAppOpsMode(context, 10001);
        } catch (Exception e) {
            return true;
        }
    }

    /**
     * 通过AppOpsManager检测权限状态
     * @param op 操作码
     * @return true表示允许
     */
    private static boolean checkAppOpsMode(Context context, int op) {
        try {
            Class<?> appOpsClass = Class.forName("android.app.AppOpsManager");
            Object appOps = context.getSystemService(Context.APP_OPS_SERVICE);
            if (appOps == null) return true;

            int uid = context.getApplicationInfo().uid;
            String pkg = context.getPackageName();

            // 尝试调用 checkOpNoThrow (int op, int uid, String packageName)
            Method checkOpMethod = appOpsClass.getMethod("checkOpNoThrow", int.class, int.class, String.class);
            int result = (int) checkOpMethod.invoke(appOps, op, uid, pkg);

            // MODE_ALLOWED = 0, MODE_IGNORED = 1, MODE_ERRORED = 2
            return result == 0;
        } catch (Exception e) {
            // 反射失败，默认返回true（不阻断用户流程）
            return true;
        }
    }

    /**
     * 检测语音通知渠道是否开启
     * 检查RTC通知渠道的importance是否为HIGH，如果渠道不存在或检测不到则用跳转标记
     */
    public static boolean isVoiceNotificationEnabled(Context context, String rtcChannelId) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            NotificationManager manager = (NotificationManager) context.getSystemService(Context.NOTIFICATION_SERVICE);
            if (manager != null) {
                android.app.NotificationChannel channel = manager.getNotificationChannel(rtcChannelId);
                if (channel != null) {
                    return channel.getImportance() >= NotificationManager.IMPORTANCE_HIGH;
                }
                // 渠道不存在，检查用户是否已跳转过设置页
                return context.getSharedPreferences("wkSharedPreferences", Context.MODE_PRIVATE)
                        .getBoolean("permission_voice_opened", false);
            }
            return false;
        }
        return true; // 8.0以下默认true
    }

    /**
     * 跳转到语音通知渠道设置页
     */
    public static void openVoiceNotificationSetting(Context context, String rtcChannelId) {
        context.getSharedPreferences("wkSharedPreferences", Context.MODE_PRIVATE)
                .edit()
                .putBoolean("permission_voice_opened", true)
                .apply();
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

    /**
     * 检测所有权限是否都已开启
     */
    public static boolean areAllPermissionsEnabled(Context context, String rtcChannelId) {
        return isNotificationEnabled(context)
                && isBatteryOptimizationIgnored(context)
                && isAutoStartEnabled(context)
                && isVoiceNotificationEnabled(context, rtcChannelId);
    }
}
