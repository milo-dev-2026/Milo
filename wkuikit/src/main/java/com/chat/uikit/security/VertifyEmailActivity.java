package com.chat.uikit.security;

import android.os.CountDownTimer;
import android.text.Editable;
import android.text.TextWatcher;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKSharedPreferencesUtil;
import com.chat.base.net.HttpResponseCode;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActivityVertifyEmailBinding;
import com.chat.uikit.security.service.SecurityModel;

public class VertifyEmailActivity extends WKBaseActivity<ActivityVertifyEmailBinding> {

    private static final String KEY_BIND_EMAIL = "bind_email";
    private CountDownTimer countDownTimer;

    @Override
    protected ActivityVertifyEmailBinding getViewBinding() {
        return ActivityVertifyEmailBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.bind_email);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        String existingEmail = WKSharedPreferencesUtil.getInstance().getSP(KEY_BIND_EMAIL);
        if (existingEmail != null && !existingEmail.isEmpty()) {
            wkVBinding.emailDisplayTv.setText(getString(R.string.vertify_email_sent, maskEmail(existingEmail)));
            wkVBinding.emailEt.setText(existingEmail);
        } else {
            wkVBinding.emailDisplayTv.setText(R.string.vertify_email_desc);
        }
    }

    @Override
    protected void initListener() {
        wkVBinding.emailEt.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {}
            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {}
            @Override
            public void afterTextChanged(Editable s) {
                updateSubmitState();
            }
        });

        wkVBinding.codeEt.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {}
            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {}
            @Override
            public void afterTextChanged(Editable s) {
                updateSubmitState();
            }
        });

        // 获取验证码
        SingleClickUtil.onSingleClick(wkVBinding.getCodeBtn, v -> {
            String email = wkVBinding.emailEt.getText().toString().trim();
            if (!email.matches("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")) {
                WKToastUtils.getInstance().showToastNormal(getString(R.string.hint_input_email_error));
                return;
            }
            wkVBinding.getCodeBtn.setEnabled(false);
            SecurityModel.getInstance().sendBindEmailCode(email, (code, msg) -> {
                if (code == HttpResponseCode.success) {
                    startCountDown();
                    wkVBinding.emailDisplayTv.setText(getString(R.string.vertify_email_sent, maskEmail(email)));
                    WKToastUtils.getInstance().showToastNormal(getString(R.string.code_sent_to_email));
                } else {
                    wkVBinding.getCodeBtn.setEnabled(true);
                    WKToastUtils.getInstance().showToastNormal(msg);
                }
            });
        });

        // 提交绑定
        SingleClickUtil.onSingleClick(wkVBinding.submitBtn, v -> {
            String email = wkVBinding.emailEt.getText().toString().trim();
            String code = wkVBinding.codeEt.getText().toString().trim();
            if (!email.matches("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")) {
                WKToastUtils.getInstance().showToastNormal(getString(R.string.hint_input_email_error));
                return;
            }
            if (code.length() != 6) {
                WKToastUtils.getInstance().showToastNormal(getString(R.string.hint_destroy_code));
                return;
            }
            wkVBinding.submitBtn.setEnabled(false);
            SecurityModel.getInstance().bindEmail(email, code, (code1, msg) -> {
                wkVBinding.submitBtn.setEnabled(true);
                if (code1 == HttpResponseCode.success) {
                    WKSharedPreferencesUtil.getInstance().putSP(KEY_BIND_EMAIL, email);
                    WKToastUtils.getInstance().showToastNormal(getString(R.string.bind_success));
                    setResult(RESULT_OK);
                    finish();
                } else {
                    WKToastUtils.getInstance().showToastNormal(msg);
                }
            });
        });
    }

    private void updateSubmitState() {
        String email = wkVBinding.emailEt.getText().toString().trim();
        String code = wkVBinding.codeEt.getText().toString().trim();
        boolean enabled = email.matches("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$") && code.length() == 6;
        wkVBinding.submitBtn.setAlpha(enabled ? 1f : 0.4f);
        wkVBinding.submitBtn.setEnabled(enabled);
    }

    private void startCountDown() {
        if (countDownTimer != null) {
            countDownTimer.cancel();
        }
        wkVBinding.getCodeBtn.setEnabled(false);
        countDownTimer = new CountDownTimer(60000, 1000) {
            @Override
            public void onTick(long millisUntilFinished) {
                wkVBinding.getCodeBtn.setText(millisUntilFinished / 1000 + " s");
            }

            @Override
            public void onFinish() {
                wkVBinding.getCodeBtn.setEnabled(true);
                wkVBinding.getCodeBtn.setText(R.string.get_verf_code);
            }
        }.start();
    }

    private String maskEmail(String email) {
        if (email == null || !email.contains("@")) return email;
        int atIndex = email.indexOf("@");
        if (atIndex <= 2) return email;
        return email.substring(0, 2) + "***" + email.substring(atIndex);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (countDownTimer != null) {
            countDownTimer.cancel();
        }
    }
}
