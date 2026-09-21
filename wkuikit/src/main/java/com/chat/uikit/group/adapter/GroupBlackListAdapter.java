package com.chat.uikit.group.adapter;

import android.text.TextUtils;
import android.view.View;

import androidx.annotation.NonNull;

import com.chad.library.adapter.base.BaseQuickAdapter;
import com.chad.library.adapter.base.viewholder.BaseViewHolder;
import com.chat.base.ui.components.AvatarView;
import com.chat.uikit.R;
import com.xinbida.wukongim.entity.WKChannelMember;
import com.xinbida.wukongim.entity.WKChannelType;

import java.util.List;

/**
 * 群黑名单适配器
 */
public class GroupBlackListAdapter extends BaseQuickAdapter<WKChannelMember, BaseViewHolder> {

    public GroupBlackListAdapter(List<WKChannelMember> list) {
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

        // 隐藏角色标签
        helper.setGone(R.id.roleTv, true);

        // 显示移除按钮
        helper.setVisible(R.id.removeIv, true);
    }
}
