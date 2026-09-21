package com.chat.uikit.security;

import android.content.Intent;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKConfig;
import com.chat.base.config.WKSharedPreferencesUtil;
import com.chat.base.net.HttpResponseCode;
import com.chat.base.utils.WKCommonUtils;
import com.chat.base.utils.WKDialogUtils;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActivityPwdManagerBinding;
import com.chat.uikit.security.service.SecurityModel;

public class PwdManagerActivity extends WKBaseActivity<ActivityPwdManagerBinding> {

    private static final String KEY_CHAT_PWD = "chat_pwd";
    private static final String KEY_LOCK_SCREEN_PWD = "lock_screen_pwd";

    @Override
    protected ActivityPwdManagerBinding getViewBinding() {
        return ActivityPwdManagerBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.pwd_management);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        refreshPasswordStatus();
    }

    @Override
    protected void onResume() {
        super.onResume();
        refreshPasswordStatus();
    }

    private void refreshPasswordStatus() {
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
        SingleClickUtil.onSingleClick(wkVBinding.loginPwdLayout, v ->
                startActivity(new Intent(this, LoginPasswordActivity.class)));

        SingleClickUtil.onSingleClick(wkVBinding.chatPwdLayout, v ->
                startActivity(new Intent(this, ChatPasswordActivity.class)));

        SingleClickUtil.onSingleClick(wkVBinding.lockScreenPwdLayout, v -> {
            String pwd = WKSharedPreferencesUtil.getInstance().getSP(KEY_LOCK_SCREEN_PWD);
            boolean hasPwd = pwd != null && pwd.length() > 0;
            if (hasPwd) {
                // 已设置 → 先验证密码，再进入详情页
                startActivity(new Intent(this, LockScreenVerifyInputActivity.class));
            } else {
                // 未设置 → 弹出设置密码
                showSetLockScreenPwdDialog();
            }
        });
    }

    private void showSetLockScreenPwdDialog() {
        WKDialogUtils.getInstance().showInputDialog(this, "设置锁屏密码",
                "请输入6位数字密码", "", "请输入密码", 6, text -> {
                    if (text != null && text.length() == 6 && text.matches("\\d+")) {
                        showConfirmPwdDialog(text);
                    } else {
                        WKToastUtils.getInstance().showToastNormal("密码需为6位数字");
                    }
                });
    }

    private void showConfirmPwdDialog(final String firstPwd) {
        WKDialogUtils.getInstance().showInputDialog(this, "确认密码",
                "请再次输入密码", "", "请确认密码", 6, text -> {
                    if (text != null && text.equals(firstPwd)) {
                        saveLockScreenPwd(text);
                    } else {
                        WKToastUtils.getInstance().showToastNormal("两次密码不一致");
                    }
                });
    }

    private void saveLockScreenPwd(String pwd) {
        String uid = WKConfig.getInstance().getUid();
        final String hashedPwd = WKCommonUtils.digest(pwd + uid);

        loadingPopup.show();
        SecurityModel.getInstance().setLockScreenPwd(hashedPwd, (code, msg) -> {
            loadingPopup.dismiss();
            // 降级方案：无论后端是否成功，都本地保存
            WKSharedPreferencesUtil.getInstance().putBoolean("lock_screen_pwd_enabled", true);
            WKSharedPreferencesUtil.getInstance().putSP(KEY_LOCK_SCREEN_PWD, hashedPwd);
            refreshPasswordStatus();
            if (code == HttpResponseCode.success) {
                WKToastUtils.getInstance().showToastNormal("锁屏密码设置成功");
            } else {
                WKToastUtils.getInstance().showToastNormal("锁屏密码设置成功（本地）");
            }
            // 设置成功后跳转到详情页
            startActivity(new Intent(this, LockScreenPwdActivity.class));
        });
    }
}
