package com.chat.uikit.service;

import android.content.Intent;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKSystemAccount;
import com.chat.base.endpoint.entity.ChatViewMenu;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.chat.manager.WKIMUtils;
import com.chat.uikit.databinding.ActivityCustomerServiceBinding;
import com.chat.uikit.setting.WKAboutActivity;
import com.xinbida.wukongim.entity.WKChannelType;

/**
 * 客服中心页面
 * 在线客服、帮助中心、意见反馈等
 */
public class CustomerServiceActivity extends WKBaseActivity<ActivityCustomerServiceBinding> {

    @Override
    protected ActivityCustomerServiceBinding getViewBinding() {
        return ActivityCustomerServiceBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.customer_service);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
    }

    @Override
    protected void initListener() {
        // 在线客服
        SingleClickUtil.onSingleClick(wkVBinding.onlineServiceLayout, v -> startCustomerServiceChat());

        // 常见问题
        SingleClickUtil.onSingleClick(wkVBinding.faqLayout, v -> {
            WKToastUtils.getInstance().showToastNormal("常见问题");
        });

        // 意见反馈
        SingleClickUtil.onSingleClick(wkVBinding.feedbackLayout, v -> startFeedback());

        // 关于
        SingleClickUtil.onSingleClick(wkVBinding.aboutLayout, v -> {
            Intent intent = new Intent(this, WKAboutActivity.class);
            startActivity(intent);
        });
    }

    /**
     * 启动在线客服聊天
     */
    private void startCustomerServiceChat() {
        // 使用系统客服账号（如果有配置的话）
        // 这里使用系统通知账号作为客服入口示例
        String customerServiceId = WKSystemAccount.system_team;
        WKIMUtils.getInstance().startChatActivity(new ChatViewMenu(
                this,
                customerServiceId,
                WKChannelType.PERSONAL,
                0,
                true
        ));
    }

    /**
     * 启动意见反馈页面
     */
    private void startFeedback() {
        Intent intent = new Intent(this, FeedbackActivity.class);
        startActivity(intent);
    }
}
