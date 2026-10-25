package com.xian.leihuhu;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.os.Handler;
import android.os.Looper;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.WindowManager;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import com.chat.base.config.WKConstants;
import com.chat.base.utils.PermissionHelper;
import com.chat.base.utils.systembar.WKOSUtils;

/**
 * 权限引导弹窗 Activity
 * 首次安装/更新后弹出，引导用户开启5项权限
 * 全部采用系统API真实检测，无弹窗确认
 */
public class PermissionGuideActivity extends Activity {

    private static final String TAG = "PermissionGuide";
    private static final String SP_KEY_PERMISSION_GUIDE_SHOWN_PREFIX = "permission_guide_shown_version_";

    private View rootView;
    private ImageView iconAutoStart, iconBattery, iconNotification, iconVoice, iconLockScreen;
    private TextView btnAutoStart, btnBattery, btnNotification, btnVoice, btnLockScreen, btnEnter;
    private TextView tvSelectAllHint;

    private boolean isAutoStartEnabled = false;
    private boolean isAutoStartUndetectable = false;
    private boolean isBatteryEnabled = false;
    private boolean isNotificationEnabled = false;
    private boolean isVoiceEnabled = false;
    private boolean isLockScreenEnabled = false;

    private Handler mHandler;
    // 跳转标记（用于延迟检测，AppOps和系统权限状态更新有延迟）
    private boolean justOpenedBatterySetting = false;
    private boolean justOpenedAutoStartSetting = false;
    private boolean justOpenedLockScreenSetting = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        mHandler = new Handler(Looper.getMainLooper());
        setupWindow();
        rootView = LayoutInflater.from(this).inflate(R.layout.dialog_permission_guide, null);
        setContentView(rootView);
        initViews();
        isAutoStartUndetectable = PermissionHelper.isAutoStartUndetectable(this);
        checkAllPermissions();
    }

    private void setupWindow() {
        getWindow().setBackgroundDrawableResource(android.R.color.transparent);
        WindowManager.LayoutParams params = getWindow().getAttributes();
        params.dimAmount = 0.5f;
        params.flags |= WindowManager.LayoutParams.FLAG_DIM_BEHIND;
        getWindow().setAttributes(params);
        setFinishOnTouchOutside(false);
    }

    private void initViews() {
        iconAutoStart = rootView.findViewById(R.id.icon_auto_start);
        iconBattery = rootView.findViewById(R.id.icon_battery);
        iconNotification = rootView.findViewById(R.id.icon_notification);
        iconVoice = rootView.findViewById(R.id.icon_voice);
        iconLockScreen = rootView.findViewById(R.id.icon_lock_screen);
        btnAutoStart = rootView.findViewById(R.id.btn_auto_start);
        btnBattery = rootView.findViewById(R.id.btn_battery);
        btnNotification = rootView.findViewById(R.id.btn_notification);
        btnVoice = rootView.findViewById(R.id.btn_voice);
        btnLockScreen = rootView.findViewById(R.id.btn_lock_screen);
        btnEnter = rootView.findViewById(R.id.btn_enter);
        tvSelectAllHint = rootView.findViewById(R.id.tv_select_all_hint);

        // 非小米手机：隐藏语音通知和锁屏显示，只显示3项核心权限
        if (!WKOSUtils.isMiui()) {
            rootView.findViewById(R.id.item_voice).setVisibility(View.GONE);
            rootView.findViewById(R.id.item_lock_screen).setVisibility(View.GONE);
            isVoiceEnabled = true; // 非小米不需要检测，视为已开启
            isLockScreenEnabled = true;
        }

        rootView.findViewById(R.id.item_auto_start).setOnClickListener(v -> {
            if (!isAutoStartEnabled || isAutoStartUndetectable) {
                justOpenedAutoStartSetting = true;
                PermissionHelper.openAutoStartSetting(PermissionGuideActivity.this);
            }
        });
        rootView.findViewById(R.id.item_battery).setOnClickListener(v -> {
            if (!isBatteryEnabled) {
                justOpenedBatterySetting = true;
                PermissionHelper.openBatteryOptimizationSetting(PermissionGuideActivity.this);
            }
        });
        rootView.findViewById(R.id.item_notification).setOnClickListener(v -> {
            if (!isNotificationEnabled) {
                PermissionHelper.openNotificationSetting(PermissionGuideActivity.this);
            }
        });
        rootView.findViewById(R.id.item_voice).setOnClickListener(v -> {
            if (!isVoiceEnabled) {
                PermissionHelper.openVoiceNotificationSetting(PermissionGuideActivity.this,
                        WKConstants.newRTCChannelID);
            }
        });
        rootView.findViewById(R.id.item_lock_screen).setOnClickListener(v -> {
            if (!isLockScreenEnabled) {
                justOpenedLockScreenSetting = true;
                PermissionHelper.openLockScreenNotificationSetting(PermissionGuideActivity.this,
                        WKConstants.newMsgChannelID);
            }
        });

        btnEnter.setOnClickListener(v -> {
            if ((isAutoStartEnabled || isAutoStartUndetectable) && isBatteryEnabled && isNotificationEnabled && isVoiceEnabled && isLockScreenEnabled) {
                markGuideShown(this);
                finish();
            } else {
                Toast.makeText(this, "请先开启全部权限", Toast.LENGTH_SHORT).show();
            }
        });
    }

    @Override
    public void onBackPressed() {
        // 禁止返回，必须开启全部权限才能进入APP
        Toast.makeText(this, "请先开启全部权限", Toast.LENGTH_SHORT).show();
    }

    @Override
    protected void onResume() {
        super.onResume();
        checkAllPermissions();

        // 系统权限状态更新有延迟，跳转过设置页的延迟1秒再检测一次
        boolean needDelayCheck = justOpenedBatterySetting || justOpenedAutoStartSetting || justOpenedLockScreenSetting;
        justOpenedBatterySetting = false;
        justOpenedAutoStartSetting = false;
        justOpenedLockScreenSetting = false;

        if (needDelayCheck) {
            mHandler.postDelayed(() -> {
                checkAllPermissions();
            }, 1000);
        }
    }

    private void checkAllPermissions() {
        isAutoStartEnabled = PermissionHelper.isAutoStartEnabled(this);
        isBatteryEnabled = PermissionHelper.isBatteryOptimizationIgnored(this);
        isNotificationEnabled = PermissionHelper.isNotificationEnabled(this);
        isVoiceEnabled = PermissionHelper.isVoiceNotificationEnabled(this, WKConstants.newRTCChannelID);
        isLockScreenEnabled = PermissionHelper.isLockScreenNotificationEnabled(this, WKConstants.newMsgChannelID);

        Log.e(TAG, "权限检测: autoStart=" + isAutoStartEnabled
                + " battery=" + isBatteryEnabled
                + " notification=" + isNotificationEnabled
                + " voice=" + isVoiceEnabled
                + " lockScreen=" + isLockScreenEnabled);

        if (isAutoStartUndetectable) {
            // vivo/OPPO 检测不到自启动真实状态，显示中性提示，不误导为“未开启”，也不阻断进入
            iconAutoStart.setImageResource(R.drawable.ic_permission_unchecked);
            btnAutoStart.setText("请确认已开启");
            btnAutoStart.setTextColor(0xFF999999);
            btnAutoStart.setBackgroundResource(R.drawable.bg_permission_btn_gray);
            btnAutoStart.setEnabled(true);
        } else {
            updateItemState(iconAutoStart, btnAutoStart, isAutoStartEnabled);
        }
        updateItemState(iconBattery, btnBattery, isBatteryEnabled);
        updateItemState(iconNotification, btnNotification, isNotificationEnabled);
        updateItemState(iconVoice, btnVoice, isVoiceEnabled);
        updateItemState(iconLockScreen, btnLockScreen, isLockScreenEnabled);

        boolean allEnabled = (isAutoStartEnabled || isAutoStartUndetectable) && isBatteryEnabled && isNotificationEnabled && isVoiceEnabled && isLockScreenEnabled;
        if (allEnabled) {
            btnEnter.setBackgroundResource(R.drawable.bg_permission_btn_blue);
            btnEnter.setTextColor(0xFFFFFFFF);
            tvSelectAllHint.setText("所有权限已开启");
            tvSelectAllHint.setTextColor(0xFF3F74FC);
        } else {
            btnEnter.setBackgroundResource(R.drawable.bg_permission_btn_disabled);
            btnEnter.setTextColor(0xFFB4B6BD);
            tvSelectAllHint.setText("请开启以上全部权限");
            tvSelectAllHint.setTextColor(0xFFB4B6BD);
        }
    }

    private void updateItemState(ImageView icon, TextView btn, boolean enabled) {
        if (enabled) {
            icon.setImageResource(R.drawable.ic_permission_checked);
            btn.setText("已开启");
            btn.setTextColor(0xFF999999);
            btn.setBackgroundResource(R.drawable.bg_permission_btn_gray);
            btn.setEnabled(false);
        } else {
            icon.setImageResource(R.drawable.ic_permission_unchecked);
            btn.setText("开启");
            btn.setTextColor(0xFFFFFFFF);
            btn.setBackgroundResource(R.drawable.bg_permission_btn_blue);
            btn.setEnabled(true);
        }
    }

    /**
     * 检查是否需要显示权限引导弹窗
     */
    public static boolean shouldShowGuide(Context context) {
        String currentVersion = getAppVersion(context);
        String shownVersion = context.getSharedPreferences("wkSharedPreferences", Context.MODE_PRIVATE)
                .getString(SP_KEY_PERMISSION_GUIDE_SHOWN_PREFIX + currentVersion, "");

        if (shownVersion.isEmpty()) {
            boolean allEnabled;
            if (WKOSUtils.isMiui()) {
                // 小米：检测5项权限
                allEnabled = PermissionHelper.isNotificationEnabled(context)
                        && PermissionHelper.isBatteryOptimizationIgnored(context)
                        && PermissionHelper.isAutoStartEnabled(context)
                        && PermissionHelper.isVoiceNotificationEnabled(context, WKConstants.newRTCChannelID)
                        && PermissionHelper.isLockScreenNotificationEnabled(context, WKConstants.newMsgChannelID);
            } else {
                // 其他品牌：只检测3项核心权限（vivo/OPPO 自启动无法检测，不参与判断）
                allEnabled = PermissionHelper.isNotificationEnabled(context)
                        && PermissionHelper.isBatteryOptimizationIgnored(context)
                        && (PermissionHelper.isAutoStartUndetectable(context) || PermissionHelper.isAutoStartEnabled(context));
            }
            return !allEnabled;
        }
        return false;
    }

    public static void markGuideShown(Context context) {
        String currentVersion = getAppVersion(context);
        context.getSharedPreferences("wkSharedPreferences", Context.MODE_PRIVATE)
                .edit()
                .putString(SP_KEY_PERMISSION_GUIDE_SHOWN_PREFIX + currentVersion, currentVersion)
                .apply();
    }

    private static String getAppVersion(Context context) {
        try {
            return context.getPackageManager()
                    .getPackageInfo(context.getPackageName(), 0).versionName;
        } catch (Exception e) {
            return "unknown";
        }
    }
}
