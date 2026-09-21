package com.chat.uikit.security;

import android.content.Intent;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKConfig;
import com.chat.base.config.WKSharedPreferencesUtil;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActivitySecurityAccountBinding;
import com.chat.uikit.user.BlacklistActivity;

public class SecurityAccountActivity extends WKBaseActivity<ActivitySecurityAccountBinding> {

    private static final String KEY_BIND_PHONE = "bind_phone";

    @Override
    protected ActivitySecurityAccountBinding getViewBinding() {
        return ActivitySecurityAccountBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.account_security);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        updatePhoneStatus();
    }

    @Override
    protected void onResume() {
        super.onResume();
        updatePhoneStatus();
    }

    private void updatePhoneStatus() {
        String phone = WKSharedPreferencesUtil.getInstance().getSP(KEY_BIND_PHONE);
        if (phone == null || phone.isEmpty()) {
            if (WKConfig.getInstance().getUserInfo() != null) {
                phone = WKConfig.getInstance().getUserInfo().phone;
            }
        }
        if (phone != null && !phone.isEmpty() && phone.length() >= 7) {
            wkVBinding.phoneStatusTv.setText(phone.substring(0, 3) + "****" + phone.substring(phone.length() - 4));
            wkVBinding.phoneStatusTv.setTextColor(getResources().getColor(R.color.colorDark));
        } else {
            wkVBinding.phoneStatusTv.setText(R.string.unbound);
            wkVBinding.phoneStatusTv.setTextColor(getResources().getColor(R.color.color999));
        }
    }

    @Override
    protected void initListener() {
        SingleClickUtil.onSingleClick(wkVBinding.bindPhoneLayout, v ->
                startActivity(new Intent(this, AccountBindingActivity.class)));

        SingleClickUtil.onSingleClick(wkVBinding.changePwdLayout, v ->
                startActivity(new Intent(this, PwdManagerActivity.class)));

        SingleClickUtil.onSingleClick(wkVBinding.blacklistLayout, v ->
                startActivity(new Intent(this, BlacklistActivity.class)));

        SingleClickUtil.onSingleClick(wkVBinding.destroyAccountLayout, v ->
                startActivity(new Intent(this, DestroyAccountActivity.class)));
    }
}
