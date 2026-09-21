package com.chat.uikit.chat.provider

import android.text.TextUtils
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.TextView
import androidx.appcompat.widget.AppCompatImageView
import androidx.core.content.ContextCompat
import com.chat.base.msgitem.WKChatBaseProvider
import com.chat.base.msgitem.WKChatIteMsgFromType
import com.chat.base.msgitem.WKMsgBgType
import com.chat.base.msgitem.WKRTCType
import com.chat.base.msgitem.WKUIChatMsgItemEntity
import com.chat.base.ui.Theme
import com.chat.base.utils.singleclick.SingleClickUtil
import com.chat.base.views.BubbleLayout
import com.chat.uikit.R
import com.chat.uikit.trtc.RTCMsgContent

/**
 * P2P 通话消息渲染器
 * 显示通话结果（已结束/取消/未接听/拒绝）
 */
class WKCallProvider : WKChatBaseProvider() {

    override fun getChatViewItem(parentView: ViewGroup, from: WKChatIteMsgFromType): View? {
        return LayoutInflater.from(context).inflate(R.layout.chat_item_p2p_video_call, parentView, false)
    }

    override val itemViewType: Int
        get() = WKRTCType.WK_P2P_CALL

    override fun setData(
        adapterPosition: Int,
        parentView: View,
        uiChatMsgItemEntity: WKUIChatMsgItemEntity,
        from: WKChatIteMsgFromType
    ) {
        android.util.Log.d("WKCallProvider", "setData: from=$from, msgType=${uiChatMsgItemEntity.wkMsg.type}, contentModel=${uiChatMsgItemEntity.wkMsg.baseContentMsgModel?.javaClass?.simpleName}")
        val contentLayout = parentView.findViewById<LinearLayout>(R.id.contentLayout)
        val bubbleLayout = parentView.findViewById<BubbleLayout>(R.id.callView)
        val typeIv = parentView.findViewById<AppCompatImageView>(R.id.typeIv)
        val contentTv = parentView.findViewById<TextView>(R.id.contentTv)

        val content = uiChatMsgItemEntity.wkMsg.baseContentMsgModel as? RTCMsgContent ?: return

        // 根据发送/接收设置布局方向和颜色
        if (from == WKChatIteMsgFromType.RECEIVED) {
            contentLayout.gravity = Gravity.START
            Theme.setColorFilter(context, typeIv, R.color.receive_text_color)
            contentTv.setTextColor(ContextCompat.getColor(context, R.color.receive_text_color))
        } else {
            contentLayout.gravity = Gravity.END
            contentTv.setTextColor(ContextCompat.getColor(context, R.color.white_abs))
            Theme.setColorFilter(context, typeIv, R.color.white_abs)
        }

        // 设置通话类型图标
        val iconRes = if (content.callType == RTCMsgContent.CALL_TYPE_VIDEO)
            R.mipmap.chat_calls_video else R.mipmap.chat_calls_voice
        typeIv.setImageResource(iconRes)

        // 设置气泡背景
        bubbleLayout.setAll(
            getMsgBgType(uiChatMsgItemEntity.previousMsg, uiChatMsgItemEntity.wkMsg, uiChatMsgItemEntity.nextMsg),
            from, uiChatMsgItemEntity.wkMsg.type
        )

        // 根据通话结果设置文本
        val text = getCallResultText(content, from)
        contentTv.text = text

        // 点击重新发起通话
        SingleClickUtil.onSingleClick(bubbleLayout) {
            val chatAdapter = getAdapter() as? com.chat.base.msg.ChatAdapter ?: return@onSingleClick
            val isVideo = content.callType == RTCMsgContent.CALL_TYPE_VIDEO

            val rtcMenu = com.chat.base.endpoint.entity.RTCMenu(
                chatAdapter.conversationContext,
                if (isVideo) 1 else 0
            )
            com.chat.base.endpoint.EndpointManager.getInstance()
                .invoke("wk_p2p_call", rtcMenu)
        }

        addLongClick(bubbleLayout, uiChatMsgItemEntity)
    }

    private fun getCallResultText(content: RTCMsgContent, from: WKChatIteMsgFromType): String {
        val isReceived = from == WKChatIteMsgFromType.RECEIVED
        return when (content.resultType) {
            RTCMsgContent.RESULT_NORMAL -> {
                val time = formatDuration(content.second)
                context.getString(R.string.call_time, time)
            }
            RTCMsgContent.RESULT_CANCEL -> {
                if (isReceived) context.getString(R.string.caller_cancel)
                else context.getString(R.string.my_cancel)
            }
            RTCMsgContent.RESULT_MISSED -> {
                if (isReceived) context.getString(R.string.caller_missed)
                else context.getString(R.string.my_missed)
            }
            RTCMsgContent.RESULT_DECLINED -> {
                if (isReceived) context.getString(R.string.caller_declined)
                else context.getString(R.string.my_declined)
            }
            RTCMsgContent.RESULT_BUSY -> {
                if (isReceived) context.getString(R.string.caller_busy)
                else context.getString(R.string.my_missed)
            }
            else -> ""
        }
    }

    private fun formatDuration(seconds: Int): String {
        val minutes = seconds / 60
        val secs = seconds % 60
        return String.format("%02d:%02d", minutes, secs)
    }

    override fun resetCellBackground(
        parentView: View,
        uiChatMsgItemEntity: WKUIChatMsgItemEntity,
        from: WKChatIteMsgFromType
    ) {
        super.resetCellBackground(parentView, uiChatMsgItemEntity, from)
        val bubbleLayout = parentView.findViewById<BubbleLayout>(R.id.callView)
        if (bubbleLayout != null) {
            bubbleLayout.setAll(
                getMsgBgType(uiChatMsgItemEntity.previousMsg, uiChatMsgItemEntity.wkMsg, uiChatMsgItemEntity.nextMsg),
                from, uiChatMsgItemEntity.wkMsg.type
            )
        }
    }
}
