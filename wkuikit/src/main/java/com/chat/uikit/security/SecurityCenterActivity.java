package com.chat.uikit.security;

import android.content.Intent;
import android.view.View;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKConfig;
import com.chat.base.config.WKSharedPreferencesUtil;
import com.chat.base.ui.components.SwitchView;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActivitySecurityCenterBinding;
import com.chat.uikit.user.BlacklistActivity;

/**
 * 2024-08-31
 * 安全中心页面
 */
public class SecurityCenterActivity extends WKBaseActivity<ActivitySecurityCenterBinding> {

    private static final String KEY_SCREENSHOT_PROTECTION = "screenshot_protection";

    @Override
    protected ActivitySecurityCenterBinding getViewBinding() {
        return ActivitySecurityCenterBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.security_center);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        // 初始化截屏保护开关
        boolean screenshotEnabled = WKSharedPreferencesUtil.getInstance().getBoolean(KEY_SCREENSHOT_PROTECTION);
        wkVBinding.screenshotSwitchView.setChecked(screenshotEnabled);

        // 显示绑定状态
        String phone = WKSharedPreferencesUtil.getInstance().getSP("bind_phone");
        if (phone == null || phone.isEmpty()) {
            if (WKConfig.getInstance().getUserInfo() != null) {
                phone = WKConfig.getInstance().getUserInfo().phone;
            }
        }
        if (phone != null && !phone.isEmpty()) {
            wkVBinding.phoneStatusTv.setText(phone.substring(0, 3) + "****" + phone.substring(phone.length() - 4));
        }

        String email = WKSharedPreferencesUtil.getInstance().getSP("bind_email");
        if (email != null && !email.isEmpty()) {
            int atIndex = email.indexOf("@");
            if (atIndex > 2) {
                wkVBinding.emailStatusTv.setText(email.substring(0, 2) + "***" + email.substring(atIndex));
            }
        }

        // 显示锁屏密码状态
        boolean lockScreenEnabled = WKSharedPreferencesUtil.getInstance().getBoolean("lock_screen_pwd_enabled");
        if (lockScreenEnabled) {
            wkVBinding.lockScreenPwdStatusTv.setText("已设置");
        }

        // 显示聊天密码状态
        boolean chatPwdEnabled = WKSharedPreferencesUtil.getInstance().getBoolean("chat_password_enabled");
        if (chatPwdEnabled) {
            wkVBinding.chatPwdStatusTv.setText("已设置");
        }
    }

    @Override
    protected void initListener() {
        // 安全账号主页
        SingleClickUtil.onSingleClick(wkVBinding.securityAccountLayout, v -> {
            startActivity(new Intent(this, SecurityAccountActivity.class));
        });

        // 修改密码 — 需先验证身份
        SingleClickUtil.onSingleClick(wkVBinding.changePwdLayout, v -> {
            startActivity(new Intent(this, VertifyPwdActivity.class));
        });

        // 绑定手机 — 需先验证身份
        SingleClickUtil.onSingleClick(wkVBinding.bindPhoneLayout, v -> {
            Intent intent = new Intent(this, VertifyPwdActivity.class);
            intent.putExtra(VertifyPwdActivity.EXTRA_TARGET, VertifyPwdActivity.TARGET_BIND_PHONE);
            startActivity(intent);
        });

        // 绑定邮箱 — 需先验证身份
        SingleClickUtil.onSingleClick(wkVBinding.bindEmailLayout, v -> {
            Intent intent = new Intent(this, VertifyPwdActivity.class);
            intent.putExtra(VertifyPwdActivity.EXTRA_TARGET, VertifyPwdActivity.TARGET_BIND_EMAIL);
            startActivity(intent);
        });

        // 设备管理
        SingleClickUtil.onSingleClick(wkVBinding.deviceManageLayout, v -> {
            startActivity(new Intent(this, DeviceManageActivity.class));
        });

        // 消息隐私
        SingleClickUtil.onSingleClick(wkVBinding.msgPrivacyLayout, v -> {
            startActivity(new Intent(this, SecurityPrivacyActivity.class));
        });

        // 聊天密码
        SingleClickUtil.onSingleClick(wkVBinding.chatPwdLayout, v -> {
            startActivity(new Intent(this, PwdManagerActivity.class));
        });

        // 锁屏密码
        SingleClickUtil.onSingleClick(wkVBinding.lockScreenPwdLayout, v -> {
            startActivity(new Intent(this, PwdManagerActivity.class));
        });

        // 黑名单
        SingleClickUtil.onSingleClick(wkVBinding.blacklistLayout, v -> {
            startActivity(new Intent(this, BlacklistActivity.class));
        });

        // 截屏保护开关
        wkVBinding.screenshotSwitchView.setOnCheckedChangeListener(new SwitchView.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(View view, boolean isChecked) {
                WKSharedPreferencesUtil.getInstance().putBoolean(KEY_SCREENSHOT_PROTECTION, isChecked);
                if (isChecked) {
                    WKToastUtils.getInstance().showToastNormal("已开启截屏保护");
                } else {
                    WKToastUtils.getInstance().showToastNormal("已关闭截屏保护");
                }
            }
        });

        // 注销账号
        SingleClickUtil.onSingleClick(wkVBinding.destroyAccountLayout, v -> {
            startActivity(new Intent(this, DestroyAccountActivity.class));
        });
    }
}
