package com.chat.uikit.security;

import android.content.Intent;
import android.os.Bundle;
import android.os.CountDownTimer;
import android.text.Editable;
import android.text.TextWatcher;
import android.text.method.HideReturnsTransformationMethod;
import android.text.method.PasswordTransformationMethod;
import android.view.View;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKConfig;
import com.chat.base.config.WKSharedPreferencesUtil;
import com.chat.base.net.HttpResponseCode;
import com.chat.base.utils.WKToastUtils;
import com.chat.uikit.R;
import com.chat.uikit.WKUIKitApplication;
import com.chat.uikit.databinding.ActivityLoginPasswordBinding;
import com.chat.uikit.security.service.SecurityModel;

public class LoginPasswordActivity extends WKBaseActivity<ActivityLoginPasswordBinding> {

    private static final String KEY_BIND_PHONE = "bind_phone";
    private static final String KEY_BIND_EMAIL = "bind_email";
    private static final String KEY_LOGIN_PWD = "login_pwd";

    private boolean isPwdVisible = false;
    private CountDownTimer countDownTimer;

    // 当前验证方式: 0=手机, 1=邮箱
    private int verifyType = -1;
    private static final int TYPE_PHONE = 0;
    private static final int TYPE_EMAIL = 1;

    private String bindPhone = "";
    private String bindEmail = "";

    @Override
    protected ActivityLoginPasswordBinding getViewBinding() {
        return ActivityLoginPasswordBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.login_password_title);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        wkVBinding.pwdEt.setTransformationMethod(PasswordTransformationMethod.getInstance());

        // 获取已绑定的手机和邮箱
        if (WKConfig.getInstance().getUserInfo() != null) {
            String phone = WKConfig.getInstance().getUserInfo().phone;
            if (phone != null && !phone.isEmpty()) {
                bindPhone = phone;
            }
        }
        bindEmail = WKSharedPreferencesUtil.getInstance().getSP(KEY_BIND_EMAIL, "");
        if (bindPhone == null || bindPhone.isEmpty()) {
            bindPhone = WKSharedPreferencesUtil.getInstance().getSP(KEY_BIND_PHONE, "");
        }

        boolean hasPhone = bindPhone != null && !bindPhone.isEmpty();
        boolean hasEmail = bindEmail != null && !bindEmail.isEmpty();

        if (hasPhone && hasEmail) {
            // 都绑定了，显示选择项
            wkVBinding.verifyTypeLayout.setVisibility(View.VISIBLE);
            wkVBinding.phoneTypeBtn.setVisibility(View.VISIBLE);
            wkVBinding.emailTypeBtn.setVisibility(View.VISIBLE);
            wkVBinding.tabSpace.setVisibility(View.VISIBLE);
            // 默认选手机
            selectVerifyType(TYPE_PHONE);
        } else if (hasPhone) {
            // 只绑定了手机
            wkVBinding.verifyTypeLayout.setVisibility(View.GONE);
            wkVBinding.tabSpace.setVisibility(View.GONE);
            selectVerifyType(TYPE_PHONE);
        } else if (hasEmail) {
            // 只绑定了邮箱
            wkVBinding.verifyTypeLayout.setVisibility(View.GONE);
            wkVBinding.tabSpace.setVisibility(View.GONE);
            selectVerifyType(TYPE_EMAIL);
        } else {
            // 都没绑定
            wkVBinding.verifyTypeLayout.setVisibility(View.GONE);
            wkVBinding.tabSpace.setVisibility(View.GONE);
            wkVBinding.accountTv.setText(R.string.no_bind_account_tip);
            wkVBinding.getCodeBtn.setEnabled(false);
            wkVBinding.getCodeBtn.setAlpha(0.4f);
            wkVBinding.submitBtn.setEnabled(false);
            wkVBinding.submitBtn.setAlpha(0.4f);
        }
    }

    @Override
    protected void initListener() {
        // 密码可见切换
        wkVBinding.visibilityIv.setOnClickListener(v -> {
            isPwdVisible = !isPwdVisible;
            if (isPwdVisible) {
                wkVBinding.pwdEt.setTransformationMethod(HideReturnsTransformationMethod.getInstance());
                wkVBinding.visibilityIv.setImageResource(R.drawable.ic_visibility_on);
            } else {
                wkVBinding.pwdEt.setTransformationMethod(PasswordTransformationMethod.getInstance());
                wkVBinding.visibilityIv.setImageResource(R.drawable.ic_visibility_off);
            }
            wkVBinding.pwdEt.setSelection(wkVBinding.pwdEt.getText().length());
        });

        // 验证方式切换
        wkVBinding.phoneTypeBtn.setOnClickListener(v -> selectVerifyType(TYPE_PHONE));
        wkVBinding.emailTypeBtn.setOnClickListener(v -> selectVerifyType(TYPE_EMAIL));

        // 获取验证码
        wkVBinding.getCodeBtn.setOnClickListener(v -> sendVerifyCode());

        // 输入监听
        TextWatcher watcher = new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {}
            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {}
            @Override
            public void afterTextChanged(Editable s) {
                updateSubmitButton();
            }
        };
        wkVBinding.codeEt.addTextChangedListener(watcher);
        wkVBinding.pwdEt.addTextChangedListener(watcher);

        // 提交
        wkVBinding.submitBtn.setOnClickListener(v -> submitChangePwd());

        updateSubmitButton();
    }

    private void selectVerifyType(int type) {
        verifyType = type;
        if (type == TYPE_PHONE) {
            wkVBinding.phoneTypeBtn.setSelected(true);
            wkVBinding.emailTypeBtn.setSelected(false);
            wkVBinding.phoneTypeBtn.setTextColor(getResources().getColor(R.color.color_main));
            wkVBinding.phoneTypeBtn.setTypeface(wkVBinding.phoneTypeBtn.getTypeface(), android.graphics.Typeface.BOLD);
            wkVBinding.emailTypeBtn.setTextColor(getResources().getColor(R.color.color999));
            wkVBinding.emailTypeBtn.setTypeface(wkVBinding.emailTypeBtn.getTypeface(), android.graphics.Typeface.NORMAL);
            wkVBinding.accountTv.setText(maskPhone(bindPhone));
        } else {
            wkVBinding.emailTypeBtn.setSelected(true);
            wkVBinding.phoneTypeBtn.setSelected(false);
            wkVBinding.emailTypeBtn.setTextColor(getResources().getColor(R.color.color_main));
            wkVBinding.emailTypeBtn.setTypeface(wkVBinding.emailTypeBtn.getTypeface(), android.graphics.Typeface.BOLD);
            wkVBinding.phoneTypeBtn.setTextColor(getResources().getColor(R.color.color999));
            wkVBinding.phoneTypeBtn.setTypeface(wkVBinding.phoneTypeBtn.getTypeface(), android.graphics.Typeface.NORMAL);
            wkVBinding.accountTv.setText(maskEmail(bindEmail));
        }
        // 清空验证码和密码
        wkVBinding.codeEt.setText("");
        wkVBinding.pwdEt.setText("");
        // 重置验证码按钮
        resetCodeBtn();
        updateSubmitButton();
    }

    private void sendVerifyCode() {
        if (verifyType == TYPE_PHONE) {
            if (bindPhone == null || bindPhone.isEmpty()) {
                WKToastUtils.getInstance().showToastNormal(getString(R.string.no_bind_phone_tip));
                return;
            }
            // 立即开始倒计时
            startCountDown();
            SecurityModel.getInstance().sendChangePwdPhoneCode("0086", bindPhone, (code, msg) -> {
                if (code != HttpResponseCode.success) {
                    cancelCountDown();
                    WKToastUtils.getInstance().showToastNormal(msg);
                } else {
                    WKToastUtils.getInstance().showToastNormal(getString(R.string.code_sent));
                }
            });
        } else if (verifyType == TYPE_EMAIL) {
            if (bindEmail == null || bindEmail.isEmpty()) {
                WKToastUtils.getInstance().showToastNormal(getString(R.string.destroy_no_email_bound));
                return;
            }
            // 立即开始倒计时
            startCountDown();
            SecurityModel.getInstance().sendChangePwdEmailCode(bindEmail, (code, msg) -> {
                if (code != HttpResponseCode.success) {
                    cancelCountDown();
                    WKToastUtils.getInstance().showToastNormal(msg);
                } else {
                    WKToastUtils.getInstance().showToastNormal(getString(R.string.code_sent_to_email));
                }
            });
        }
    }

    private void submitChangePwd() {
        String code = wkVBinding.codeEt.getText().toString().trim();
        String pwd = wkVBinding.pwdEt.getText().toString().trim();

        if (code.length() != 6) {
            WKToastUtils.getInstance().showToastNormal(getString(R.string.destroy_code_hint));
            return;
        }
        if (pwd.length() < 6 || pwd.length() > 20) {
            WKToastUtils.getInstance().showToastNormal(getString(R.string.password_rule_tip));
            return;
        }

        wkVBinding.submitBtn.setEnabled(false);
        wkVBinding.submitBtn.setAlpha(0.4f);

        if (verifyType == TYPE_PHONE) {
            SecurityModel.getInstance().changePwdByPhone("0086", bindPhone, code, pwd, (code1, msg) -> {
                wkVBinding.submitBtn.setEnabled(true);
                wkVBinding.submitBtn.setAlpha(1f);
                handlePwdChangeResult(code1, msg);
            });
        } else if (verifyType == TYPE_EMAIL) {
            SecurityModel.getInstance().changePwdByEmail(bindEmail, code, pwd, (code1, msg) -> {
                wkVBinding.submitBtn.setEnabled(true);
                wkVBinding.submitBtn.setAlpha(1f);
                handlePwdChangeResult(code1, msg);
            });
        }
    }

    private void handlePwdChangeResult(int code, String msg) {
        if (code == HttpResponseCode.success) {
            WKSharedPreferencesUtil.getInstance().putSP(KEY_LOGIN_PWD, "");
            WKToastUtils.getInstance().showToastNormal(getString(R.string.pwd_set_success));
            // 退出登录，跳转到登录页
            WKUIKitApplication.getInstance().exitLogin(0);
        } else {
            WKToastUtils.getInstance().showToastNormal(msg);
        }
    }

    private void updateSubmitButton() {
        String code = wkVBinding.codeEt.getText().toString().trim();
        String pwd = wkVBinding.pwdEt.getText().toString().trim();
        boolean enabled = code.length() == 6 && pwd.length() >= 6 && pwd.length() <= 20
                && verifyType >= 0;
        wkVBinding.submitBtn.setAlpha(enabled ? 1f : 0.4f);
        wkVBinding.submitBtn.setEnabled(enabled);
    }

    private void startCountDown() {
        if (countDownTimer != null) {
            countDownTimer.cancel();
        }
        wkVBinding.getCodeBtn.setEnabled(false);
        wkVBinding.getCodeBtn.setTextColor(getResources().getColor(R.color.color999));
        countDownTimer = new CountDownTimer(60000, 1000) {
            @Override
            public void onTick(long millisUntilFinished) {
                int seconds = (int) (millisUntilFinished / 1000);
                wkVBinding.getCodeBtn.setText(seconds + "s");
            }

            @Override
            public void onFinish() {
                resetCodeBtn();
            }
        }.start();
    }

    private void cancelCountDown() {
        if (countDownTimer != null) {
            countDownTimer.cancel();
            countDownTimer = null;
        }
        resetCodeBtn();
    }

    private void resetCodeBtn() {
        wkVBinding.getCodeBtn.setEnabled(true);
        wkVBinding.getCodeBtn.setText(R.string.get_verify_code);
        wkVBinding.getCodeBtn.setTextColor(getResources().getColor(R.color.color_main));
    }

    private String maskPhone(String phone) {
        if (phone == null || phone.length() < 7) return phone;
        return phone.substring(0, 3) + "****" + phone.substring(phone.length() - 4);
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
