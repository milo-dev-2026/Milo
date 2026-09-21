package com.chat.uikit.contacts;


import android.text.TextUtils;
import android.view.View;
import android.widget.Button;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.chad.library.adapter.base.BaseQuickAdapter;
import com.chad.library.adapter.base.viewholder.BaseViewHolder;
import com.chat.base.entity.NewFriendEntity;
import com.chat.base.entity.PopupMenuItem;
import com.chat.base.ui.Theme;
import com.chat.base.ui.components.AvatarView;
import com.chat.base.utils.WKDialogUtils;
import com.chat.uikit.R;
import com.xinbida.wukongim.entity.WKChannelType;

import java.util.ArrayList;
import java.util.List;

/**
 * 2019-11-30 12:11
 * 新朋友
 */
public class NewFriendAdapter extends BaseQuickAdapter<NewFriendEntity, BaseViewHolder> {
    IDelete iDelete;

    NewFriendAdapter(@Nullable List<NewFriendEntity> data, IDelete iDelete) {
        super(R.layout.item_new_friend_layout, data);
        this.iDelete = iDelete;
    }

    @Override
    protected void convert(@NonNull BaseViewHolder helper, NewFriendEntity item) {
        helper.setText(R.id.nameTv, item.apply_name);
        helper.setText(R.id.remarkTv, !TextUtils.isEmpty(item.remark) ? item.remark : getContext().getString(R.string.request_add_frined));
        // 状态显示：0=等待通过，1=已通过，2=已拒绝
        helper.setGone(R.id.statusTv, item.status == 0);
        if (item.status == 1) {
            helper.setText(R.id.statusTv, getContext().getString(R.string.agreed_apply));
        } else if (item.status == 2) {
            helper.setText(R.id.statusTv, getContext().getString(R.string.rejected_apply));
        }
        // 按钮显示控制：status==0 时显示按钮组
        helper.setGone(R.id.actionLayout, item.status != 0);
        // 好友申请(type=0)只显示同意按钮，入群申请(type=1)显示拒绝和通过两个按钮
        helper.setGone(R.id.rejectBtn, item.type != 1);
        helper.setGone(R.id.agreeBtn, false);
        showDialog(helper.getView(R.id.contentLayout), item);
        AvatarView avatarView = helper.getView(R.id.avatarView);
        avatarView.setSize(45f);
        avatarView.showAvatar(item.apply_uid, WKChannelType.PERSONAL);
        Button agreeButton = helper.getView(R.id.agreeBtn);
        if (agreeButton != null && agreeButton.getBackground() != null) {
            agreeButton.getBackground().setTint(Theme.colorAccount);
        }
    }


    private void showDialog(View view, NewFriendEntity item) {
        List<PopupMenuItem> list = new ArrayList<>();
        list.add(new PopupMenuItem(getContext().getString(R.string.base_delete), R.mipmap.msg_delete, () -> iDelete.onDelete(item)));
        WKDialogUtils.getInstance().setViewLongClickPopup(view,list);
    }

    interface IDelete {
        void onDelete(NewFriendEntity item);
    }
}
