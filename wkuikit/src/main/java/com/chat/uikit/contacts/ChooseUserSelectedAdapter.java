package com.chat.uikit.contacts;

import android.content.Context;
import android.view.View;
import android.widget.TextView;

import androidx.annotation.NonNull;

import com.chad.library.adapter.base.BaseQuickAdapter;
import com.chad.library.adapter.base.viewholder.BaseViewHolder;
import com.chat.base.ui.components.AvatarView;
import com.chat.uikit.R;

import org.jetbrains.annotations.NotNull;

import java.util.List;

/**
 * 2020-09-25 16:28
 * 已选中人列表
 */
public class ChooseUserSelectedAdapter extends BaseQuickAdapter<FriendUIEntity, BaseViewHolder> {
    int[] colors;
    IGetEdit iGetEdit;

    public ChooseUserSelectedAdapter(Context context, IGetEdit iGetEdit) {
        super(R.layout.item_choose_user_selected);
        this.iGetEdit = iGetEdit;
        colors = context.getResources().getIntArray(R.array.name_colors);
    }

    @Override
    protected void convert(@NonNull BaseViewHolder holder, FriendUIEntity item, @NonNull List<?> payloads) {
        super.convert(holder, item, payloads);
        // 局部刷新暂不特殊处理，使用全局刷新即可
    }

    @Override
    protected void convert(@NotNull BaseViewHolder baseViewHolder, FriendUIEntity friendUIEntity) {
        AvatarView avatarView = baseViewHolder.getView(R.id.avatarView);
        avatarView.showAvatar(friendUIEntity.channel);
        avatarView.setSize(50, 8f);
        avatarView.setStrokeWidth(0);

        // 删除角标（可选，默认隐藏，点击头像直接取消选择）
        TextView deleteIv = baseViewHolder.getView(R.id.deleteIv);
        deleteIv.setVisibility(View.GONE);
    }

    public interface IGetEdit {
        void onDeleted(String uid);

        void searchUser(String key);
    }

}
