package com.chat.uikit.chat.provider

import android.content.Intent
import android.text.TextUtils
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.content.ContextCompat
import com.chat.base.msgitem.WKChatBaseProvider
import com.chat.base.msgitem.WKChatIteMsgFromType
import com.chat.base.msgitem.WKContentType
import com.chat.base.msgitem.WKUIChatMsgItemEntity
import com.chat.base.ui.components.FilterImageView
import com.chat.base.utils.WKFileUtils
import com.chat.base.views.BubbleLayout
import com.chat.uikit.R
import com.chat.uikit.location.LocationDetailActivity
import com.chat.uikit.location.WKLocationContent
import com.chat.base.config.WKApiConfig
import com.chat.base.glide.GlideUtils
import com.chat.base.utils.singleclick.SingleClickUtil
import androidx.appcompat.widget.AppCompatTextView

/**
 * 位置消息 Provider
 */
class WKLocationProvider : WKChatBaseProvider() {

    override val itemViewType: Int
        get() = WKContentType.WK_LOCATION

    override fun getChatViewItem(parentView: ViewGroup, from: WKChatIteMsgFromType): View? {
        return LayoutInflater.from(context).inflate(R.layout.chat_item_location, parentView, false)
    }

    override fun setData(
        adapterPosition: Int,
        parentView: View,
        uiChatMsgItemEntity: WKUIChatMsgItemEntity,
        from: WKChatIteMsgFromType
    ) {
        val locationView = parentView.findViewById<LinearLayout>(R.id.locationView)
        val nameTv = parentView.findViewById<TextView>(R.id.addressTv)
        val addressTv = parentView.findViewById<TextView>(R.id.addressDetailTv)
        val mapIv = parentView.findViewById<FilterImageView>(R.id.locationMapIv)

        locationView.layoutParams.width = getViewWidth(from, uiChatMsgItemEntity)

        val content = uiChatMsgItemEntity.wkMsg.baseContentMsgModel as? WKLocationContent
        if (content == null) return

        nameTv.text = if (TextUtils.isEmpty(content.title)) "位置" else content.title
        addressTv.text = content.address ?: ""

        // 加载地图缩略图
        var showUrl: String? = null
        if (!TextUtils.isEmpty(content.localPath)) {
            val file = java.io.File(content.localPath)
            showUrl = if (file.exists()) content.localPath else null
        }
        if (showUrl == null && !TextUtils.isEmpty(content.url)) {
            showUrl = WKApiConfig.getShowUrl(content.url)
        }
        if (showUrl == null && content.latitude != 0.0 && content.longitude != 0.0) {
            showUrl = getStaticMapUrl(content.latitude, content.longitude)
        }

        if (showUrl != null) {
            GlideUtils.getInstance().showImg(context, showUrl, mapIv)
        } else {
            mapIv.setImageResource(R.drawable.default_view_bg)
        }

        resetCellBackground(parentView, uiChatMsgItemEntity, from)

        val timeTv = parentView.findViewById<AppCompatTextView>(R.id.msgTimeTv)
        timeTv?.setTextColor(0xFFFFFFFF.toInt())

        val bubbleLayout = parentView.findViewById<BubbleLayout>(R.id.bubbleLayout)
        SingleClickUtil.onSingleClick(bubbleLayout) {
            val intent = Intent(context, LocationDetailActivity::class.java)
            intent.putExtra(LocationDetailActivity.EXTRA_TITLE, content.title)
            intent.putExtra(LocationDetailActivity.EXTRA_ADDRESS, content.address)
            intent.putExtra(LocationDetailActivity.EXTRA_LATITUDE, content.latitude)
            intent.putExtra(LocationDetailActivity.EXTRA_LONGITUDE, content.longitude)
            intent.putExtra(LocationDetailActivity.EXTRA_IMG, content.url)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
        }
    }

    private fun getStaticMapUrl(latitude: Double, longitude: Double): String {
        val key = "f33b95e9b302dbb24b8b2eb12c799ca1"
        val location = "$longitude,$latitude"
        val zoom = 15
        val size = "400*300"
        val markers = "mid,,A:$longitude,$latitude"
        return "https://restapi.amap.com/v3/staticmap?location=$location&zoom=$zoom&size=$size&markers=$markers&key=$key"
    }

    override fun resetCellBackground(
        parentView: View,
        uiChatMsgItemEntity: WKUIChatMsgItemEntity,
        from: WKChatIteMsgFromType
    ) {
        super.resetCellBackground(parentView, uiChatMsgItemEntity, from)
        val bubbleLayout = parentView.findViewById<BubbleLayout>(R.id.bubbleLayout)
        val bgType = getMsgBgType(
            uiChatMsgItemEntity.previousMsg,
            uiChatMsgItemEntity.wkMsg,
            uiChatMsgItemEntity.nextMsg
        )
        bubbleLayout?.setAll(bgType, from, WKContentType.WK_LOCATION)
    }

    override fun resetCellListener(
        position: Int,
        parentView: View,
        uiChatMsgItemEntity: WKUIChatMsgItemEntity,
        from: WKChatIteMsgFromType
    ) {
        super.resetCellListener(position, parentView, uiChatMsgItemEntity, from)
        val bubbleLayout = parentView.findViewById<BubbleLayout>(R.id.bubbleLayout)
        if (bubbleLayout != null) {
            addLongClick(bubbleLayout, uiChatMsgItemEntity)
        }
    }
}
