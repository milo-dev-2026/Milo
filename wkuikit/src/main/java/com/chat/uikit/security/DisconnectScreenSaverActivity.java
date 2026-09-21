package com.chat.uikit.security;

import android.view.View;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKSharedPreferencesUtil;
import com.chat.base.utils.WKToastUtils;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActivityDisconnectScreenSaverBinding;

public class DisconnectScreenSaverActivity extends WKBaseActivity<ActivityDisconnectScreenSaverBinding> {

    private static final String KEY_DISCONNECT_PROTECTION = "disconnect_protection_enabled";
    private static final String KEY_DISCONNECT_SCREENSHOT_DISABLED = "disconnect_screenshot_disabled";

    @Override
    protected ActivityDisconnectScreenSaverBinding getViewBinding() {
        return ActivityDisconnectScreenSaverBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.disconnect_saver);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        boolean disconnectEnabled = WKSharedPreferencesUtil.getInstance().getBoolean(KEY_DISCONNECT_PROTECTION);
        wkVBinding.disconnectProtectionSwitch.setChecked(disconnectEnabled);

        boolean disconnectScreenshot = !WKSharedPreferencesUtil.getInstance().getBoolean(KEY_DISCONNECT_SCREENSHOT_DISABLED);
        wkVBinding.disconnectScreenshotSwitch.setChecked(disconnectScreenshot);
    }

    @Override
    protected void initListener() {
        wkVBinding.disconnectProtectionSwitch.setOnCheckedChangeListener((view, isChecked) -> {
            if (view.isPressed()) {
                WKSharedPreferencesUtil.getInstance().putBoolean(KEY_DISCONNECT_PROTECTION, isChecked);
                WKToastUtils.getInstance().showToastNormal(
                        isChecked ? "断连屏保已开启" : "断连屏保已关闭");
            }
        });

        wkVBinding.disconnectScreenshotSwitch.setOnCheckedChangeListener((view, isChecked) -> {
            if (view.isPressed()) {
                WKSharedPreferencesUtil.getInstance().putBoolean(KEY_DISCONNECT_SCREENSHOT_DISABLED, !isChecked);
                WKToastUtils.getInstance().showToastNormal(
                        isChecked ? "断连截屏已允许" : "断连截屏已禁止");
            }
        });
    }
}
