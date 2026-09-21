package com.chat.uikit.trtc

import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import com.chat.base.msgitem.WKChatBaseProvider
import com.chat.base.msgitem.WKChatIteMsgFromType
import com.chat.base.msgitem.WKRTCType
import com.chat.base.msgitem.WKUIChatMsgItemEntity
import com.chat.uikit.R

/**
 * RTC 信令消息渲染器（不显示，静默处理）
 * 通话信令（邀请/接听/取消/挂断等）属于控制消息，不显示在聊天列表中
 */
class RTCSignalProvider : WKChatBaseProvider() {

    override fun getChatViewItem(parentView: ViewGroup, from: WKChatIteMsgFromType): View? {
        return LayoutInflater.from(context).inflate(R.layout.chat_rtc_signal_msg, parentView, false)
    }

    override fun setData(
        adapterPosition: Int,
        parentView: View,
        uiChatMsgItemEntity: WKUIChatMsgItemEntity,
        from: WKChatIteMsgFromType
    ) {
        // 信令消息不显示内容
    }

    override val itemViewType: Int
        get() = WKRTCType.wk_video_call_received
}