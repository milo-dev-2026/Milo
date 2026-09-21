package com.chat.uikit.security;

import android.view.View;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.config.WKSharedPreferencesUtil;
import com.chat.base.ui.components.SwitchView;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.databinding.ActivityMessagePrivacyBinding;

/**
 * 2024-08-31
 * 消息隐私设置页面
 */
public class MessagePrivacyActivity extends WKBaseActivity<ActivityMessagePrivacyBinding> {

    private static final String KEY_BURN_AFTER_READING = "burn_after_reading";
    private static final String KEY_BURN_TIME = "burn_time";
    private static final String KEY_READ_RECEIPT = "read_receipt";
    private static final String KEY_TYPING_STATUS = "typing_status";

    private int burnTime = 10; // 默认10秒

    @Override
    protected ActivityMessagePrivacyBinding getViewBinding() {
        return ActivityMessagePrivacyBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.message_privacy);
    }

    @Override
    protected void initPresenter() {
    }

    @Override
    protected void initView() {
        // 读取保存的设置
        boolean burnEnabled = WKSharedPreferencesUtil.getInstance().getBoolean(KEY_BURN_AFTER_READING);
        burnTime = WKSharedPreferencesUtil.getInstance().getInt(KEY_BURN_TIME, 10);
        boolean readReceiptEnabled = WKSharedPreferencesUtil.getInstance().getBoolean(KEY_READ_RECEIPT);
        boolean typingStatusEnabled = WKSharedPreferencesUtil.getInstance().getBoolean(KEY_TYPING_STATUS);

        wkVBinding.burnSwitchView.setChecked(burnEnabled);
        wkVBinding.burnTimeExpandLayout.setExpanded(burnEnabled);
        wkVBinding.readReceiptSwitchView.setChecked(readReceiptEnabled);
        wkVBinding.typingStatusSwitchView.setChecked(typingStatusEnabled);

        updateBurnTimeUI();
    }

    @Override
    protected void initListener() {
        // 阅后即焚开关
        wkVBinding.burnSwitchView.setOnCheckedChangeListener(new SwitchView.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(View view, boolean isChecked) {
                WKSharedPreferencesUtil.getInstance().putBoolean(KEY_BURN_AFTER_READING, isChecked);
                wkVBinding.burnTimeExpandLayout.setExpanded(isChecked);
                if (isChecked) {
                    WKToastUtils.getInstance().showToastNormal("已开启阅后即焚");
                } else {
                    WKToastUtils.getInstance().showToastNormal("已关闭阅后即焚");
                }
            }
        });

        // 阅后即焚时间选择 - 5秒
        SingleClickUtil.onSingleClick(wkVBinding.time5Layout, v -> {
            burnTime = 5;
            saveBurnTime();
        });

        // 10秒
        SingleClickUtil.onSingleClick(wkVBinding.time10Layout, v -> {
            burnTime = 10;
            saveBurnTime();
        });

        // 30秒
        SingleClickUtil.onSingleClick(wkVBinding.time30Layout, v -> {
            burnTime = 30;
            saveBurnTime();
        });

        // 1分钟
        SingleClickUtil.onSingleClick(wkVBinding.time60Layout, v -> {
            burnTime = 60;
            saveBurnTime();
        });

        // 已读回执
        wkVBinding.readReceiptSwitchView.setOnCheckedChangeListener(new SwitchView.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(View view, boolean isChecked) {
                WKSharedPreferencesUtil.getInstance().putBoolean(KEY_READ_RECEIPT, isChecked);
            }
        });

        // 输入状态
        wkVBinding.typingStatusSwitchView.setOnCheckedChangeListener(new SwitchView.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(View view, boolean isChecked) {
                WKSharedPreferencesUtil.getInstance().putBoolean(KEY_TYPING_STATUS, isChecked);
            }
        });
    }

    private void saveBurnTime() {
        WKSharedPreferencesUtil.getInstance().putInt(KEY_BURN_TIME, burnTime);
        updateBurnTimeUI();
    }

    private void updateBurnTimeUI() {
        wkVBinding.time5CheckIv.setVisibility(burnTime == 5 ? View.VISIBLE : View.GONE);
        wkVBinding.time10CheckIv.setVisibility(burnTime == 10 ? View.VISIBLE : View.GONE);
        wkVBinding.time30CheckIv.setVisibility(burnTime == 30 ? View.VISIBLE : View.GONE);
        wkVBinding.time60CheckIv.setVisibility(burnTime == 60 ? View.VISIBLE : View.GONE);

        String timeStr;
        if (burnTime < 60) {
            timeStr = burnTime + "秒";
        } else {
            timeStr = (burnTime / 60) + "分钟";
        }
        wkVBinding.burnTimeDescTv.setText("消息在阅读后 " + timeStr + " 自动销毁");
    }
}
