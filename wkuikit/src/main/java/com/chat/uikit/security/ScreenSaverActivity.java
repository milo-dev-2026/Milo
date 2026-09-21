package com.chat.uikit.security;

import android.view.View;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKSharedPreferencesUtil;
import com.chat.base.ui.components.SwitchView;
import com.chat.base.utils.WKToastUtils;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActivityScreenSaverBinding;

public class ScreenSaverActivity extends WKBaseActivity<ActivityScreenSaverBinding> {

    private static final String KEY_OFFLINE_PROTECTION = "offline_protection_enabled";
    private static final String KEY_SCREENSHOT_DISABLED = "screenshot_disabled";

    @Override
    protected ActivityScreenSaverBinding getViewBinding() {
        return ActivityScreenSaverBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.screen_saver);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        boolean offlineEnabled = WKSharedPreferencesUtil.getInstance().getBoolean(KEY_OFFLINE_PROTECTION);
        wkVBinding.offlineProtectionSwitch.setChecked(offlineEnabled);

        boolean screenshotAllowed = !WKSharedPreferencesUtil.getInstance().getBoolean(KEY_SCREENSHOT_DISABLED);
        wkVBinding.screenshotAllowedSwitch.setChecked(screenshotAllowed);
    }

    @Override
    protected void initListener() {
        wkVBinding.offlineProtectionSwitch.setOnCheckedChangeListener((view, isChecked) -> {
            if (view.isPressed()) {
                WKSharedPreferencesUtil.getInstance().putBoolean(KEY_OFFLINE_PROTECTION, isChecked);
                WKToastUtils.getInstance().showToastNormal(
                        isChecked ? "离线保护已开启" : "离线保护已关闭");
            }
        });

        wkVBinding.screenshotAllowedSwitch.setOnCheckedChangeListener((view, isChecked) -> {
            if (view.isPressed()) {
                WKSharedPreferencesUtil.getInstance().putBoolean(KEY_SCREENSHOT_DISABLED, !isChecked);
                WKToastUtils.getInstance().showToastNormal(
                        isChecked ? "已允许截屏" : "已禁止截屏");
            }
        });
    }
}
