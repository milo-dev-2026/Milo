package com.chat.uikit.security;

import android.content.Intent;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKConfig;
import com.chat.base.config.WKSharedPreferencesUtil;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActivityDestroyAccountBinding;

public class DestroyAccountActivity extends WKBaseActivity<ActivityDestroyAccountBinding> {

    private static final String KEY_BIND_EMAIL = "bind_email";
    private static final String KEY_BIND_PHONE = "bind_phone";

    public static final String EXTRA_VERIFY_TYPE = "verify_type";
    public static final int VERIFY_TYPE_EMAIL = 0;
    public static final int VERIFY_TYPE_PHONE = 1;

    @Override
    protected ActivityDestroyAccountBinding getViewBinding() {
        return ActivityDestroyAccountBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.destroy_account);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        // 获取绑定的邮箱和手机号
        String email = WKSharedPreferencesUtil.getInstance().getSP(KEY_BIND_EMAIL);
        String phone = WKSharedPreferencesUtil.getInstance().getSP(KEY_BIND_PHONE);
        if (phone == null || phone.isEmpty()) {
            if (WKConfig.getInstance().getUserInfo() != null) {
                phone = WKConfig.getInstance().getUserInfo().phone;
            }
        }

        // 显示当前绑定信息
        StringBuilder boundInfo = new StringBuilder();
        if (email != null && !email.isEmpty()) {
            boundInfo.append("邮箱：").append(maskEmail(email));
        }
        if (phone != null && !phone.isEmpty()) {
            if (boundInfo.length() > 0) {
                boundInfo.append("\n");
            }
            boundInfo.append("手机：").append(maskPhone(phone));
        }
        if (boundInfo.length() > 0) {
            wkVBinding.emailTv.setText(boundInfo.toString());
        } else {
            wkVBinding.emailTv.setText(R.string.destroy_no_email);
        }

        String appName = getString(R.string.app_name);
        wkVBinding.special1Tv.setText(getString(R.string.destroy_special_1, appName));
    }

    @Override
    protected void initListener() {
        SingleClickUtil.onSingleClick(wkVBinding.agreementBtn, v -> {
            openWebPage("https://www.milo.com/agreement.html");
        });

        SingleClickUtil.onSingleClick(wkVBinding.continueBtn, v -> {
            String email = WKSharedPreferencesUtil.getInstance().getSP(KEY_BIND_EMAIL);
            String phone = WKSharedPreferencesUtil.getInstance().getSP(KEY_BIND_PHONE);
            if (phone == null || phone.isEmpty()) {
                if (WKConfig.getInstance().getUserInfo() != null) {
                    phone = WKConfig.getInstance().getUserInfo().phone;
                }
            }

            boolean hasEmail = email != null && !email.isEmpty();
            boolean hasPhone = phone != null && !phone.isEmpty();

            if (!hasEmail && !hasPhone) {
                WKToastUtils.getInstance().showToastNormal(getString(R.string.destroy_no_bound_account));
                return;
            }

            // 优先用邮箱验证，没有邮箱用手机验证
            Intent intent = new Intent(this, InputDestroyAccountCodeActivity.class);
            if (hasEmail) {
                intent.putExtra(EXTRA_VERIFY_TYPE, VERIFY_TYPE_EMAIL);
            } else {
                intent.putExtra(EXTRA_VERIFY_TYPE, VERIFY_TYPE_PHONE);
            }
            startActivity(intent);
        });

        SingleClickUtil.onSingleClick(wkVBinding.thinkAgainBtn, v -> finish());
    }

    private void openWebPage(String url) {
        try {
            android.net.Uri uri = android.net.Uri.parse(url);
            Intent intent = new Intent(Intent.ACTION_VIEW, uri);
            startActivity(intent);
        } catch (Exception e) {
            WKToastUtils.getInstance().showToastNormal(getString(R.string.user_agreement));
        }
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
}
