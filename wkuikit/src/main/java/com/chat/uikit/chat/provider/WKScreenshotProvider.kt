package com.chat.uikit.chat.provider

import android.text.SpannableString
import android.text.TextUtils
import android.view.View
import android.view.ViewGroup
import android.widget.TextView
import androidx.core.content.ContextCompat
import com.chad.library.adapter.base.viewholder.BaseViewHolder
import com.chat.base.R
import com.chat.base.config.WKConfig
import com.chat.base.msg.ChatAdapter
import com.chat.base.msgitem.WKChatBaseProvider
import com.chat.base.msgitem.WKChatIteMsgFromType
import com.chat.base.msgitem.WKContentType
import com.chat.base.msgitem.WKUIChatMsgItemEntity
import com.chat.base.ui.components.SystemMsgBackgroundColorSpan
import com.chat.base.utils.AndroidUtilities
import com.xinbida.wukongim.entity.WKChannelType
import org.json.JSONObject

/**
 * 截图提醒渲染：以居中系统提示展示在会话窗口内（不再以文本气泡/独立会话提醒出现）。
 */
class WKScreenshotProvider : WKChatBaseProvider() {
    override fun getChatViewItem(parentView: ViewGroup, from: WKChatIteMsgFromType): View? {
        return null
    }

    override val layoutId: Int
        get() = R.layout.chat_system_layout

    override fun setData(
        adapterPosition: Int,
        parentView: View,
        uiChatMsgItemEntity: WKUIChatMsgItemEntity,
        from: WKChatIteMsgFromType
    ) {
    }

    override fun convert(
        helper: BaseViewHolder,
        item: WKUIChatMsgItemEntity
    ) {
        super.convert(helper, item)
        var content = ""
        var contentFromUid = ""
        if (!TextUtils.isEmpty(item.wkMsg.content)) {
            try {
                val jsonObject = JSONObject(item.wkMsg.content)
                content = jsonObject.optString("text")
                contentFromUid = jsonObject.optString("from")
            } catch (e: Exception) {
                content = item.wkMsg.content
            }
        }
        if (TextUtils.isEmpty(content)) {
            content = item.wkMsg.baseContentMsgModel?.getDisplayContent() ?: ""
        }
        // 单聊时根据发送者动态显示文本：自己发的显示"你已截图"，对方发的显示"对方已截图"。
        // 三重判定：本机发送记录 / 消息内容里的 from / msg.fromUID，任意一个命中即算自己。
        if (item.wkMsg.channelType == WKChannelType.PERSONAL) {
            val myUid = WKConfig.getInstance().uid
            val modelFromUid = (item.wkMsg.baseContentMsgModel
                    as? com.chat.uikit.chat.msgmodel.WKScreenshotContent)?.fromUid
            val isSelf = com.chat.uikit.chat.ScreenShotHelper.isSelfScreenshotMsg(item.wkMsg.clientMsgNO)
                    || (!TextUtils.isEmpty(myUid) && (myUid == item.wkMsg.fromUID
                    || myUid == contentFromUid || myUid == modelFromUid))
            content = if (isSelf) context.getString(R.string.screenshot_single_self)
            else context.getString(R.string.screenshot_single_text)
        }
        val rootView = helper.getView<View>(R.id.systemRootView)
        rootView?.setOnClickListener {
            val chatAdapter = getAdapter() as? ChatAdapter
            chatAdapter?.conversationContext?.hideSoftKeyboard()
        }
        val textView = helper.getView<TextView>(R.id.contentTv)
        textView.setShadowLayer(AndroidUtilities.dp(5f).toFloat(), 0f, 0f, 0)
        if (!TextUtils.isEmpty(content)) {
            val str = SpannableString(content)
            str.setSpan(
                SystemMsgBackgroundColorSpan(
                    ContextCompat.getColor(
                        context,
                        R.color.colorSystemBg
                    ), AndroidUtilities.dp(5f), AndroidUtilities.dp((2 * 5).toFloat())
                ), 0, content.length, 0
            )
            textView.text = str
        } else {
            textView.text = ""
        }
    }

    override val itemViewType: Int
        get() = WKContentType.screenshot
}
