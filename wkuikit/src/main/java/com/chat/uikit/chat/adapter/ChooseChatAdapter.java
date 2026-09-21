package com.chat.uikit.chat.adapter;

import android.text.TextUtils;
import android.view.View;
import android.widget.ImageView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.chad.library.adapter.base.BaseQuickAdapter;
import com.chad.library.adapter.base.viewholder.BaseViewHolder;
import com.chat.base.ui.components.AvatarView;
import com.chat.uikit.R;
import com.chat.uikit.chat.ChooseChatActivity;
import com.xinbida.wukongim.WKIM;

import java.util.List;

/**
 * 2019-12-08 13:52
 * 选择会话适配器
 */
public class ChooseChatAdapter extends BaseQuickAdapter<ChooseChatActivity.ChooseChatEntity, BaseViewHolder> {
    public ChooseChatAdapter(@Nullable List<ChooseChatActivity.ChooseChatEntity> data) {
        super(R.layout.item_choose_chat_layout, data);
    }

    @Override
    protected void convert(@NonNull BaseViewHolder holder, ChooseChatActivity.ChooseChatEntity item, @NonNull List<?> payloads) {
        super.convert(holder, item, payloads);
        ChooseChatActivity.ChooseChatEntity entity = (ChooseChatActivity.ChooseChatEntity) payloads.get(0);
        if (entity != null) {
            ImageView checkBox = holder.getView(R.id.checkbox);
            checkBox.setSelected(item.isCheck);
        }
    }

    @Override
    protected void convert(@NonNull BaseViewHolder helper, ChooseChatActivity.ChooseChatEntity item) {
        ImageView checkBox = helper.getView(R.id.checkbox);
        checkBox.setSelected(item.isCheck);
        checkBox.setVisibility(View.VISIBLE);
        AvatarView avatarView = helper.getView(R.id.avatarView);
        if (item.uiConveursationMsg.getWkChannel() != null) {
            String showName = item.uiConveursationMsg.getWkChannel().channelRemark;
            if (TextUtils.isEmpty(showName))
                showName = item.uiConveursationMsg.getWkChannel().channelName;
            helper.setText(R.id.nameTv, showName);
            avatarView.showAvatar(item.uiConveursationMsg.getWkChannel());
            helper.setGone(R.id.banTv, !item.isBan);
            if (item.isForbidden || item.isBan) {
                helper.setGone(R.id.checkbox, true);
            } else {
                helper.setGone(R.id.checkbox, false);
            }
            helper.setGone(R.id.fullStaffingTv, !item.isForbidden);
        } else {
            //消息头像
            avatarView.showAvatar(item.uiConveursationMsg.channelID, item.uiConveursationMsg.channelType);
            WKIM.getInstance().getChannelManager().fetchChannelInfo(item.uiConveursationMsg.channelID, item.uiConveursationMsg.channelType);
            helper.setGone(R.id.fullStaffingTv, true);
            helper.setGone(R.id.checkbox, false);
        }

    }
}
