package com.chat.uikit.setting;

import android.content.Intent;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.utils.WKDialogUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.WKUIKitApplication;
import com.chat.uikit.databinding.ActSettingLayoutBinding;
import com.chat.uikit.security.SecurityAccountActivity;

public class SettingActivity extends WKBaseActivity<ActSettingLayoutBinding> {

    @Override
    protected ActSettingLayoutBinding getViewBinding() {
        return ActSettingLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.setting);
    }

    @Override
    protected void initPresenter() {
        wkVBinding.refreshLayout.setEnableOverScrollDrag(true);
        wkVBinding.refreshLayout.setEnableLoadMore(false);
        wkVBinding.refreshLayout.setEnableRefresh(false);
    }

    @Override
    protected void initView() {
    }

    @Override
    protected void initListener() {
        SingleClickUtil.onSingleClick(wkVBinding.accountSecurityLayout, v ->
                startActivity(new Intent(this, SecurityAccountActivity.class)));

        SingleClickUtil.onSingleClick(wkVBinding.msgNoticeLayout, v ->
                startActivity(new Intent(this, MsgNoticesSettingActivity.class)));

        SingleClickUtil.onSingleClick(wkVBinding.aboutUsLayout, v ->
                startActivity(new Intent(this, WKAboutActivity.class)));

        wkVBinding.loginOutTv.setOnClickListener(v ->
                WKDialogUtils.getInstance().showDialog(this, getString(R.string.login_out),
                        getString(R.string.login_out_dialog), true, "", getString(R.string.login_out), 0, 0, index -> {
                    if (index == 1) {
                        WKUIKitApplication.getInstance().exitLogin(0);
                    }
                }));
    }
}
