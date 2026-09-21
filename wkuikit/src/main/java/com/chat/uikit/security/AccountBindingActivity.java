package com.chat.uikit.security;

import android.os.CountDownTimer;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.View;
import android.widget.EditText;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKConfig;
import com.chat.base.config.WKSharedPreferencesUtil;
import com.chat.base.net.HttpResponseCode;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActivityAccountBindingBinding;
import com.chat.uikit.security.service.SecurityModel;

public class AccountBindingActivity extends WKBaseActivity<ActivityAccountBindingBinding> {

    private static final String KEY_BIND_PHONE = "bind_phone";
    private static final String KEY_BIND_EMAIL = "bind_email";

    private int currentMode = 0;
    private static final int MODE_PHONE = 0;
    private static final int MODE_EMAIL = 1;

    private CountDownTimer countDownTimer;

    @Override
    protected ActivityAccountBindingBinding getViewBinding() {
        return ActivityAccountBindingBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.account_binding);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        updatePhoneStatus();
        updateEmailStatus();
    }

    @Override
    protected void onResume() {
        super.onResume();
        updatePhoneStatus();
        updateEmailStatus();
    }

    private void updatePhoneStatus() {
        String phone = WKSharedPreferencesUtil.getInstance().getSP(KEY_BIND_PHONE);
        if (phone == null || phone.isEmpty()) {
            if (WKConfig.getInstance().getUserInfo() != null) {
                phone = WKConfig.getInstance().getUserInfo().phone;
            }
        }
        if (phone != null && !phone.isEmpty()) {
            wkVBinding.phoneStatusTv.setText(maskPhone(phone));
            wkVBinding.phoneStatusTag.setText(R.string.bound);
            wkVBinding.phoneStatusTag.setBackgroundResource(R.drawable.bg_tag_bound);
            wkVBinding.phoneStatusTag.setTextColor(getResources().getColor(R.color.c3F74FC));
            wkVBinding.bindPhoneBtn.setText(R.string.change_btn);
            wkVBinding.bindPhoneBtn.setBackgroundResource(R.drawable.bg_btn_solid_blue);
            wkVBinding.bindPhoneBtn.setTextColor(getResources().getColor(R.color.white));
        } else {
            wkVBinding.phoneStatusTv.setText(R.string.phone_not_bound);
            wkVBinding.phoneStatusTag.setText(R.string.not_bound);
            wkVBinding.phoneStatusTag.setBackgroundResource(R.drawable.bg_tag_unbound);
            wkVBinding.phoneStatusTag.setTextColor(getResources().getColor(R.color.color999));
            wkVBinding.bindPhoneBtn.setText(R.string.bind);
            wkVBinding.bindPhoneBtn.setBackgroundResource(R.drawable.bg_btn_outline_blue);
            wkVBinding.bindPhoneBtn.setTextColor(getResources().getColor(R.color.c3F74FC));
        }
    }

    private void updateEmailStatus() {
        String email = WKSharedPreferencesUtil.getInstance().getSP(KEY_BIND_EMAIL);
        if (email != null && !email.isEmpty()) {
            wkVBinding.emailStatusTv.setText(maskEmail(email));
            wkVBinding.emailStatusTag.setText(R.string.bound);
            wkVBinding.emailStatusTag.setBackgroundResource(R.drawable.bg_tag_bound);
            wkVBinding.emailStatusTag.setTextColor(getResources().getColor(R.color.c3F74FC));
            wkVBinding.bindEmailBtn.setText(R.string.change_btn);
            wkVBinding.bindEmailBtn.setBackgroundResource(R.drawable.bg_btn_solid_blue);
            wkVBinding.bindEmailBtn.setTextColor(getResources().getColor(R.color.white));
        } else {
            wkVBinding.emailStatusTv.setText(R.string.unbound);
            wkVBinding.emailStatusTag.setText(R.string.not_bound);
            wkVBinding.emailStatusTag.setBackgroundResource(R.drawable.bg_tag_unbound);
            wkVBinding.emailStatusTag.setTextColor(getResources().getColor(R.color.color999));
            wkVBinding.bindEmailBtn.setText(R.string.bind);
            wkVBinding.bindEmailBtn.setBackgroundResource(R.drawable.bg_btn_outline_blue);
            wkVBinding.bindEmailBtn.setTextColor(getResources().getColor(R.color.c3F74FC));
        }
    }

    @Override
    protected void initListener() {
        SingleClickUtil.onSingleClick(wkVBinding.bindPhoneBtn, v -> {
            currentMode = MODE_PHONE;
            showBindingDialog();
        });

        SingleClickUtil.onSingleClick(wkVBinding.bindEmailBtn, v -> {
            currentMode = MODE_EMAIL;
            showBindingDialog();
        });
    }

    private void showBindingDialog() {
        String title = currentMode == MODE_PHONE ? getString(R.string.bind_phone) : getString(R.string.bind_email);
        String hint = currentMode == MODE_PHONE ? getString(R.string.hint_input_phone) : getString(R.string.hint_input_email);

        View dialogView = getLayoutInflater().inflate(R.layout.dialog_bind_account, null);
        EditText accountEt = dialogView.findViewById(R.id.accountEt);
        EditText codeEt = dialogView.findViewById(R.id.codeEt);
        TextView getCodeBtn = dialogView.findViewById(R.id.getCodeBtn);
        TextView confirmBtn = dialogView.findViewById(R.id.confirmBtn);
        accountEt.setHint(hint);

        android.app.AlertDialog dialog = new android.app.AlertDialog.Builder(this)
                .setTitle(title)
                .setView(dialogView)
                .setCancelable(true)
                .create();

        // 输入监听
        TextWatcher watcher = new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {}
            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {}
            @Override
            public void afterTextChanged(Editable s) {
                updateConfirmState(accountEt, codeEt, confirmBtn);
            }
        };
        accountEt.addTextChangedListener(watcher);
        codeEt.addTextChangedListener(watcher);

        // 获取验证码 - 点击后立即开始倒计时，提升响应速度
        getCodeBtn.setOnClickListener(v -> {
            String account = accountEt.getText().toString().trim();
            if (currentMode == MODE_PHONE) {
                if (!account.matches("^1[3-9]\\d{9}$")) {
                    WKToastUtils.getInstance().showToastNormal(getString(R.string.hint_input_phone_error));
                    return;
                }
                // 立即开始倒计时，提升响应速度
                startCountDown(getCodeBtn);
                SecurityModel.getInstance().sendBindPhoneCode("0086", account, (code, msg) -> {
                    if (code != HttpResponseCode.success) {
                        // 发送失败，恢复按钮
                        cancelCountDown(getCodeBtn);
                        WKToastUtils.getInstance().showToastNormal(msg);
                    } else {
                        WKToastUtils.getInstance().showToastNormal(getString(R.string.code_sent));
                    }
                });
            } else {
                if (!account.matches("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")) {
                    WKToastUtils.getInstance().showToastNormal(getString(R.string.hint_input_email_error));
                    return;
                }
                // 立即开始倒计时，提升响应速度
                startCountDown(getCodeBtn);
                SecurityModel.getInstance().sendBindEmailCode(account, (code, msg) -> {
                    if (code != HttpResponseCode.success) {
                        // 发送失败，恢复按钮
                        cancelCountDown(getCodeBtn);
                        WKToastUtils.getInstance().showToastNormal(msg);
                    } else {
                        WKToastUtils.getInstance().showToastNormal(getString(R.string.code_sent_to_email));
                    }
                });
            }
        });

        // 确认绑定
        confirmBtn.setOnClickListener(v -> {
            String account = accountEt.getText().toString().trim();
            String code = codeEt.getText().toString().trim();

            if (currentMode == MODE_PHONE) {
                if (!account.matches("^1[3-9]\\d{9}$")) {
                    WKToastUtils.getInstance().showToastNormal(getString(R.string.hint_input_phone_error));
                    return;
                }
            } else {
                if (!account.matches("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$")) {
                    WKToastUtils.getInstance().showToastNormal(getString(R.string.hint_input_email_error));
                    return;
                }
            }
            if (code.length() != 6) {
                WKToastUtils.getInstance().showToastNormal(getString(R.string.hint_destroy_code));
                return;
            }

            confirmBtn.setEnabled(false);
            confirmBtn.setAlpha(0.5f);
            if (currentMode == MODE_PHONE) {
                SecurityModel.getInstance().bindPhone("0086", account, code, (code1, msg) -> {
                    confirmBtn.setEnabled(true);
                    confirmBtn.setAlpha(1f);
                    if (code1 == HttpResponseCode.success) {
                        WKSharedPreferencesUtil.getInstance().putSP(KEY_BIND_PHONE, account);
                        WKToastUtils.getInstance().showToastNormal(getString(R.string.bind_success));
                        updatePhoneStatus();
                        dialog.dismiss();
                    } else {
                        WKToastUtils.getInstance().showToastNormal(msg);
                    }
                });
            } else {
                SecurityModel.getInstance().bindEmail(account, code, (code1, msg) -> {
                    confirmBtn.setEnabled(true);
                    confirmBtn.setAlpha(1f);
                    if (code1 == HttpResponseCode.success) {
                        WKSharedPreferencesUtil.getInstance().putSP(KEY_BIND_EMAIL, account);
                        WKToastUtils.getInstance().showToastNormal(getString(R.string.bind_success));
                        updateEmailStatus();
                        dialog.dismiss();
                    } else {
                        WKToastUtils.getInstance().showToastNormal(msg);
                    }
                });
            }
        });

        updateConfirmState(accountEt, codeEt, confirmBtn);
        dialog.show();
    }

    private void updateConfirmState(EditText accountEt, EditText codeEt, TextView confirmBtn) {
        String account = accountEt.getText().toString().trim();
        String code = codeEt.getText().toString().trim();
        boolean accountValid;
        if (currentMode == MODE_PHONE) {
            accountValid = account.matches("^1[3-9]\\d{9}$");
        } else {
            accountValid = account.matches("^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\\.[a-zA-Z]{2,}$");
        }
        boolean enabled = accountValid && code.length() == 6;
        confirmBtn.setAlpha(enabled ? 1f : 0.4f);
        confirmBtn.setEnabled(enabled);
    }

    private void startCountDown(TextView getCodeBtn) {
        if (countDownTimer != null) {
            countDownTimer.cancel();
        }
        getCodeBtn.setEnabled(false);
        getCodeBtn.setAlpha(0.5f);
        countDownTimer = new CountDownTimer(60000, 1000) {
            @Override
            public void onTick(long millisUntilFinished) {
                getCodeBtn.setText(millisUntilFinished / 1000 + "s");
            }

            @Override
            public void onFinish() {
                getCodeBtn.setEnabled(true);
                getCodeBtn.setAlpha(1f);
                getCodeBtn.setText(R.string.get_verify_code);
            }
        }.start();
    }

    private void cancelCountDown(TextView getCodeBtn) {
        if (countDownTimer != null) {
            countDownTimer.cancel();
            countDownTimer = null;
        }
        getCodeBtn.setEnabled(true);
        getCodeBtn.setAlpha(1f);
        getCodeBtn.setText(R.string.get_verify_code);
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
