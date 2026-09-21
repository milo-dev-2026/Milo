package com.chat.uikit.security;

import android.os.CountDownTimer;
import android.text.Editable;
import android.text.TextWatcher;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKConfig;
import com.chat.base.config.WKSharedPreferencesUtil;
import com.chat.base.net.ICommonListener;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActivityInputDestroyCodeBinding;
import com.chat.uikit.security.service.SecurityModel;

public class InputDestroyAccountCodeActivity extends WKBaseActivity<ActivityInputDestroyCodeBinding> {

    private CountDownTimer countDownTimer;
    private static final String KEY_BIND_EMAIL = "bind_email";
    private static final String KEY_BIND_PHONE = "bind_phone";

    private int verifyType = DestroyAccountActivity.VERIFY_TYPE_EMAIL;
    private String phone;
    private String email;

    @Override
    protected ActivityInputDestroyCodeBinding getViewBinding() {
        return ActivityInputDestroyCodeBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.destroy_verify_title);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        verifyType = getIntent().getIntExtra(DestroyAccountActivity.EXTRA_VERIFY_TYPE, DestroyAccountActivity.VERIFY_TYPE_EMAIL);

        email = WKSharedPreferencesUtil.getInstance().getSP(KEY_BIND_EMAIL);
        phone = WKSharedPreferencesUtil.getInstance().getSP(KEY_BIND_PHONE);
        if (phone == null || phone.isEmpty()) {
            if (WKConfig.getInstance().getUserInfo() != null) {
                phone = WKConfig.getInstance().getUserInfo().phone;
            }
        }

        if (verifyType == DestroyAccountActivity.VERIFY_TYPE_PHONE && phone != null && !phone.isEmpty()) {
            wkVBinding.emailTv.setText(getString(R.string.destroy_verify_phone_tip, maskPhone(phone)));
        } else if (email != null && !email.isEmpty()) {
            wkVBinding.emailTv.setText(maskEmail(email));
        }

        // 进入页面自动发送验证码
        sendCode();
    }

    @Override
    protected void initListener() {
        wkVBinding.codeEt.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {}
            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {}
            @Override
            public void afterTextChanged(Editable s) {
                boolean enabled = s != null && s.length() == 6;
                wkVBinding.submitBtn.setAlpha(enabled ? 1f : 0.4f);
                wkVBinding.submitBtn.setEnabled(enabled);
            }
        });

        SingleClickUtil.onSingleClick(wkVBinding.getCodeBtn, v -> {
            sendCode();
        });

        SingleClickUtil.onSingleClick(wkVBinding.submitBtn, v -> {
            String code = wkVBinding.codeEt.getText().toString().trim();
            if (code.length() != 6) {
                WKToastUtils.getInstance().showToastNormal(getString(R.string.hint_destroy_code));
                return;
            }
            doDestroy(code);
        });
    }

    private void sendCode() {
        if (verifyType == DestroyAccountActivity.VERIFY_TYPE_PHONE) {
            if (phone == null || phone.isEmpty()) {
                WKToastUtils.getInstance().showToastNormal("未找到绑定手机号");
                return;
            }
            SecurityModel.getInstance().sendDestroyPhoneCode("+86", phone, new ICommonListener() {
                @Override
                public void onResult(int code, String msg) {
                    if (code == 200) {
                        WKToastUtils.getInstance().showToastNormal(getString(R.string.code_sent));
                        startCountDown();
                    } else {
                        WKToastUtils.getInstance().showToastNormal(msg);
                    }
                }
            });
        } else {
            if (email == null || email.isEmpty()) {
                WKToastUtils.getInstance().showToastNormal("未找到绑定邮箱");
                return;
            }
            SecurityModel.getInstance().sendDestroyEmailCode(email, new ICommonListener() {
                @Override
                public void onResult(int code, String msg) {
                    if (code == 200) {
                        WKToastUtils.getInstance().showToastNormal(getString(R.string.code_sent_to_email));
                        startCountDown();
                    } else {
                        WKToastUtils.getInstance().showToastNormal(msg);
                    }
                }
            });
        }
    }

    private void doDestroy(String code) {
        String account = verifyType == DestroyAccountActivity.VERIFY_TYPE_PHONE ? phone : email;
        String type = verifyType == DestroyAccountActivity.VERIFY_TYPE_PHONE ? "phone" : "email";
        String zone = verifyType == DestroyAccountActivity.VERIFY_TYPE_PHONE ? "+86" : "";

        if (account == null || account.isEmpty()) {
            WKToastUtils.getInstance().showToastNormal("账号信息异常");
            return;
        }

        SecurityModel.getInstance().destroyAccount(account, code, type, zone, new ICommonListener() {
            @Override
            public void onResult(int code, String msg) {
                if (code == 200) {
                    WKSharedPreferencesUtil.getInstance().putSP("account_destroyed", "true");
                    WKToastUtils.getInstance().showToastNormal(getString(R.string.account_destroyed));
                    // 退出登录等操作
                    finish();
                } else {
                    WKToastUtils.getInstance().showToastNormal(msg);
                }
            }
        });
    }

    private void startCountDown() {
        if (countDownTimer != null) {
            countDownTimer.cancel();
        }
        wkVBinding.getCodeBtn.setEnabled(false);
        countDownTimer = new CountDownTimer(60000, 1000) {
            @Override
            public void onTick(long millisUntilFinished) {
                int seconds = (int) (millisUntilFinished / 1000);
                wkVBinding.getCodeBtn.setText(getString(R.string.resend_code_format, seconds));
                wkVBinding.getCodeBtn.setTextColor(getResources().getColor(R.color.color999));
            }

            @Override
            public void onFinish() {
                wkVBinding.getCodeBtn.setEnabled(true);
                wkVBinding.getCodeBtn.setText(R.string.get_verify_code);
                wkVBinding.getCodeBtn.setTextColor(getResources().getColor(R.color.c3F74FC));
            }
        }.start();
    }

    private String maskEmail(String email) {
        if (email == null || !email.contains("@")) return email;
        int atIndex = email.indexOf("@");
        if (atIndex <= 2) return email;
        return email.substring(0, Math.min(6, atIndex)) + "****" + email.substring(atIndex);
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
