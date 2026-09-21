package com.chat.uikit.chat;

import android.content.Intent;
import android.text.TextUtils;
import android.view.Gravity;
import android.view.View;
import android.widget.LinearLayout;
import android.widget.TextView;

import androidx.activity.result.ActivityResultLauncher;
import androidx.activity.result.contract.ActivityResultContracts;
import androidx.core.content.ContextCompat;

import com.chat.base.base.WKBaseActivity;
import com.chat.base.endpoint.EndpointCategory;
import com.chat.base.endpoint.EndpointManager;
import com.chat.base.endpoint.entity.ChatSettingCellMenu;
import com.chat.base.endpoint.entity.PrivacyMessageMenu;
import com.chat.base.net.HttpResponseCode;
import com.chat.base.ui.components.SwitchView;
import com.chat.base.utils.WKDialogUtils;
import com.chat.base.utils.WKToastUtils;
import com.chat.base.utils.singleclick.SingleClickUtil;
import com.chat.uikit.R;
import com.chat.uikit.contacts.ChooseContactsActivity;
import com.chat.uikit.contacts.service.FriendModel;
import com.chat.uikit.databinding.ActChatPersonalLayoutBinding;
import com.chat.uikit.message.MsgModel;
import com.chat.uikit.user.UserDetailActivity;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKChannel;
import com.xinbida.wukongim.entity.WKChannelType;

/**
 * 2019-12-08 12:26
 * 个人会话资料页面
 */
public class ChatPersonalActivity extends WKBaseActivity<ActChatPersonalLayoutBinding> {
    private String channelId;
    private WKChannel channel;

    @Override
    protected ActChatPersonalLayoutBinding getViewBinding() {
        return ActChatPersonalLayoutBinding.inflate(getLayoutInflater());
    }

    @Override
    protected void setTitle(TextView titleTv) {
        titleTv.setText(R.string.chat_info);
    }

    @Override
    protected void initPresenter() {
        channelId = getIntent().getStringExtra("channelId");
    }

    @Override
    protected void initView() {
        wkVBinding.refreshLayout.setEnableOverScrollDrag(true);
        wkVBinding.refreshLayout.setEnableLoadMore(false);
        wkVBinding.refreshLayout.setEnableRefresh(false);

        View findMsgView = (View) EndpointManager.getInstance().invoke("find_msg_view", new ChatSettingCellMenu(channelId, WKChannelType.PERSONAL, wkVBinding.findContentLayout));
        if (findMsgView != null) {
            wkVBinding.findContentLayout.removeAllViews();
            wkVBinding.findContentLayout.addView(findMsgView);
        }

        // 阅后即焚开关
        LinearLayout burnLayout = new LinearLayout(this);
        burnLayout.setOrientation(LinearLayout.VERTICAL);
        int paddingH = (int) (15 * getResources().getDisplayMetrics().density);
        int paddingV = (int) (12 * getResources().getDisplayMetrics().density);
        burnLayout.setPadding(paddingH, paddingV, paddingH, paddingV);
        burnLayout.setBackgroundResource(com.chat.base.R.color.white);

        LinearLayout burnRow = new LinearLayout(this);
        burnRow.setOrientation(LinearLayout.HORIZONTAL);
        burnRow.setGravity(Gravity.CENTER_VERTICAL);
        LinearLayout.LayoutParams rowParams = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT);
        burnRow.setLayoutParams(rowParams);

        TextView burnTv = new TextView(this);
        burnTv.setText(getString(R.string.burn_after_reading));
        burnTv.setTextSize(15);
        burnTv.setTextColor(getResources().getColor(com.chat.base.R.color.popupTextColor));
        LinearLayout.LayoutParams tvParams = new LinearLayout.LayoutParams(
                0, LinearLayout.LayoutParams.WRAP_CONTENT, 1);
        burnTv.setLayoutParams(tvParams);
        burnRow.addView(burnTv);

        SwitchView burnSwitch = new SwitchView(this);
        LinearLayout.LayoutParams switchParams = new LinearLayout.LayoutParams(
                (int) (50 * getResources().getDisplayMetrics().density),
                (int) (30 * getResources().getDisplayMetrics().density));
        burnSwitch.setLayoutParams(switchParams);
        burnRow.addView(burnSwitch);

        burnLayout.addView(burnRow);

        // 说明文字
        TextView descTv = new TextView(this);
        descTv.setText("对方阅读消息后，根据设置的时间自动销毁");
        descTv.setTextSize(12);
        descTv.setTextColor(getResources().getColor(com.chat.base.R.color.gray_888888));
        LinearLayout.LayoutParams descParams = new LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT);
        descParams.topMargin = (int) (4 * getResources().getDisplayMetrics().density);
        descTv.setLayoutParams(descParams);
        burnLayout.addView(descTv);

        burnSwitch.setOnCheckedChangeListener((buttonView, isChecked) -> {
            if (buttonView.isPressed()) {
                FriendModel.getInstance().updateUserSetting(channelId, "flame", isChecked ? 1 : 0, (code, msg) -> {
                    if (code != HttpResponseCode.success) {
                        burnSwitch.setChecked(!isChecked);
                        WKToastUtils.getInstance().showToastNormal(msg);
                    } else {
                        WKToastUtils.getInstance().showToastNormal(isChecked ? "已开启阅后即焚" : "已关闭阅后即焚");
                    }
                });
            }
        });
        wkVBinding.msgSettingLayout.addView(burnLayout);
    }

    @Override
    protected void initListener() {
        EndpointManager.getInstance().setMethod("chat_personal_activity", EndpointCategory.wkExitChat, object -> {
            if (object != null) {
                WKChannel channel = (WKChannel) object;
                if (channelId.equals(channel.channelID) && channel.channelType == WKChannelType.PERSONAL) {
                    finish();
                }
            }
            return null;
        });

        //免打扰
        wkVBinding.muteSwitchView.setOnCheckedChangeListener((compoundButton, b) -> {
            if (compoundButton.isPressed()) {
                FriendModel.getInstance().updateUserSetting(channelId, "mute", b ? 1 : 0, (code, msg) -> {
                    if (code != HttpResponseCode.success) {
                        wkVBinding.muteSwitchView.setChecked(!b);
                        showToast(msg);
                    }
                });
            }
        });
        //置顶
        wkVBinding.stickSwitchView.setOnCheckedChangeListener((compoundButton, b) -> {
            if (compoundButton.isPressed())
                FriendModel.getInstance().updateUserSetting(channelId, "top", b ? 1 : 0, (code, msg) -> {
                    if (code != HttpResponseCode.success) {
                        wkVBinding.stickSwitchView.setChecked(!b);
                        showToast(msg);
                    }
                });
        });
        wkVBinding.clearChatMsgLayout.setOnClickListener(v -> {
            String content = String.format(getString(R.string.clear_history_tip), channel == null ? "" : channel.channelName);

            Object object = EndpointManager.getInstance().invoke("is_register_msg_privacy_module", null);
            if (object instanceof PrivacyMessageMenu) {
                String showName = "";
                if (channel != null) {
                    if (TextUtils.isEmpty(channel.channelRemark)) {
                        showName = channel.channelName;
                    } else {
                        showName = channel.channelRemark;
                    }
                }
                String checkBoxText = String.format(getString(R.string.str_delete_message_also_to), showName);
                WKDialogUtils.getInstance().showCheckBoxDialog(this, getString(R.string.clear_history), content, checkBoxText, true, "", getString(R.string.base_delete), 0, ContextCompat.getColor(this, R.color.red), (index, isChecked) -> {
                    if (index == 1) {
                        if (isChecked) {
                            ((PrivacyMessageMenu) object).getIClick().clearChannelMsg(channelId, WKChannelType.PERSONAL);
                        } else {
                            MsgModel.getInstance().offsetMsg(channelId, WKChannelType.PERSONAL, null);
                            WKIM.getInstance().getMsgManager().clearWithChannel(channelId, WKChannelType.PERSONAL);
                            showToast(R.string.cleared);
                        }
                    }
                });
                return;
            }
            WKDialogUtils.getInstance().showDialog(this, getString(R.string.clear_history), content, true, "", getString(R.string.base_delete), 0, ContextCompat.getColor(this, R.color.red), new WKDialogUtils.IClickListener() {
                @Override
                public void onClick(int index) {
                    if (index == 1) {
                        MsgModel.getInstance().offsetMsg(channelId, WKChannelType.PERSONAL, null);
                        WKIM.getInstance().getMsgManager().clearWithChannel(channelId, WKChannelType.PERSONAL);
                        showToast(R.string.cleared);
                    }
                }
            });
        });
        // 点击+号选择联系人共同加入群聊
        SingleClickUtil.onSingleClick(wkVBinding.addIv, view1 -> {
            Intent intent = new Intent(ChatPersonalActivity.this, ChooseContactsActivity.class);
            intent.putExtra("unSelectUids", channelId);
            intent.putExtra("isIncludeUids", true);
            chooseCardResultLac.launch(intent);
        });
        // 点击头像跳转个人名片页面
        SingleClickUtil.onSingleClick(wkVBinding.avatarView, view1 -> {
            Intent intent = new Intent(ChatPersonalActivity.this, UserDetailActivity.class);
            intent.putExtra("uid", channelId);
            startActivity(intent);
        });
    }

    @Override
    protected void initData() {
        super.initData();

        if (com.chat.base.config.WKSystemAccount.isSystemAccount(channelId)) {
            Intent intent = new Intent(this, UserDetailActivity.class);
            intent.putExtra("uid", channelId);
            startActivity(intent);
            finish();
            return;
        }
        channel = WKIM.getInstance().getChannelManager().getChannel(channelId, WKChannelType.PERSONAL);
        if (channel != null) {
            wkVBinding.avatarView.showAvatar(channel);
            wkVBinding.nameTv.setText(TextUtils.isEmpty(channel.channelRemark) ? channel.channelName : channel.channelRemark);
            wkVBinding.muteSwitchView.setChecked(channel.mute == 1);
            wkVBinding.stickSwitchView.setChecked(channel.top == 1);
        }
    }

    ActivityResultLauncher<Intent> chooseCardResultLac = registerForActivityResult(new ActivityResultContracts.StartActivityForResult(), result -> {
        if (result.getResultCode() == RESULT_OK) {
            finish();
        }
    });

    @Override
    public void finish() {
        super.finish();
        EndpointManager.getInstance().remove("chat_personal_activity");
    }
}
