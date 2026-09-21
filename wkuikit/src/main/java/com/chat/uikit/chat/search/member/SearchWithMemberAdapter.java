package com.chat.uikit.chat.search.member;

import android.text.TextUtils;
import android.widget.TextView;

import androidx.annotation.NonNull;

import com.chad.library.adapter.base.BaseQuickAdapter;
import com.chad.library.adapter.base.viewholder.BaseViewHolder;
import com.chat.base.entity.GlobalMessage;
import com.chat.base.ui.components.AvatarView;
import com.chat.base.utils.WKTimeUtils;
import com.chat.uikit.R;
import com.xinbida.wukongim.WKIM;
import com.xinbida.wukongim.entity.WKChannelType;
import com.xinbida.wukongim.msgmodel.WKMessageContent;

import org.json.JSONObject;

public class SearchWithMemberAdapter extends BaseQuickAdapter<GlobalMessage, BaseViewHolder> {
    String name;
    String avatarKey;

    public SearchWithMemberAdapter(String name, String avatarKey) {
        super(R.layout.item_search_with_member_layout);
        this.name = name;
        this.avatarKey = avatarKey;
    }

    @Override
    protected void convert(@NonNull BaseViewHolder baseViewHolder, GlobalMessage msg) {
        WKMessageContent msgModel = decodeMessageContent(msg);
        long msgTime = msg.getTimestamp();
        if (msgModel != null)
            baseViewHolder.setText(R.id.contentTv, msgModel.getDisplayContent());
        TextView msgTimeTv = baseViewHolder.getView(R.id.timeTv);
        String timeSpace = WKTimeUtils.getInstance().getTimeString(msgTime * 1000);
        msgTimeTv.setText(timeSpace);
        baseViewHolder.setText(R.id.nameTv, name);
        AvatarView avatarView = baseViewHolder.getView(R.id.avatarView);
        avatarView.showAvatar(msg.getFrom_uid(), WKChannelType.PERSONAL, avatarKey);
    }

    private WKMessageContent decodeMessageContent(GlobalMessage msg) {
        if (msg == null || TextUtils.isEmpty(msg.getContent())) {
            return null;
        }
        try {
            JSONObject jsonObject = new JSONObject(msg.getContent());
            return WKIM.getInstance().getMsgManager().getMsgContentModel(jsonObject);
        } catch (Exception e) {
            return null;
        }
    }
}
