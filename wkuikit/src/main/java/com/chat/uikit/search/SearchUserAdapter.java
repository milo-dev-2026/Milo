package com.chat.uikit.search;

import android.text.SpannableStringBuilder;
import android.text.TextUtils;
import android.view.View;
import android.widget.TextView;

import androidx.annotation.NonNull;
import androidx.annotation.Nullable;

import com.chad.library.adapter.base.BaseMultiItemQuickAdapter;
import com.chad.library.adapter.base.viewholder.BaseViewHolder;
import com.chat.base.net.HttpResponseCode;
import com.chat.base.ui.Theme;
import com.chat.base.ui.components.AvatarView;
import com.chat.base.utils.StringUtils;
import com.chat.base.utils.WKDialogUtils;
import com.chat.uikit.R;
import com.chat.uikit.contacts.service.FriendModel;
import com.google.android.material.button.MaterialButton;
import com.xinbida.wukongim.entity.WKChannelType;

import java.util.List;

public class SearchUserAdapter extends BaseMultiItemQuickAdapter<SearchUserEntity, BaseViewHolder> {
    @Nullable
    private String searchKey;

    public SearchUserAdapter(@Nullable List<SearchUserEntity> data) {
        super(data);
        addItemType(0, R.layout.item_search_user_layout);
        addItemType(1, R.layout.item_nodata_layout);
    }

    public void setSearchKey(@Nullable String key) {
        this.searchKey = key;
        notifyItemRangeChanged(0, getItemCount());
    }

    @Override
    protected void convert(@NonNull BaseViewHolder helper, SearchUserEntity item) {
        switch (item.getItemType()) {
            case 1:
                break;
            case 0:
                AvatarView avatarView = helper.getView(R.id.avatarView);

                if (item.data != null) {
                    avatarView.setVisibility(View.VISIBLE);
                    avatarView.showAvatar(item.data.uid, WKChannelType.PERSONAL);
                }

                String name = item.data.name;
                if (TextUtils.isEmpty(name)) {
                    name = item.data.username;
                }
                if (TextUtils.isEmpty(name)) {
                    name = item.data.uid;
                }
                if (!TextUtils.isEmpty(searchKey) && !TextUtils.isEmpty(name)) {
                    helper.setText(R.id.nameTv, StringUtils.findSearch(Theme.colorAccount, name, searchKey));
                } else {
                    helper.setText(R.id.nameTv, name);
                }

                // 显示用户ID号（始终显示）
                String shortNo = item.data.short_no;
                TextView contentTv = helper.getView(R.id.contentTv);
                if (!TextUtils.isEmpty(shortNo)) {
                    SpannableStringBuilder builder = new SpannableStringBuilder("ID: ");
                    if (!TextUtils.isEmpty(searchKey) && shortNo.toLowerCase().contains(searchKey.toLowerCase())) {
                        builder.append(StringUtils.findSearch(Theme.colorAccount, shortNo, searchKey));
                    } else {
                        builder.append(shortNo);
                    }
                    contentTv.setText(builder);
                    contentTv.setVisibility(View.VISIBLE);
                } else {
                    contentTv.setVisibility(View.GONE);
                }

                // 隐藏临时标签
                TextView labelTv = helper.getView(R.id.labelTv);
                labelTv.setVisibility(View.GONE);

                // 添加好友按钮
                MaterialButton addFriendBtn = helper.getView(R.id.addFriendBtn);
                boolean isFriend = item.data.follow == 1;
                if (isFriend) {
                    addFriendBtn.setVisibility(View.GONE);
                } else {
                    addFriendBtn.setVisibility(View.VISIBLE);
                    addFriendBtn.setText(R.string.add_friends);
                    addFriendBtn.setEnabled(true);
                    addFriendBtn.setAlpha(1f);
                }

                addFriendBtn.setOnClickListener(v -> {
                    if (item.data == null) return;
                    String vercode = item.data.vercode != null ? item.data.vercode : "";
                    WKDialogUtils.getInstance().showInputDialog(getContext(),
                            getContext().getString(R.string.apply),
                            getContext().getString(R.string.input_remark),
                            "",
                            getContext().getString(R.string.input_remark),
                            20,
                            text -> FriendModel.getInstance().applyAddFriend(item.data.uid, vercode, text, (code, msg) -> {
                                if (code == HttpResponseCode.success) {
                                    addFriendBtn.setText(R.string.applyed);
                                    addFriendBtn.setEnabled(false);
                                    addFriendBtn.setAlpha(0.4f);
                                } else {
                                    com.chat.base.utils.WKToastUtils.getInstance().showToastNormal(msg);
                                }
                            }));
                });
                break;
        }
    }
}
