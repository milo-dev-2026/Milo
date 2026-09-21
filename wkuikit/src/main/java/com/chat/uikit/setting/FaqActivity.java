package com.chat.uikit.setting;

import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActivityFaqBinding;

public class FaqActivity extends WKBaseActivity<ActivityFaqBinding> {

    @Override
    protected ActivityFaqBinding getViewBinding() {
        return ActivityFaqBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.faq);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
    }

    @Override
    protected void initListener() {
    }
}
