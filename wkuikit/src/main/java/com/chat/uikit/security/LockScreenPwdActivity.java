package com.chat.uikit.security;

import android.content.Intent;
import android.view.View;
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
import com.chat.uikit.databinding.ActivityLockScreenPwdBinding;
import com.chat.uikit.security.service.SecurityModel;

public class LockScreenPwdActivity extends WKBaseActivity<ActivityLockScreenPwdBinding> {

    private static final String KEY_LOCK_SCREEN_ENABLED = "lock_screen_pwd_enabled";
    private static final String KEY_LOCK_SCREEN_PWD = "lock_screen_pwd";
    private static final String KEY_LOCK_AFTER_MINUTE = "lock_screen_auto_lock_time";

    private static final int[] LOCK_TIME_VALUES = {0, 1, 5, 30, 60};
    private static final String[] LOCK_TIME_LABELS = {"立即", "离开1分钟后", "离开5分钟后", "离开30分钟后", "离开1小时后"};

    @Override
    protected ActivityLockScreenPwdBinding getViewBinding() {
        return ActivityLockScreenPwdBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.lock_screen_password);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        updateAutoLockTimeUI();
    }

    @Override
    protected void onResume() {
        super.onResume();
        updateAutoLockTimeUI();
    }

    @Override
    protected void initListener() {
        SingleClickUtil.onSingleClick(wkVBinding.autoLockLayout, v -> {
            showAutoLockTimePicker();
        });

        SingleClickUtil.onSingleClick(wkVBinding.changePwdLayout, v -> {
            showChangePasswordDialog();
        });

        SingleClickUtil.onSingleClick(wkVBinding.closePwdLayout, v -> {
            showCloseConfirmDialog();
        });
    }

    private void updateAutoLockTimeUI() {
        int minute = WKSharedPreferencesUtil.getInstance().getInt(KEY_LOCK_AFTER_MINUTE, 0);
        String label = getLockTimeLabel(minute);
        wkVBinding.autoLockTimeTv.setText(label);
    }

    private String getLockTimeLabel(int minute) {
        for (int i = 0; i < LOCK_TIME_VALUES.length; i++) {
            if (LOCK_TIME_VALUES[i] == minute) {
                return LOCK_TIME_LABELS[i];
            }
        }
        return LOCK_TIME_LABELS[0];
    }

    private void showAutoLockTimePicker() {
        int current = WKSharedPreferencesUtil.getInstance().getInt(KEY_LOCK_AFTER_MINUTE, 0);
        int selectedIndex = 0;
        for (int i = 0; i < LOCK_TIME_VALUES.length; i++) {
            if (LOCK_TIME_VALUES[i] == current) {
                selectedIndex = i;
                break;
            }
        }
        final int finalSelectedIndex = selectedIndex;
        new android.app.AlertDialog.Builder(this)
                .setTitle("自动锁定")
                .setSingleChoiceItems(LOCK_TIME_LABELS, finalSelectedIndex, (dialog, which) -> {
                    int selectedValue = LOCK_TIME_VALUES[which];
                    updateAutoLockTime(selectedValue);
                    dialog.dismiss();
                })
                .show();
    }

    private void updateAutoLockTime(final int minute) {
        loadingPopup.show();
        SecurityModel.getInstance().updateLockAfterMinute(minute, (code, msg) -> {
            loadingPopup.dismiss();
            // 降级方案：无论后端是否成功，都本地保存
            WKSharedPreferencesUtil.getInstance().putInt(KEY_LOCK_AFTER_MINUTE, minute);
            updateAutoLockTimeUI();
            WKToastUtils.getInstance().showToastNormal("设置成功");
        });
    }

    private void showChangePasswordDialog() {
        WKDialogUtils.getInstance().showInputDialog(this, "验证旧密码",
                "请输入当前锁屏密码", "", "请输入密码", 6, oldInput -> {
                    if (oldInput != null && verifyLocalPwd(oldInput)) {
                        showSetNewPwdDialog();
                    } else {
                        WKToastUtils.getInstance().showToastNormal("旧密码不正确");
                    }
                });
    }

    private void showSetNewPwdDialog() {
        WKDialogUtils.getInstance().showInputDialog(this, "设置新密码",
                "请输入6位数字新密码", "", "请输入新密码", 6, newInput -> {
                    if (newInput != null && newInput.length() == 6 && newInput.matches("\\d+")) {
                        showConfirmNewPwdDialog(newInput);
                    } else {
                        WKToastUtils.getInstance().showToastNormal("密码需为6位数字");
                    }
                });
    }

    private void showConfirmNewPwdDialog(final String newPwd) {
        WKDialogUtils.getInstance().showInputDialog(this, "确认新密码",
                "请再次输入新密码", "", "请确认密码", 6, text -> {
                    if (text != null && text.equals(newPwd)) {
                        saveLockScreenPwd(newPwd);
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
            WKSharedPreferencesUtil.getInstance().putBoolean(KEY_LOCK_SCREEN_ENABLED, true);
            WKSharedPreferencesUtil.getInstance().putSP(KEY_LOCK_SCREEN_PWD, hashedPwd);
            if (code == HttpResponseCode.success) {
                WKToastUtils.getInstance().showToastNormal("密码修改成功");
            } else {
                WKToastUtils.getInstance().showToastNormal("密码修改成功（本地）");
            }
        });
    }

    private boolean verifyLocalPwd(String inputPwd) {
        String savedPwd = WKSharedPreferencesUtil.getInstance().getSP(KEY_LOCK_SCREEN_PWD);
        String uid = WKConfig.getInstance().getUid();
        String hashedInput = WKCommonUtils.digest(inputPwd + uid);
        // 兼容两种密码格式：新的 MD5(pwd+uid) 和旧的明文密码
        return hashedInput.equals(savedPwd) || inputPwd.equals(savedPwd);
    }

    private void showCloseConfirmDialog() {
        WKDialogUtils.getInstance().showDialog(this, "关闭锁屏密码",
                "关闭后，进入应用时将不再验证锁屏密码",
                true, "取消", "关闭锁屏密码", 0, 0, index -> {
                    if (index == 1) {
                        closeLockScreenPwd();
                    }
                });
    }

    private void closeLockScreenPwd() {
        loadingPopup.show();
        SecurityModel.getInstance().deleteLockScreenPwd((code, msg) -> {
            loadingPopup.dismiss();
            // 降级方案：无论后端是否成功，都本地关闭
            WKSharedPreferencesUtil.getInstance().putBoolean(KEY_LOCK_SCREEN_ENABLED, false);
            WKSharedPreferencesUtil.getInstance().putSP(KEY_LOCK_SCREEN_PWD, "");
            WKToastUtils.getInstance().showToastNormal("已关闭锁屏密码");
            // 重置应用锁定状态
            try {
                Class<?> appClass = Class.forName("com.xian.leihuhu.TSApplication");
                java.lang.reflect.Method getInstanceMethod = appClass.getMethod("getInstance");
                Object appInstance = getInstanceMethod.invoke(null);
                java.lang.reflect.Method setAppLockedMethod = appClass.getMethod("setAppLocked", boolean.class);
                setAppLockedMethod.invoke(appInstance, false);
            } catch (Exception e) {
                e.printStackTrace();
            }
            finish();
        });
    }
}
