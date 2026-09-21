package com.chat.uikit.security;

import android.content.Intent;
import android.text.Editable;
import android.text.TextWatcher;
import android.text.method.HideReturnsTransformationMethod;
import android.text.method.PasswordTransformationMethod;
import android.view.View;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKSharedPreferencesUtil;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActivityVertifyPwdBinding;

public class VertifyPwdActivity extends WKBaseActivity<ActivityVertifyPwdBinding> {

    private boolean isPwdVisible = false;
    public static final String EXTRA_VOUCHER_CODE = "voucher_code";
    public static final String EXTRA_TARGET = "target";
    public static final int TARGET_BIND_PHONE = 1;
    public static final int TARGET_BIND_EMAIL = 2;
    public static final int TARGET_DEFAULT = 0;
    private int target = TARGET_DEFAULT;

    @Override
    protected ActivityVertifyPwdBinding getViewBinding() {
        return ActivityVertifyPwdBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.vertify_pwd_title);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        wkVBinding.pwdEt.setTransformationMethod(PasswordTransformationMethod.getInstance());
        target = getIntent().getIntExtra(EXTRA_TARGET, TARGET_DEFAULT);
    }

    @Override
    protected void initListener() {
        wkVBinding.pwdEt.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {}
            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {}
            @Override
            public void afterTextChanged(Editable s) {
                boolean enabled = s != null && s.length() >= 4;
                wkVBinding.submitBtn.setAlpha(enabled ? 1f : 0.4f);
                wkVBinding.submitBtn.setEnabled(enabled);
            }
        });

        SingleClickUtil.onSingleClick(wkVBinding.visibilityIv, v -> {
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

        SingleClickUtil.onSingleClick(wkVBinding.submitBtn, v -> {
            String pwd = wkVBinding.pwdEt.getText().toString().trim();
            if (pwd.length() < 4) {
                WKToastUtils.getInstance().showToastNormal(getString(R.string.pwd_too_short));
                return;
            }
            String savedPwd = WKSharedPreferencesUtil.getInstance().getSP("login_pwd");
            if (savedPwd == null || savedPwd.isEmpty()) {
                WKToastUtils.getInstance().showToastNormal("请先设置聊天密码");
                return;
            }
            if (pwd.equals(savedPwd)) {
                String voucherCode = java.util.UUID.randomUUID().toString();
                WKSharedPreferencesUtil.getInstance().putSP(EXTRA_VOUCHER_CODE, voucherCode);
                Intent intent;
                if (target == TARGET_BIND_PHONE) {
                    intent = new Intent(this, VertifyPhoneActivity.class);
                } else if (target == TARGET_BIND_EMAIL) {
                    intent = new Intent(this, VertifyEmailActivity.class);
                } else {
                    intent = new Intent(this, AccountBindingActivity.class);
                }
                intent.putExtra(EXTRA_VOUCHER_CODE, voucherCode);
                startActivity(intent);
                finish();
            } else {
                WKToastUtils.getInstance().showToastNormal(getString(R.string.pwd_incorrect));
            }
        });
    }
}
