package com.chat.uikit.security;

import android.view.View;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKSharedPreferencesUtil;
import com.chat.base.utils.WKDialogUtils;
import com.chat.base.utils.WKToastUtils;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActivityCheckLockScreenPwdBinding;

public class CheckLockScreenPwdActivity extends WKBaseActivity<ActivityCheckLockScreenPwdBinding> {

    public static final int MAX_PASSWORD_ATTEMPTS = 5;

    private static final String KEY_LOCK_SCREEN_PWD = "lock_screen_pwd";
    private static final String KEY_PWD_ATTEMPTS = "lock_screen_pwd_attempts";

    private StringBuilder inputBuilder = new StringBuilder();
    private int remainingAttempts = MAX_PASSWORD_ATTEMPTS;

    private final int[] dotIds = {
            R.id.dot1, R.id.dot2, R.id.dot3, R.id.dot4, R.id.dot5, R.id.dot6
    };
    private final int[] btnIds = {
            R.id.btn0, R.id.btn1, R.id.btn2, R.id.btn3, R.id.btn4,
            R.id.btn5, R.id.btn6, R.id.btn7, R.id.btn8, R.id.btn9
    };

    @Override
    protected ActivityCheckLockScreenPwdBinding getViewBinding() {
        return ActivityCheckLockScreenPwdBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.check_lock_screen_pwd);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        remainingAttempts = WKSharedPreferencesUtil.getInstance().getInt(KEY_PWD_ATTEMPTS, MAX_PASSWORD_ATTEMPTS);
        if (remainingAttempts < MAX_PASSWORD_ATTEMPTS) {
            wkVBinding.attemptsTv.setVisibility(View.VISIBLE);
            wkVBinding.attemptsTv.setText(String.format(getString(R.string.remaining_attempts), remainingAttempts));
        }
        updateDots();
        setupNumberPad();
    }

    private void setupNumberPad() {
        for (int i = 0; i < btnIds.length; i++) {
            final int digit = i;
            findViewById(btnIds[i]).setOnClickListener(v -> appendDigit(digit));
        }
        wkVBinding.deleteBtn.setOnClickListener(v -> deleteDigit());
        wkVBinding.clearPwdBtn.setOnClickListener(v -> showClearPasswordDialog());
    }

    private void appendDigit(int digit) {
        if (inputBuilder.length() >= 6) return;
        inputBuilder.append(digit);
        updateDots();
        if (inputBuilder.length() == 6) {
            verifyPassword();
        }
    }

    private void deleteDigit() {
        if (inputBuilder.length() == 0) return;
        inputBuilder.deleteCharAt(inputBuilder.length() - 1);
        updateDots();
    }

    private void updateDots() {
        for (int i = 0; i < 6; i++) {
            View dot = findViewById(dotIds[i]);
            dot.setSelected(i < inputBuilder.length());
        }
    }

    private void verifyPassword() {
        String password = inputBuilder.toString();
        String savedPwd = WKSharedPreferencesUtil.getInstance().getSP(KEY_LOCK_SCREEN_PWD);

        if (savedPwd != null && password.equals(savedPwd)) {
            WKSharedPreferencesUtil.getInstance().putInt(KEY_PWD_ATTEMPTS, MAX_PASSWORD_ATTEMPTS);
            finish();
        } else {
            remainingAttempts--;
            if (remainingAttempts <= 0) {
                WKToastUtils.getInstance().showToastNormal(getString(R.string.max_attempts_reached));
                finish();
            } else {
                WKSharedPreferencesUtil.getInstance().putInt(KEY_PWD_ATTEMPTS, remainingAttempts);
                wkVBinding.attemptsTv.setVisibility(View.VISIBLE);
                wkVBinding.attemptsTv.setText(String.format(getString(R.string.remaining_attempts), remainingAttempts));
                inputBuilder.setLength(0);
                updateDots();
            }
        }
    }

    private void showClearPasswordDialog() {
        WKDialogUtils.getInstance().showDialog(this,
                getString(R.string.clear_lock_screen_pwd),
                getString(R.string.clear_pwd_confirm),
                true, "", getString(R.string.confirm), 0, 0, index -> {
                    if (index == 1) {
                        WKSharedPreferencesUtil.getInstance().putSP(KEY_LOCK_SCREEN_PWD, "");
                        WKSharedPreferencesUtil.getInstance().putBoolean("lock_screen_pwd_enabled", false);
                        WKToastUtils.getInstance().showToastNormal(getString(R.string.clear_pwd_success));
                        finish();
                    }
                });
    }

    @Override
    protected void initListener() {
    }
}
