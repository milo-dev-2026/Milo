package com.chat.uikit.chat;

import android.content.Context;
import android.content.Intent;
import android.view.View;
import android.widget.TextView;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.net.HttpResponseCode;
import com.chat.base.ui.components.SwitchView;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.contacts.service.FriendModel;
import com.chat.uikit.databinding.ActivityChatMessagePrivacyBinding;
import com.xinbida.wukongim.entity.WKChannelType;

/**
 * 单聊消息隐私设置页面
 * 阅后即焚、消息免打扰、置顶等设置
 */
public class ChatMessagePrivacyActivity extends WKBaseActivity<ActivityChatMessagePrivacyBinding> {

    private static final String KEY_CHANNEL_ID = "channel_id";
    private static final String KEY_CHANNEL_NAME = "channel_name";

    private String channelId;
    private String channelName;
    private int burnTime = 10; // 默认10秒
    private boolean burnEnabled = false;

    public static void startChatMessagePrivacy(Context context, String channelId, String channelName) {
        Intent intent = new Intent(context, ChatMessagePrivacyActivity.class);
        intent.putExtra(KEY_CHANNEL_ID, channelId);
        intent.putExtra(KEY_CHANNEL_NAME, channelName);
        context.startActivity(intent);
    }

    @Override
    protected ActivityChatMessagePrivacyBinding getViewBinding() {
        return ActivityChatMessagePrivacyBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.message_privacy);
    }

    @Override
    protected void initPresenter() {
        if (getIntent() != null) {
            channelId = getIntent().getStringExtra(KEY_CHANNEL_ID);
            channelName = getIntent().getStringExtra(KEY_CHANNEL_NAME);
        }
    }

    @Override
    protected void initView() {
        updateBurnTimeUI();
    }

    @Override
    protected void initListener() {
        // 阅后即焚开关
        wkVBinding.burnSwitchView.setOnCheckedChangeListener(new SwitchView.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(View view, boolean isChecked) {
                updateBurnAfterReading(isChecked);
            }
        });

        // 阅后即焚时间选择
        SingleClickUtil.onSingleClick(wkVBinding.time5Layout, v -> selectBurnTime(5));
        SingleClickUtil.onSingleClick(wkVBinding.time10Layout, v -> selectBurnTime(10));
        SingleClickUtil.onSingleClick(wkVBinding.time30Layout, v -> selectBurnTime(30));
        SingleClickUtil.onSingleClick(wkVBinding.time60Layout, v -> selectBurnTime(60));

        // 消息免打扰
        wkVBinding.muteSwitchView.setOnCheckedChangeListener(new SwitchView.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(View view, boolean isChecked) {
                updateMuteSetting(isChecked);
            }
        });

        // 置顶
        wkVBinding.topSwitchView.setOnCheckedChangeListener(new SwitchView.OnCheckedChangeListener() {
            @Override
            public void onCheckedChanged(View view, boolean isChecked) {
                updateTopSetting(isChecked);
            }
        });
    }

    /**
     * 更新阅后即焚设置
     */
    private void updateBurnAfterReading(boolean isChecked) {
        FriendModel.getInstance().updateUserSetting(channelId, "flame", isChecked ? 1 : 0, (code, msg) -> {
            if (code != HttpResponseCode.success) {
                wkVBinding.burnSwitchView.setChecked(!isChecked);
                WKToastUtils.getInstance().showToastNormal(msg);
            } else {
                burnEnabled = isChecked;
                wkVBinding.burnTimeExpandLayout.setExpanded(isChecked);
                WKToastUtils.getInstance().showToastNormal(isChecked ? "已开启阅后即焚" : "已关闭阅后即焚");
            }
        });
    }

    /**
     * 选择阅后即焚时间
     */
    private void selectBurnTime(int time) {
        burnTime = time;
        updateBurnTimeUI();
        // 保存阅后即焚时间设置
        FriendModel.getInstance().updateUserSetting(channelId, "flame_second", time, (code, msg) -> {
            if (code != HttpResponseCode.success) {
                WKToastUtils.getInstance().showToastNormal(msg);
            }
        });
    }

    /**
     * 更新阅后即焚时间UI
     */
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
        wkVBinding.burnDescTv.setText("消息在阅读后 " + timeStr + " 自动销毁");
    }

    /**
     * 更新免打扰设置
     */
    private void updateMuteSetting(boolean isChecked) {
        FriendModel.getInstance().updateUserSetting(channelId, "mute", isChecked ? 1 : 0, (code, msg) -> {
            if (code != HttpResponseCode.success) {
                wkVBinding.muteSwitchView.setChecked(!isChecked);
                WKToastUtils.getInstance().showToastNormal(msg);
            }
        });
    }

    /**
     * 更新置顶设置
     */
    private void updateTopSetting(boolean isChecked) {
        FriendModel.getInstance().updateUserSetting(channelId, "top", isChecked ? 1 : 0, (code, msg) -> {
            if (code != HttpResponseCode.success) {
                wkVBinding.topSwitchView.setChecked(!isChecked);
                WKToastUtils.getInstance().showToastNormal(msg);
            }
        });
    }
}
