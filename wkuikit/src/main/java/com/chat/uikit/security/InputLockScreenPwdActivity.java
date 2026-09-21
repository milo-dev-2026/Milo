package com.chat.uikit.security;

import android.view.View;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKSharedPreferencesUtil;
import com.chat.base.utils.WKToastUtils;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActivityInputLockScreenPwdBinding;

public class InputLockScreenPwdActivity extends WKBaseActivity<ActivityInputLockScreenPwdBinding> {

    public static final String EXTRA_IS_SET_NEW_PASSWORD = "is_set_new_password";

    private static final String KEY_LOCK_SCREEN_PWD = "lock_screen_pwd";
    private static final String KEY_LOCK_SCREEN_ENABLED = "lock_screen_pwd_enabled";

    private static final int STATE_INPUT = 0;
    private static final int STATE_CONFIRM = 1;
    private static final int STATE_MODIFY = 2;

    private int currentState = STATE_INPUT;
    private StringBuilder inputBuilder = new StringBuilder();
    private String firstInput = "";
    private boolean isSetNewPassword = false;

    private final int[] dotIds = {
            R.id.dot1, R.id.dot2, R.id.dot3, R.id.dot4, R.id.dot5, R.id.dot6
    };
    private final int[] btnIds = {
            R.id.btn0, R.id.btn1, R.id.btn2, R.id.btn3, R.id.btn4,
            R.id.btn5, R.id.btn6, R.id.btn7, R.id.btn8, R.id.btn9
    };

    @Override
    protected ActivityInputLockScreenPwdBinding getViewBinding() {
        return ActivityInputLockScreenPwdBinding.inflate(getLayoutInflater());
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
        isSetNewPassword = getIntent().getBooleanExtra(EXTRA_IS_SET_NEW_PASSWORD, false);
        if (isSetNewPassword) {
            wkVBinding.titleTv.setText(R.string.set_lock_screen_pwd);
            wkVBinding.subtitleTv.setText(R.string.set_lock_screen_pwd_desc);
            currentState = STATE_INPUT;
        } else {
            wkVBinding.titleTv.setText(R.string.modify_lock_screen_pwd);
            wkVBinding.subtitleTv.setText(R.string.modify_lock_screen_pwd_desc);
            currentState = STATE_MODIFY;
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
    }

    private void appendDigit(int digit) {
        if (inputBuilder.length() >= 6) return;
        inputBuilder.append(digit);
        updateDots();
        if (inputBuilder.length() == 6) {
            onPasswordComplete();
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

    private void onPasswordComplete() {
        String password = inputBuilder.toString();
        switch (currentState) {
            case STATE_INPUT:
                firstInput = password;
                inputBuilder.setLength(0);
                currentState = STATE_CONFIRM;
                wkVBinding.titleTv.setText(R.string.confirm_lock_screen_pwd);
                wkVBinding.subtitleTv.setText(R.string.confirm_lock_screen_pwd_desc);
                updateDots();
                break;
            case STATE_CONFIRM:
                if (password.equals(firstInput)) {
                    WKSharedPreferencesUtil.getInstance().putSP(KEY_LOCK_SCREEN_PWD, password);
                    WKSharedPreferencesUtil.getInstance().putBoolean(KEY_LOCK_SCREEN_ENABLED, true);
                    WKToastUtils.getInstance().showToastNormal(getString(R.string.pwd_set_success));
                    finish();
                } else {
                    WKToastUtils.getInstance().showToastNormal(getString(R.string.pwd_mismatch));
                    inputBuilder.setLength(0);
                    currentState = STATE_INPUT;
                    wkVBinding.titleTv.setText(R.string.set_lock_screen_pwd);
                    wkVBinding.subtitleTv.setText(R.string.set_lock_screen_pwd_desc);
                    updateDots();
                }
                break;
            case STATE_MODIFY:
                String oldPwd = WKSharedPreferencesUtil.getInstance().getSP(KEY_LOCK_SCREEN_PWD);
                if (oldPwd != null && password.equals(oldPwd)) {
                    inputBuilder.setLength(0);
                    currentState = STATE_INPUT;
                    firstInput = "";
                    wkVBinding.titleTv.setText(R.string.set_lock_screen_pwd);
                    wkVBinding.subtitleTv.setText(R.string.set_lock_screen_pwd_desc);
                    updateDots();
                } else {
                    WKToastUtils.getInstance().showToastNormal(getString(R.string.pwd_incorrect));
                    inputBuilder.setLength(0);
                    updateDots();
                }
                break;
        }
    }

    @Override
    protected void initListener() {
    }
}
