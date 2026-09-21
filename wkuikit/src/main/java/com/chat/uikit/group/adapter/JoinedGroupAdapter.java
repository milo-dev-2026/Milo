package com.chat.uikit.group.adapter;

import android.text.TextUtils;

import androidx.annotation.NonNull;

import com.chad.library.adapter.base.BaseQuickAdapter;
import com.chad.library.adapter.base.viewholder.BaseViewHolder;
import com.chat.base.ui.components.AvatarView;
import com.chat.uikit.R;
import com.chat.uikit.group.GroupEntity;
import com.xinbida.wukongim.entity.WKChannelType;

import java.util.List;

/**
 * 我加入的群适配器
 */
public class JoinedGroupAdapter extends BaseQuickAdapter<GroupEntity, BaseViewHolder> {

    public JoinedGroupAdapter() {
        super(R.layout.item_group_layout);
    }

    @Override
    protected void convert(@NonNull BaseViewHolder holder, GroupEntity item) {
        String showName = TextUtils.isEmpty(item.remark) ? item.name : item.remark;
        holder.setText(R.id.nameTv, showName);
        AvatarView avatarView = holder.getView(R.id.avatarView);
        avatarView.showAvatar(item.group_no, WKChannelType.GROUP, item.avatar);
    }
}
