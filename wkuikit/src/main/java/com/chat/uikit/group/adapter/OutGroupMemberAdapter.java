package com.chat.uikit.group.adapter;

import android.text.TextUtils;

import androidx.annotation.NonNull;

import com.chad.library.adapter.base.BaseQuickAdapter;
import com.chad.library.adapter.base.viewholder.BaseViewHolder;
import com.chat.base.ui.components.AvatarView;
import com.chat.base.utils.WKTimeUtils;
import com.chat.uikit.R;
import com.xinbida.wukongim.entity.WKChannelMember;
import com.xinbida.wukongim.entity.WKChannelType;

import java.text.SimpleDateFormat;
import java.util.Date;
import java.util.List;
import java.util.Locale;

/**
 * 已退群成员适配器
 */
public class OutGroupMemberAdapter extends BaseQuickAdapter<WKChannelMember, BaseViewHolder> {

    private final SimpleDateFormat dateFormat;

    public OutGroupMemberAdapter(List<WKChannelMember> list) {
        super(R.layout.item_out_group_member_layout, list);
        dateFormat = new SimpleDateFormat("yyyy-MM-dd HH:mm", Locale.getDefault());
    }

    @Override
    protected void convert(@NonNull BaseViewHolder helper, WKChannelMember item) {
        String showName = item.memberRemark;
        if (TextUtils.isEmpty(showName)) {
            showName = item.memberName;
        }
        if (TextUtils.isEmpty(showName)) {
            showName = item.memberUID;
        }
        helper.setText(R.id.nameTv, showName);

        // 设置头像
        AvatarView avatarView = helper.getView(R.id.avatarView);
        avatarView.showAvatar(item.memberUID, WKChannelType.PERSONAL, item.memberAvatarCacheKey);

        // 设置退出时间（使用 updatedAt 作为退出时间参考）
        String exitTime = "";
        try {
            long time = Long.parseLong(item.updatedAt);
            if (time > 0) {
                // 如果时间戳是秒级，转换为毫秒
                if (String.valueOf(time).length() < 13) {
                    time = time * 1000;
                }
                exitTime = dateFormat.format(new Date(time));
            }
        } catch (Exception e) {
            // updatedAt 可能为 String 格式或为空，解析失败时不显示时间
        }
        helper.setText(R.id.timeTv, exitTime);
    }
}
