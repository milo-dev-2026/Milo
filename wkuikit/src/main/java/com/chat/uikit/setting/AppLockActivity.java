package com.chat.uikit.setting;

import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKSharedPreferencesUtil;
import com.chat.base.utils.WKDialogUtils;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActAppLockLayoutBinding;

/**
 * 应用锁设置
 */
public class AppLockActivity extends WKBaseActivity<ActAppLockLayoutBinding> {

    private static final String SP_KEY_APP_LOCK = "app_lock_enabled";
    private static final String SP_KEY_AUTO_LOCK_TIME = "auto_lock_time";

    @Override
    protected ActAppLockLayoutBinding getViewBinding() {
        return ActAppLockLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.app_lock);
    }

    @Override
    protected void initPresenter() {
        int appLockValue = WKSharedPreferencesUtil.getInstance().getInt(SP_KEY_APP_LOCK, 0);
        boolean isAppLockEnabled = appLockValue == 1;
        wkVBinding.appLockSwitch.setChecked(isAppLockEnabled);
        updateLockSettingsVisibility(isAppLockEnabled);
    }

    @Override
    protected void initView() {
        int lockTime = WKSharedPreferencesUtil.getInstance().getInt(SP_KEY_AUTO_LOCK_TIME, 0);
        updateAutoLockTimeText(lockTime);
    }

    @Override
    protected void initListener() {
        wkVBinding.appLockSwitch.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (buttonView.isPressed()) {
                WKSharedPreferencesUtil.getInstance().putInt(SP_KEY_APP_LOCK, isChecked ? 1 : 0);
                updateLockSettingsVisibility(isChecked);
                WKToastUtils.getInstance().showToastNormal(isChecked ? getString(R.string.app_lock_enabled) : getString(R.string.app_lock_disabled));
            }
        });
        SingleClickUtil.onSingleClick(wkVBinding.changePwdLayout, v -> {
            WKDialogUtils.getInstance().showInputDialog(this, "设置应用锁密码",
                    "请输入4-6位数字密码", "", "请输入密码", 6, text -> {
                        if (text != null && text.length() >= 4 && text.length() <= 6 && text.matches("\\d+")) {
                            WKSharedPreferencesUtil.getInstance().putSP("app_lock_pwd", text);
                            WKToastUtils.getInstance().showToastNormal("密码设置成功");
                        } else {
                            WKToastUtils.getInstance().showToastNormal("密码需为4-6位数字");
                        }
                    });
        });
        SingleClickUtil.onSingleClick(wkVBinding.autoLockLayout, v -> {
            String[] items = {getString(R.string.immediately), "1分钟", "5分钟", "10分钟", "30分钟"};
            int[] values = {0, 1, 5, 10, 30};
            int current = WKSharedPreferencesUtil.getInstance().getInt(SP_KEY_AUTO_LOCK_TIME, 0);
            int selectedIndex = 0;
            for (int i = 0; i < values.length; i++) {
                if (values[i] == current) {
                    selectedIndex = i;
                    break;
                }
            }
            new android.app.AlertDialog.Builder(this)
                    .setTitle("自动锁屏时间")
                    .setSingleChoiceItems(items, selectedIndex, (dialog, which) -> {
                        WKSharedPreferencesUtil.getInstance().putInt(SP_KEY_AUTO_LOCK_TIME, values[which]);
                        updateAutoLockTimeText(values[which]);
                        dialog.dismiss();
                    })
                    .show();
        });
    }

    private void updateLockSettingsVisibility(boolean enabled) {
        if (enabled) {
            wkVBinding.changePwdLayout.setVisibility(android.view.View.VISIBLE);
            wkVBinding.autoLockLayout.setVisibility(android.view.View.VISIBLE);
        } else {
            wkVBinding.changePwdLayout.setVisibility(android.view.View.GONE);
            wkVBinding.autoLockLayout.setVisibility(android.view.View.GONE);
        }
    }

    private void updateAutoLockTimeText(int time) {
        String timeText;
        switch (time) {
            case 0:
                timeText = getString(R.string.immediately);
                break;
            case 1:
                timeText = "1分钟";
                break;
            case 5:
                timeText = "5分钟";
                break;
            case 10:
                timeText = "10分钟";
                break;
            case 30:
                timeText = "30分钟";
                break;
            default:
                timeText = getString(R.string.immediately);
                break;
        }
        wkVBinding.autoLockTimeTv.setText(timeText);
    }
}
