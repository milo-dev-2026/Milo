package com.chat.uikit.security;

import android.content.Intent;
import android.view.View;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKSharedPreferencesUtil;
import com.chat.base.ui.components.SwitchView;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActivitySecurityPrivacyBinding;
import com.chat.uikit.user.BlacklistActivity;

public class SecurityPrivacyActivity extends WKBaseActivity<ActivitySecurityPrivacyBinding> {

    private static final String KEY_SCREENSHOT_PROTECTION = "screenshot_protection";
    private static final String KEY_CHAT_PWD = "chat_pwd";
    private static final String KEY_LOCK_SCREEN_PWD = "lock_screen_pwd";

    @Override
    protected ActivitySecurityPrivacyBinding getViewBinding() {
        return ActivitySecurityPrivacyBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.security_privacy);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        boolean screenshotEnabled = WKSharedPreferencesUtil.getInstance().getBoolean(KEY_SCREENSHOT_PROTECTION);
        wkVBinding.screenshotSwitch.setChecked(screenshotEnabled);
        refreshPwdStatus();
    }

    @Override
    protected void onResume() {
        super.onResume();
        refreshPwdStatus();
    }

    private void refreshPwdStatus() {
        String chatPwd = WKSharedPreferencesUtil.getInstance().getSP(KEY_CHAT_PWD);
        if (chatPwd != null && chatPwd.length() > 0) {
            wkVBinding.chatPwdStatusTv.setText(R.string.already_set);
        } else {
            wkVBinding.chatPwdStatusTv.setText(R.string.unsetting);
        }

        String lockScreenPwd = WKSharedPreferencesUtil.getInstance().getSP(KEY_LOCK_SCREEN_PWD);
        if (lockScreenPwd != null && lockScreenPwd.length() > 0) {
            wkVBinding.lockScreenPwdStatusTv.setText(R.string.already_set);
        } else {
            wkVBinding.lockScreenPwdStatusTv.setText(R.string.unsetting);
        }
    }

    @Override
    protected void initListener() {
        SingleClickUtil.onSingleClick(wkVBinding.msgPrivacyLayout, v -> {
            startActivity(new Intent(this, MessagePrivacyActivity.class));
        });

        SingleClickUtil.onSingleClick(wkVBinding.chatPwdLayout, v -> {
            startActivity(new Intent(this, ChatPasswordActivity.class));
        });

        SingleClickUtil.onSingleClick(wkVBinding.lockScreenPwdLayout, v -> {
            startActivity(new Intent(this, LockScreenPwdActivity.class));
        });

        SingleClickUtil.onSingleClick(wkVBinding.blacklistLayout, v -> {
            startActivity(new Intent(this, BlacklistActivity.class));
        });

        wkVBinding.screenshotSwitch.setOnCheckedChangeListener((view, isChecked) -> {
            if (view.isPressed()) {
                WKSharedPreferencesUtil.getInstance().putBoolean(KEY_SCREENSHOT_PROTECTION, isChecked);
                WKToastUtils.getInstance().showToastNormal(
                        isChecked ? "已开启截屏保护" : "已关闭截屏保护");
            }
        });

        SingleClickUtil.onSingleClick(wkVBinding.screenSaverLayout, v -> {
            startActivity(new Intent(this, ScreenSaverActivity.class));
        });

        SingleClickUtil.onSingleClick(wkVBinding.disconnectSaverLayout, v -> {
            startActivity(new Intent(this, DisconnectScreenSaverActivity.class));
        });
    }
}
