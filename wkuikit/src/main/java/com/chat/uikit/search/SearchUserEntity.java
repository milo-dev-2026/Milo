package com.chat.uikit.search;

import com.chad.library.adapter.base.entity.MultiItemEntity;
import com.chat.uikit.enity.UserInfo;

public class SearchUserEntity implements MultiItemEntity {
    public int itemType;
    public int status = 0;
    public int exist;
    public boolean showApply = true;
    public UserInfo data;

    @Override
    public int getItemType() {
        return itemType;
    }
}
