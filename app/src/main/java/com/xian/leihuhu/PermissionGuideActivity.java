package com.xian.leihuhu;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.os.Bundle;
import android.util.Log;
import android.view.LayoutInflater;
import android.view.View;
import android.view.WindowManager;
import android.widget.ImageView;
import android.widget.TextView;
import android.widget.Toast;

import com.chat.base.config.WKConstants;
import com.chat.base.utils.PermissionHelper;

/**
 * 权限引导弹窗 Activity
 * 首次安装/更新后弹出，引导用户开启4项权限
 * 乳白色透明毛玻璃效果
 */
public class PermissionGuideActivity extends Activity {

    private static final String TAG = "PermissionGuide";
    private static final String SP_KEY_PERMISSION_GUIDE_SHOWN_PREFIX = "permission_guide_shown_version_";
    private static final String SP_KEY_AUTO_START_OPENED = "permission_auto_start_opened_";

    private View rootView;
    private ImageView iconAutoStart, iconBattery, iconNotification, iconVoice;
    private TextView btnAutoStart, btnBattery, btnNotification, btnVoice, btnEnter;
    private TextView tvSelectAllHint;

    private boolean isAutoStartEnabled = false;
    private boolean isBatteryEnabled = false;
    private boolean isNotificationEnabled = false;
    private boolean isVoiceEnabled = false;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setupWindow();
        rootView = LayoutInflater.from(this).inflate(R.layout.dialog_permission_guide, null);
        setContentView(rootView);
        initViews();
        checkAllPermissions();
    }

    private void setupWindow() {
        getWindow().setBackgroundDrawableResource(android.R.color.transparent);
        // 不使用 FLAG_LAYOUT_NO_LIMITS，避免内容被状态栏覆盖
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
        btnAutoStart = rootView.findViewById(R.id.btn_auto_start);
        btnBattery = rootView.findViewById(R.id.btn_battery);
        btnNotification = rootView.findViewById(R.id.btn_notification);
        btnVoice = rootView.findViewById(R.id.btn_voice);
        btnEnter = rootView.findViewById(R.id.btn_enter);
        tvSelectAllHint = rootView.findViewById(R.id.tv_select_all_hint);

        rootView.findViewById(R.id.item_auto_start).setOnClickListener(v -> {
            if (!isAutoStartEnabled) {
                PermissionHelper.openAutoStartSetting(PermissionGuideActivity.this);
            }
        });
        rootView.findViewById(R.id.item_battery).setOnClickListener(v -> {
            if (!isBatteryEnabled) {
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

        btnEnter.setOnClickListener(v -> {
            if (isAutoStartEnabled && isBatteryEnabled && isNotificationEnabled && isVoiceEnabled) {
                markGuideShown(this);
                Intent intent = new Intent(this, com.chat.uikit.TabActivity.class);
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK | Intent.FLAG_ACTIVITY_CLEAR_TASK);
                startActivity(intent);
                finish();
            } else {
                Toast.makeText(this, "请先开启全部权限", Toast.LENGTH_SHORT).show();
            }
        });
    }

    @Override
    protected void onResume() {
        super.onResume();
        checkAllPermissions();
    }

    private void checkAllPermissions() {
        isAutoStartEnabled = PermissionHelper.isAutoStartEnabled(this);
        isBatteryEnabled = PermissionHelper.isBatteryOptimizationIgnored(this);
        isNotificationEnabled = PermissionHelper.isNotificationEnabled(this);
        isVoiceEnabled = PermissionHelper.isVoiceNotificationEnabled(this, WKConstants.newRTCChannelID);

        Log.e(TAG, "权限检测: autoStart=" + isAutoStartEnabled
                + " battery=" + isBatteryEnabled
                + " notification=" + isNotificationEnabled
                + " voice=" + isVoiceEnabled);

        updateItemState(iconAutoStart, btnAutoStart, isAutoStartEnabled);
        updateItemState(iconBattery, btnBattery, isBatteryEnabled);
        updateItemState(iconNotification, btnNotification, isNotificationEnabled);
        updateItemState(iconVoice, btnVoice, isVoiceEnabled);

        boolean allEnabled = isAutoStartEnabled && isBatteryEnabled && isNotificationEnabled && isVoiceEnabled;
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
     * 在首次安装或更新版本后显示，如所有权限已开启则不显示
     */
    public static boolean shouldShowGuide(Context context) {
        String currentVersion = getAppVersion(context);
        String shownVersion = context.getSharedPreferences("wkSharedPreferences", Context.MODE_PRIVATE)
                .getString(SP_KEY_PERMISSION_GUIDE_SHOWN_PREFIX + currentVersion, "");

        if (shownVersion.isEmpty()) {
            boolean allEnabled = PermissionHelper.isNotificationEnabled(context)
                    && PermissionHelper.isBatteryOptimizationIgnored(context)
                    && PermissionHelper.isAutoStartEnabled(context)
                    && PermissionHelper.isVoiceNotificationEnabled(context, WKConstants.newRTCChannelID);
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
