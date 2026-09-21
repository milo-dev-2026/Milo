package com.chat.uikit.groupmanage;

import com.chad.library.adapter.base.entity.MultiItemEntity;
import com.xinbida.wukongim.entity.WKChannelMember;

/**
 * 群管理列表项实体
 * 支持两种类型: 管理员项(TYPE_ADMIN) 和 添加按钮项(TYPE_ADD)
 */
public class GroupManageItemEntity implements MultiItemEntity {

    public static final int TYPE_ADMIN = 0;
    public static final int TYPE_ADD = 1;

    private final int itemType;
    private WKChannelMember member;

    public GroupManageItemEntity(int itemType) {
        this.itemType = itemType;
    }

    public GroupManageItemEntity(int itemType, WKChannelMember member) {
        this.itemType = itemType;
        this.member = member;
    }

    @Override
    public int getItemType() {
        return itemType;
    }

    public WKChannelMember getMember() {
        return member;
    }

    public void setMember(WKChannelMember member) {
        this.member = member;
    }
}
