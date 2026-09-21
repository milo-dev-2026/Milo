package com.chat.richeditor.msg

import android.content.Intent
import android.graphics.Typeface
import android.graphics.drawable.Drawable
import android.text.Spannable
import android.text.SpannableStringBuilder
import android.text.Spanned
import android.text.style.AbsoluteSizeSpan
import android.text.style.ForegroundColorSpan
import android.text.style.ImageSpan
import android.text.style.StrikethroughSpan
import android.text.style.StyleSpan
import android.text.style.UnderlineSpan
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.TextView
import androidx.appcompat.widget.AppCompatTextView
import androidx.core.content.ContextCompat

import com.bumptech.glide.Glide
import com.bumptech.glide.request.target.CustomTarget
import com.bumptech.glide.request.transition.Transition
import com.chat.base.R
import com.chat.base.act.WKWebViewActivity
import com.chat.base.msgitem.WKChatBaseProvider
import com.chat.base.msgitem.WKChatIteMsgFromType
import com.chat.base.msgitem.WKContentType
import com.chat.base.msgitem.WKUIChatMsgItemEntity
import com.chat.base.ui.Theme
import com.chat.base.ui.components.AlignImageSpan
import com.chat.base.ui.components.NormalClickableContent
import com.chat.base.ui.components.NormalClickableSpan
import com.chat.base.views.BubbleLayout
import com.chat.richeditor.component.RichStyles
import com.chat.richeditor.component.span.ClickableMovementMethod
import com.chat.richeditor.component.util.WMColor
import com.chat.uikit.R as UiKitR
import com.xinbida.wukongim.WKIM
import com.xinbida.wukongim.entity.WKChannelType
import com.xinbida.wukongim.msgmodel.WKMessageContent
import com.xinbida.wukongim.msgmodel.WKMsgEntity

/**
 * 富文本消息 Provider
 */
class RichChatProvider : WKChatBaseProvider() {

    override val itemViewType: Int
        get() = WKContentType.richText

    override fun getChatViewItem(parentView: ViewGroup, from: WKChatIteMsgFromType): View? {
        return LayoutInflater.from(context).inflate(UiKitR.layout.chat_chat_rich, parentView, false)
    }

    override fun setData(
        adapterPosition: Int,
        parentView: View,
        uiChatMsgItemEntity: WKUIChatMsgItemEntity,
        from: WKChatIteMsgFromType
    ) {
        val contentTv = parentView.findViewById<AppCompatTextView>(UiKitR.id.contentTv)
        val receivedTextNameTv = parentView.findViewById<TextView>(UiKitR.id.receivedTextNameTv)
        val contentTvLayout = parentView.findViewById<BubbleLayout>(UiKitR.id.contentTvLayout)
        val contentLayout = parentView.findViewById<LinearLayout>(UiKitR.id.contentLayout)

        val richContent = uiChatMsgItemEntity.wkMsg.baseContentMsgModel as? RichTextContent

        // 设置气泡背景和样式
        resetCellBackground(parentView, uiChatMsgItemEntity, from)

        val textColor: Int
        if (from == WKChatIteMsgFromType.SEND) {
            contentTv?.setBackgroundResource(UiKitR.drawable.send_chat_text_bg)
            contentLayout?.gravity = Gravity.END
            receivedTextNameTv?.visibility = View.GONE
            textColor = ContextCompat.getColor(context, UiKitR.color.colorDark)
        } else {
            contentTv?.setBackgroundResource(UiKitR.drawable.received_chat_text_bg)
            setFromName(uiChatMsgItemEntity, from, receivedTextNameTv)
            contentLayout?.gravity = Gravity.START
            textColor = ContextCompat.getColor(context, UiKitR.color.receive_text_color)
        }
        contentTv?.setTextColor(textColor)

        // 构建富文本 Spannable
        if (richContent != null) {
            val spannable = buildRichSpannable(richContent, textColor, contentTv)
            contentTv?.text = spannable
            contentTv?.movementMethod = ClickableMovementMethod.getInstance()
        } else {
            contentTv?.text = uiChatMsgItemEntity.wkMsg.baseContentMsgModel?.content ?: ""
        }

        // 长按事件
        contentTv?.let { addLongClick(it, uiChatMsgItemEntity) }
    }

    override fun resetCellBackground(
        parentView: View,
        uiChatMsgItemEntity: WKUIChatMsgItemEntity,
        from: WKChatIteMsgFromType
    ) {
        super.resetCellBackground(parentView, uiChatMsgItemEntity, from)
        val contentTvLayout = parentView.findViewById<BubbleLayout>(UiKitR.id.contentTvLayout)
        val textContentLayout = parentView.findViewById<View>(UiKitR.id.textContentLayout)
        val msgTimeView = parentView.findViewById<View>(UiKitR.id.msgTimeView)
        if (textContentLayout == null || msgTimeView == null) {
            return
        }
        textContentLayout.layoutParams.width = getViewWidth(from, uiChatMsgItemEntity)
        val bgType = getMsgBgType(
            uiChatMsgItemEntity.previousMsg,
            uiChatMsgItemEntity.wkMsg,
            uiChatMsgItemEntity.nextMsg
        )
        contentTvLayout?.setAll(bgType, from, WKContentType.richText)
        if (textContentLayout.layoutParams.width < msgTimeView.layoutParams.width) {
            textContentLayout.layoutParams.width = msgTimeView.layoutParams.width
        }
    }

    override fun resetFromName(
        position: Int,
        parentView: View,
        uiChatMsgItemEntity: WKUIChatMsgItemEntity,
        from: WKChatIteMsgFromType
    ) {
        val receivedTextNameTv = parentView.findViewById<TextView>(UiKitR.id.receivedTextNameTv)
        setFromName(uiChatMsgItemEntity, from, receivedTextNameTv)
    }

    private fun buildRichSpannable(richContent: RichTextContent, defaultTextColor: Int, contentTv: AppCompatTextView?): SpannableStringBuilder {
        val sb = SpannableStringBuilder(richContent.content)
        val entities = richContent.entities ?: return sb

        val ctx = this.context ?: return sb

        for (entity in entities) {
            if (entity.offset < 0 || entity.offset + entity.length > sb.length) continue

            when (entity.type) {
                RichStyles.BOLD -> {
                    sb.setSpan(
                        StyleSpan(Typeface.BOLD),
                        entity.offset,
                        entity.offset + entity.length,
                        Spanned.SPAN_EXCLUSIVE_EXCLUSIVE
                    )
                }
                RichStyles.ITALIC -> {
                    sb.setSpan(
                        StyleSpan(Typeface.ITALIC),
                        entity.offset,
                        entity.offset + entity.length,
                        Spanned.SPAN_EXCLUSIVE_EXCLUSIVE
                    )
                }
                RichStyles.UNDERLINE -> {
                    sb.setSpan(
                        UnderlineSpan(),
                        entity.offset,
                        entity.offset + entity.length,
                        Spanned.SPAN_EXCLUSIVE_EXCLUSIVE
                    )
                }
                RichStyles.STRIKETHROUGH -> {
                    sb.setSpan(
                        StrikethroughSpan(),
                        entity.offset,
                        entity.offset + entity.length,
                        Spanned.SPAN_EXCLUSIVE_EXCLUSIVE
                    )
                }
                RichStyles.COLOR -> {
                    val color = WMColor.parseColor(entity.value)
                    sb.setSpan(
                        ForegroundColorSpan(color),
                        entity.offset,
                        entity.offset + entity.length,
                        Spanned.SPAN_EXCLUSIVE_EXCLUSIVE
                    )
                }
                RichStyles.FONT -> {
                    val size = entity.value?.toIntOrNull() ?: 16
                    sb.setSpan(
                        AbsoluteSizeSpan(size, true),
                        entity.offset,
                        entity.offset + entity.length,
                        Spanned.SPAN_EXCLUSIVE_EXCLUSIVE
                    )
                }
                RichStyles.LINK -> {
                    val url = entity.value ?: ""
                    val clickSpan = NormalClickableSpan(
                        false,
                        ContextCompat.getColor(ctx, R.color.blue),
                        NormalClickableContent(
                            NormalClickableContent.NormalClickableTypes.URL,
                            url
                        )
                    ) { view ->
                        val intent = Intent(ctx, WKWebViewActivity::class.java)
                        intent.putExtra("url", url)
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        ctx.startActivity(intent)
                    }
                    sb.setSpan(
                        StyleSpan(Typeface.BOLD),
                        entity.offset,
                        entity.offset + entity.length,
                        Spanned.SPAN_EXCLUSIVE_EXCLUSIVE
                    )
                    sb.setSpan(
                        clickSpan,
                        entity.offset,
                        entity.offset + entity.length,
                        Spanned.SPAN_EXCLUSIVE_EXCLUSIVE
                    )
                }
                RichStyles.MENTION -> {
                    val uid = entity.value ?: ""
                    sb.setSpan(
                        StyleSpan(Typeface.BOLD),
                        entity.offset,
                        entity.offset + entity.length,
                        Spanned.SPAN_EXCLUSIVE_EXCLUSIVE
                    )
                    sb.setSpan(
                        NormalClickableSpan(
                            false,
                            Theme.colorAccount,
                            NormalClickableContent(
                                NormalClickableContent.NormalClickableTypes.Remind,
                                uid
                            )
                        ) { /* 点击@提及的处理 */ },
                        entity.offset,
                        entity.offset + entity.length,
                        Spanned.SPAN_EXCLUSIVE_EXCLUSIVE
                    )
                }
                RichStyles.IMG -> {
                    val imgUrl = entity.value ?: ""
                    if (imgUrl.isNotEmpty() && entity.offset >= 0 && entity.offset + entity.length <= sb.length) {
                        val start = entity.offset
                        val end = entity.offset + entity.length
                        Glide.with(ctx)
                            .asDrawable()
                            .load(imgUrl)
                            .into(object : CustomTarget<Drawable>() {
                                override fun onResourceReady(resource: Drawable, transition: Transition<in Drawable>?) {
                                    val width = resource.intrinsicWidth.coerceAtMost(200)
                                    val height = resource.intrinsicHeight.coerceAtMost(200)
                                    if (width > 0 && height > 0) {
                                        resource.setBounds(0, 0, width, height)
                                    }
                                    val imageSpan = ImageSpan(resource, ImageSpan.ALIGN_BASELINE)
                                    if (start in 0..sb.length && end in 0..sb.length && start <= end) {
                                        sb.setSpan(imageSpan, start, end, Spanned.SPAN_EXCLUSIVE_EXCLUSIVE)
                                        contentTv?.text = sb
                                    }
                                }
                                override fun onLoadCleared(placeholder: Drawable?) {}
                            })
                    }
                }
            }
        }

        return sb
    }
}
