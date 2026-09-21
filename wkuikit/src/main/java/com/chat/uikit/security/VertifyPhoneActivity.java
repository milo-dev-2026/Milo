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
import com.chat.uikit.databinding.ActivityVertifyPhoneBinding;
import com.chat.uikit.security.service.SecurityModel;

public class VertifyPhoneActivity extends WKBaseActivity<ActivityVertifyPhoneBinding> {

    private static final String KEY_BIND_PHONE = "bind_phone";
    private CountDownTimer countDownTimer;

    @Override
    protected ActivityVertifyPhoneBinding getViewBinding() {
        return ActivityVertifyPhoneBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.bind_phone);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        String existingPhone = WKSharedPreferencesUtil.getInstance().getSP(KEY_BIND_PHONE);
        if (existingPhone != null && !existingPhone.isEmpty()) {
            wkVBinding.phoneDisplayTv.setText(getString(R.string.vertify_phone_sent, maskPhone(existingPhone)));
            wkVBinding.phoneEt.setText(existingPhone);
        } else {
            wkVBinding.phoneDisplayTv.setText(R.string.vertify_phone_desc);
        }
    }

    @Override
    protected void initListener() {
        wkVBinding.phoneEt.addTextChangedListener(new TextWatcher() {
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
            String phone = wkVBinding.phoneEt.getText().toString().trim();
            if (!phone.matches("^1[3-9]\\d{9}$")) {
                WKToastUtils.getInstance().showToastNormal(getString(R.string.hint_input_phone_error));
                return;
            }
            wkVBinding.getCodeBtn.setEnabled(false);
            SecurityModel.getInstance().sendBindPhoneCode("0086", phone, (code, msg) -> {
                if (code == HttpResponseCode.success) {
                    startCountDown();
                    wkVBinding.phoneDisplayTv.setText(getString(R.string.vertify_phone_sent, maskPhone(phone)));
                    WKToastUtils.getInstance().showToastNormal(getString(R.string.code_sent));
                } else {
                    wkVBinding.getCodeBtn.setEnabled(true);
                    WKToastUtils.getInstance().showToastNormal(msg);
                }
            });
        });

        // 提交绑定
        SingleClickUtil.onSingleClick(wkVBinding.submitBtn, v -> {
            String phone = wkVBinding.phoneEt.getText().toString().trim();
            String code = wkVBinding.codeEt.getText().toString().trim();
            if (!phone.matches("^1[3-9]\\d{9}$")) {
                WKToastUtils.getInstance().showToastNormal(getString(R.string.hint_input_phone_error));
                return;
            }
            if (code.length() != 6) {
                WKToastUtils.getInstance().showToastNormal(getString(R.string.hint_destroy_code));
                return;
            }
            wkVBinding.submitBtn.setEnabled(false);
            SecurityModel.getInstance().bindPhone("0086", phone, code, (code1, msg) -> {
                wkVBinding.submitBtn.setEnabled(true);
                if (code1 == HttpResponseCode.success) {
                    WKSharedPreferencesUtil.getInstance().putSP(KEY_BIND_PHONE, phone);
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
        String phone = wkVBinding.phoneEt.getText().toString().trim();
        String code = wkVBinding.codeEt.getText().toString().trim();
        boolean enabled = phone.matches("^1[3-9]\\d{9}$") && code.length() == 6;
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

    private String maskPhone(String phone) {
        if (phone == null || phone.length() < 7) return phone;
        return phone.substring(0, 3) + "****" + phone.substring(phone.length() - 4);
    }

    @Override
    protected void onDestroy() {
        super.onDestroy();
        if (countDownTimer != null) {
            countDownTimer.cancel();
        }
    }
}
