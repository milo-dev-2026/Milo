package com.chat.uikit.chat.pin;

import android.text.TextUtils;
import android.widget.TextView;

import androidx.annotation.NonNull;

import com.chad.library.adapter.base.BaseQuickAdapter;
import com.chad.library.adapter.base.viewholder.BaseViewHolder;
import com.chat.base.ui.components.AvatarView;
import com.chat.base.utils.WKTimeUtils;
import com.chat.uikit.R;
import com.xinbida.wukongim.entity.WKChannelType;
import com.xinbida.wukongim.entity.WKMsg;
import com.xinbida.wukongim.msgmodel.WKImageContent;
import com.xinbida.wukongim.msgmodel.WKTextContent;
import com.xinbida.wukongim.msgmodel.WKVideoContent;
import com.xinbida.wukongim.msgmodel.WKVoiceContent;

import java.util.List;

/**
 * 置顶消息列表适配器
 */
public class MessagePinAdapter extends BaseQuickAdapter<WKMsg, BaseViewHolder> {

    public MessagePinAdapter(List<WKMsg> data) {
        super(R.layout.item_message_pin, data);
    }

    @Override
    protected void convert(@NonNull BaseViewHolder helper, WKMsg item) {
        if (item == null) return;

        AvatarView avatarView = helper.getView(R.id.avatarView);
        TextView senderNameTv = helper.getView(R.id.senderNameTv);
        TextView contentTv = helper.getView(R.id.contentTv);
        TextView pinTimeTv = helper.getView(R.id.pinTimeTv);

        // 发送者头像
        if (avatarView != null) {
            avatarView.setSize(44);
            avatarView.showAvatar(item.fromUID, WKChannelType.PERSONAL);
        }

        // 发送者名称
        String senderName = "";
        if (item.getFrom() != null && !TextUtils.isEmpty(item.getFrom().channelRemark)) {
            senderName = item.getFrom().channelRemark;
        } else if (item.getFrom() != null && !TextUtils.isEmpty(item.getFrom().channelName)) {
            senderName = item.getFrom().channelName;
        } else if (!TextUtils.isEmpty(item.fromUID)) {
            senderName = item.fromUID;
        }
        senderNameTv.setText(senderName);

        // 消息内容预览
        String content = "";
        if (item.baseContentMsgModel instanceof WKTextContent) {
            content = ((WKTextContent) item.baseContentMsgModel).content;
        } else if (item.baseContentMsgModel instanceof WKImageContent) {
            content = "[图片]";
        } else if (item.baseContentMsgModel instanceof WKVideoContent) {
            content = "[视频]";
        } else if (item.baseContentMsgModel instanceof WKVoiceContent) {
            content = "[语音]";
        } else if (item.baseContentMsgModel != null) {
            content = item.baseContentMsgModel.getDisplayContent();
        }
        if (content == null) content = "";
        contentTv.setText(content);

        // 置顶时间（使用消息时间戳）
        String timeStr = WKTimeUtils.getInstance().getTimeString(item.timestamp * 1000L);
        pinTimeTv.setText(timeStr);
    }
}
