package com.chat.uikit.user;

import android.content.Intent;
import android.text.Editable;
import android.text.TextWatcher;
import android.view.View;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKConfig;
import com.chat.base.config.WKSharedPreferencesUtil;
import com.chat.base.net.HttpResponseCode;
import com.chat.base.utils.SoftKeyboardUtils;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActivityPersonalSignatureBinding;
import com.chat.uikit.user.service.UserModel;

public class PersonalSignatureActivity extends WKBaseActivity<ActivityPersonalSignatureBinding> {
    private String channelId;
    private String oldStr = "";

    @Override
    protected ActivityPersonalSignatureBinding getViewBinding() {
        return ActivityPersonalSignatureBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(android.widget.TextView titleTv) {
        titleTv.setText(R.string.personal_signature);
    }

    @Override
    protected void initPresenter() {
        channelId = getIntent().getStringExtra("channelId");
        oldStr = getIntent().getStringExtra("oldStr");
        if (oldStr == null) oldStr = "";
    }

    @Override
    protected void initView() {
        wkVBinding.totalTv.setText("/100");
        if (!oldStr.isEmpty()) {
            wkVBinding.contentEt.setText(oldStr);
            wkVBinding.countTv.setText(String.valueOf(oldStr.length()));
        }
        SoftKeyboardUtils.getInstance().showSoftKeyBoard(this, wkVBinding.contentEt);
    }

    @Override
    protected String getRightTvText(android.widget.TextView textView) {
        return getString(R.string.b_complete);
    }

    @Override
    protected void rightLayoutClick() {
        super.rightLayoutClick();
        String content = wkVBinding.contentEt.getText().toString().trim();
        showTitleRightLoading();
        UserModel.getInstance().updateUserInfo("signature", content, (code, msg) -> {
            if (code == HttpResponseCode.success) {
                saveSignatureLocal(content);
                finishWithResult(content);
            } else {
                // API不支持signature字段时，本地保存
                saveSignatureLocal(content);
                finishWithResult(content);
            }
        });
    }

    private void saveSignatureLocal(String content) {
        WKSharedPreferencesUtil.getInstance().putSPWithUID("user_signature", content);
    }

    private void finishWithResult(String content) {
        hideTitleRightLoading();
        Intent intent = new Intent();
        intent.putExtra("result", content);
        intent.putExtra("updateType", 3);
        setResult(RESULT_OK, intent);
        finish();
    }

    @Override
    protected void initListener() {
        wkVBinding.contentEt.addTextChangedListener(new TextWatcher() {
            @Override
            public void beforeTextChanged(CharSequence s, int start, int count, int after) {}

            @Override
            public void onTextChanged(CharSequence s, int start, int before, int count) {}

            @Override
            public void afterTextChanged(Editable editable) {
                String content = editable.toString();
                if (content.length() > 100) {
                    content = content.substring(0, 100);
                    wkVBinding.contentEt.setText(content);
                    wkVBinding.contentEt.setSelection(content.length());
                }
                wkVBinding.countTv.setText(String.valueOf(content.length()));
                if (content.isEmpty() || content.equals(oldStr)) {
                    hideTitleRightView();
                } else {
                    showTitleRightView();
                }
            }
        });
        wkVBinding.ivDelete.setOnClickListener(v -> {
            wkVBinding.contentEt.setText("");
            wkVBinding.countTv.setText("0");
        });
    }

    @Override
    public void finish() {
        super.finish();
        SoftKeyboardUtils.getInstance().hideSoftKeyboard(this);
    }
}
