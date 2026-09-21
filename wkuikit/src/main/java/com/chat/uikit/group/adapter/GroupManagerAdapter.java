package com.chat.uikit.group.adapter;

import android.text.TextUtils;
import android.view.View;

import androidx.annotation.NonNull;

import com.chad.library.adapter.base.BaseQuickAdapter;
import com.chad.library.adapter.base.viewholder.BaseViewHolder;
import com.chat.base.msgitem.WKChannelMemberRole;
import com.chat.base.ui.components.AvatarView;
import com.chat.base.ui.components.RoundTextView;
import com.chat.uikit.R;
import com.xinbida.wukongim.entity.WKChannelMember;
import com.xinbida.wukongim.entity.WKChannelType;

import java.util.List;

/**
 * 群管理员适配器
 */
public class GroupManagerAdapter extends BaseQuickAdapter<WKChannelMember, BaseViewHolder> {

    public GroupManagerAdapter(List<WKChannelMember> list) {
        super(R.layout.item_group_manager_layout, list);
        addChildClickViewIds(R.id.removeIv);
    }

    @Override
    protected void convert(@NonNull BaseViewHolder helper, WKChannelMember item) {
        String showName = item.memberRemark;
        if (TextUtils.isEmpty(showName)) {
            showName = item.memberName;
        }
        helper.setText(R.id.nameTv, showName);

        // 设置头像
        AvatarView avatarView = helper.getView(R.id.avatarView);
        avatarView.showAvatar(item.memberUID, WKChannelType.PERSONAL, item.memberAvatarCacheKey);

        // 设置角色标签
        RoundTextView roleTv = helper.getView(R.id.roleTv);
        if (item.role == WKChannelMemberRole.admin) {
            roleTv.setText(R.string.group_owner);
            roleTv.setVisibility(View.VISIBLE);
        } else if (item.role == WKChannelMemberRole.manager) {
            roleTv.setText(R.string.group_admin);
            roleTv.setVisibility(View.VISIBLE);
        } else {
            roleTv.setVisibility(View.GONE);
        }

        // 创建者(群主)不能被移除
        helper.setVisible(R.id.removeIv, item.role != WKChannelMemberRole.admin);
    }
}
