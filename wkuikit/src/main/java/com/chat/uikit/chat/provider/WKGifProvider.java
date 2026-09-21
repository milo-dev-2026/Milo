package com.chat.uikit.chat.provider;

import android.view.View;
import android.view.ViewGroup;

import com.chat.base.msgitem.WKChatBaseProvider;
import com.chat.base.msgitem.WKChatIteMsgFromType;
import com.chat.base.msgitem.WKUIChatMsgItemEntity;
import com.xinbida.wukongim.message.type.WKMsgContentType;

public class WKGifProvider extends WKChatBaseProvider {
    public WKGifProvider() {
        super();
    }

    @Override
    public int getItemViewType() {
        return WKMsgContentType.WK_GIF;
    }

    @Override
    protected View getChatViewItem(ViewGroup parentView, WKChatIteMsgFromType from) {
        return null;
    }

    @Override
    protected void setData(int adapterPosition, View parentView, WKUIChatMsgItemEntity uiChatMsgItemEntity, WKChatIteMsgFromType from) {
    }
}