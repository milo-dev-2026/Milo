package com.chat.uikit.groupmanage.adapter;

import android.text.TextUtils;
import android.view.View;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import androidx.core.content.ContextCompat;

import com.chad.library.adapter.base.BaseMultiItemQuickAdapter;
import com.chad.library.adapter.base.viewholder.BaseViewHolder;
import com.chat.base.msgitem.WKChannelMemberRole;
import com.chat.base.ui.components.AvatarView;
import com.chat.uikit.R;
import com.chat.uikit.groupmanage.GroupManageItemEntity;
import com.xinbida.wukongim.entity.WKChannelMember;
import com.xinbida.wukongim.entity.WKChannelType;

import java.util.List;

/**
 * 群管理员列表适配器
 * 支持两种项类型: 管理员项 和 添加管理员按钮项
 */
public class GroupManageAdapter extends BaseMultiItemQuickAdapter<GroupManageItemEntity, BaseViewHolder> {

    private boolean isOwner = false;

    public GroupManageAdapter(@Nullable List<GroupManageItemEntity> data) {
        super(data);
        addItemType(GroupManageItemEntity.TYPE_ADMIN, R.layout.item_group_manager);
        addItemType(GroupManageItemEntity.TYPE_ADD, R.layout.item_group_manager_add);
    }

    /**
     * 设置当前用户是否为群主
     * 群主可看到管理员的移除按钮
     */
    public void setOwner(boolean owner) {
        this.isOwner = owner;
    }

    @Override
    protected void convert(@NonNull BaseViewHolder helper, GroupManageItemEntity item) {
        if (item == null) return;
        switch (item.getItemType()) {
            case GroupManageItemEntity.TYPE_ADMIN: {
                WKChannelMember member = item.getMember();
                if (member == null) return;

                AvatarView avatarView = helper.getView(R.id.avatarView);
                avatarView.setSize(45f);
                avatarView.showAvatar(member.memberUID, WKChannelType.PERSONAL, member.memberAvatarCacheKey);

                String showName = member.memberRemark;
                if (TextUtils.isEmpty(showName)) {
                    showName = member.memberName;
                }
                helper.setText(R.id.nameTv, showName);

                TextView roleTv = helper.getView(R.id.roleTv);
                if (member.role == WKChannelMemberRole.admin) {
                    // 群主
                    roleTv.setText(R.string.group_owner);
                    roleTv.setTextColor(ContextCompat.getColor(getContext(), R.color.colorGroupOwner));
                    roleTv.setVisibility(View.VISIBLE);
                    // 群主不可被移除
                    helper.setGone(R.id.removeBtn, true);
                } else if (member.role == WKChannelMemberRole.manager) {
                    // 管理员
                    roleTv.setText(R.string.group_manager);
                    roleTv.setTextColor(ContextCompat.getColor(getContext(), R.color.colorAccent));
                    roleTv.setVisibility(View.VISIBLE);
                    // 群主可移除管理员
                    helper.setGone(R.id.removeBtn, !isOwner);
                } else {
                    roleTv.setVisibility(View.GONE);
                    helper.setGone(R.id.removeBtn, true);
                }
                break;
            }
            case GroupManageItemEntity.TYPE_ADD:
                // 添加管理员按钮项，布局已固定，无需额外处理
                break;
        }
    }
}
