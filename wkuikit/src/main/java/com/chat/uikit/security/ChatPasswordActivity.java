package com.chat.uikit.security;

import android.text.Editable;
import android.text.TextWatcher;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKSharedPreferencesUtil;
import com.chat.base.net.HttpResponseCode;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActivityChatPasswordBinding;
import com.chat.uikit.security.service.SecurityModel;

public class ChatPasswordActivity extends WKBaseActivity<ActivityChatPasswordBinding> {

    private static final String KEY_CHAT_PWD = "chat_pwd";
    private static final String KEY_CHAT_PWD_ENABLED = "chat_password_enabled";

    @Override
    protected ActivityChatPasswordBinding getViewBinding() {
        return ActivityChatPasswordBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.chat_password_title);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
    }

    @Override
    protected void initListener() {
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
        wkVBinding.loginPwdEt.addTextChangedListener(watcher);
        wkVBinding.chatPwdEt.addTextChangedListener(watcher);
        wkVBinding.confirmPwdEt.addTextChangedListener(watcher);

        SingleClickUtil.onSingleClick(wkVBinding.submitBtn, v -> submitChatPwd());
    }

    private void submitChatPwd() {
        String loginPwd = wkVBinding.loginPwdEt.getText().toString().trim();
        String chatPwd = wkVBinding.chatPwdEt.getText().toString().trim();
        String confirmPwd = wkVBinding.confirmPwdEt.getText().toString().trim();

        if (loginPwd.isEmpty()) {
            WKToastUtils.getInstance().showToastNormal(getString(R.string.input_login_password));
            return;
        }
        if (chatPwd.length() != 6) {
            WKToastUtils.getInstance().showToastNormal(getString(R.string.input_chat_password));
            return;
        }
        if (!chatPwd.equals(confirmPwd)) {
            WKToastUtils.getInstance().showToastNormal(getString(R.string.chat_password_mismatch));
            return;
        }

        wkVBinding.submitBtn.setEnabled(false);
        wkVBinding.submitBtn.setAlpha(0.4f);

        // 调用后端接口验证登录密码
        SecurityModel.getInstance().verifyLoginPwd(loginPwd, (code, msg) -> {
            if (code == HttpResponseCode.success) {
                // 登录密码正确，设置聊天密码
                WKSharedPreferencesUtil.getInstance().putSP(KEY_CHAT_PWD, chatPwd);
                WKSharedPreferencesUtil.getInstance().putBoolean(KEY_CHAT_PWD_ENABLED, true);
                WKToastUtils.getInstance().showToastNormal(getString(R.string.chat_password_set_success));
                finish();
            } else {
                wkVBinding.submitBtn.setEnabled(true);
                wkVBinding.submitBtn.setAlpha(1f);
                WKToastUtils.getInstance().showToastNormal(msg != null ? msg : getString(R.string.pwd_incorrect));
            }
        });
    }

    private void updateSubmitButton() {
        String loginPwd = wkVBinding.loginPwdEt.getText().toString().trim();
        String chatPwd = wkVBinding.chatPwdEt.getText().toString().trim();
        String confirmPwd = wkVBinding.confirmPwdEt.getText().toString().trim();
        boolean enabled = !loginPwd.isEmpty() && chatPwd.length() == 6 && confirmPwd.length() == 6;
        wkVBinding.submitBtn.setAlpha(enabled ? 1f : 0.4f);
        wkVBinding.submitBtn.setEnabled(enabled);
    }
}
