package com.chat.uikit.chat.provider

import android.content.Intent
import android.text.TextUtils
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.content.ContextCompat
import com.bumptech.glide.Glide
import com.chat.base.entity.PopupMenuItem
import com.chat.base.msgitem.WKChatBaseProvider
import com.chat.base.msgitem.WKChatIteMsgFromType
import com.chat.base.msgitem.WKContentType
import com.chat.base.msgitem.WKUIChatMsgItemEntity
import com.chat.base.ui.components.FilterImageView
import com.chat.base.views.BubbleLayout
import com.chat.uikit.R
import com.chat.uikit.chat.msgmodel.WKNoteContent
import com.chat.uikit.note.NoteEntity
import com.chat.uikit.note.NotePreviewActivity
import com.chat.uikit.note.NoteStorageManager
import com.chat.base.utils.singleclick.SingleClickUtil

class WKNoteProvider : WKChatBaseProvider() {

    override val itemViewType: Int
        get() = WKContentType.noteMsg

    override fun getChatViewItem(parentView: ViewGroup, from: WKChatIteMsgFromType): View? {
        return LayoutInflater.from(context).inflate(R.layout.chat_item_note, parentView, false)
    }

    override fun setData(
        adapterPosition: Int,
        parentView: View,
        uiChatMsgItemEntity: WKUIChatMsgItemEntity,
        from: WKChatIteMsgFromType
    ) {
        val cardView = parentView.findViewById<LinearLayout>(R.id.cardView)
        cardView.layoutParams.width = getViewWidth(from, uiChatMsgItemEntity)

        val titleTv = parentView.findViewById<TextView>(R.id.title)
        val tvNote = parentView.findViewById<TextView>(R.id.tvNote)
        val divider = parentView.findViewById<View>(R.id.divider)
        val headIv = parentView.findViewById<FilterImageView>(R.id.note_item_headurl)

        val content = uiChatMsgItemEntity.wkMsg.baseContentMsgModel as? WKNoteContent
        if (content == null) {
            titleTv.text = "[笔记] 无标题"
            headIv.visibility = View.GONE
            resetCellBackground(parentView, uiChatMsgItemEntity, from)
            return
        }

        // 根据发送/接收设置不同颜色
        if (from == WKChatIteMsgFromType.SEND) {
            titleTv.setTextColor(ContextCompat.getColor(context, R.color.white0))
            tvNote.setTextColor(ContextCompat.getColor(context, R.color.white_abs))
            divider.setBackgroundColor(ContextCompat.getColor(context, R.color.cb3ffffff))
        } else if (from == WKChatIteMsgFromType.RECEIVED) {
            titleTv.setTextColor(ContextCompat.getColor(context, R.color.textcode))
            tvNote.setTextColor(ContextCompat.getColor(context, R.color.cc787A7E))
            divider.setBackgroundColor(ContextCompat.getColor(context, R.color.note_line))
        }

        // 设置标题
        titleTv.text = if (TextUtils.isEmpty(content.noteTitle)) "无标题" else content.noteTitle

        // 设置摘要（优先summary，否则用noteContent）
        val summary = if (!TextUtils.isEmpty(content.summary)) {
            content.summary
        } else if (!TextUtils.isEmpty(content.noteContent)) {
            content.noteContent
        } else {
            ""
        }
        tvNote.text = summary

        // 封面图片 - 优先从coverUrl加载（resource字段已在decodeMsg时同步到coverUrl）
        // 没有封面时隐藏图片区域（不显示默认占位图，纯文字展示）
        // 发送方：优先显示本地文件（上传完成前），上传后显示网络URL
        // 接收方：显示网络URL
        val coverUrl = getCoverImageUrl(content)
        if (!TextUtils.isEmpty(coverUrl)) {
            headIv.visibility = View.VISIBLE
            android.util.Log.d("WKNoteProvider", "loading cover: $coverUrl")
            Glide.with(context)
                .load(coverUrl)
                .centerCrop()
                .listener(object : com.bumptech.glide.request.RequestListener<android.graphics.drawable.Drawable> {
                    override fun onResourceReady(
                        resource: android.graphics.drawable.Drawable,
                        model: Any,
                        target: com.bumptech.glide.request.target.Target<android.graphics.drawable.Drawable>,
                        dataSource: com.bumptech.glide.load.DataSource,
                        isFirstResource: Boolean
                    ): Boolean {
                        return false
                    }

                    override fun onLoadFailed(
                        e: com.bumptech.glide.load.engine.GlideException?,
                        model: Any?,
                        target: com.bumptech.glide.request.target.Target<android.graphics.drawable.Drawable>,
                        isFirstResource: Boolean
                    ): Boolean {
                        android.util.Log.e("WKNoteProvider", "cover load failed: $coverUrl, error=${e?.message}")
                        headIv.visibility = View.GONE
                        return false
                    }
                })
                .into(headIv)
        } else {
            // 无封面时隐藏图片区域，清除可能的复用残留，不显示默认占位图
            headIv.setImageDrawable(null)
            headIv.visibility = View.GONE
        }

        // 时间颜色设为白色 - 使用post延迟设置，避免被setMsgTimeAndStatus覆盖
        parentView.post {
            val msgTimeTv = parentView.findViewById<TextView>(R.id.msgTimeTv)
            msgTimeTv?.setTextColor(ContextCompat.getColor(context, R.color.white_abs))
        }

        resetCellBackground(parentView, uiChatMsgItemEntity, from)

        val bubbleLayout = parentView.findViewById<BubbleLayout>(R.id.contentLayout)
        SingleClickUtil.onSingleClick(bubbleLayout) {
            val intent = Intent(context, NotePreviewActivity::class.java)
            intent.putExtra(NotePreviewActivity.KEY_NOTE_ID, content.noteId)
            intent.putExtra(NotePreviewActivity.KEY_NOTE_TITLE, content.noteTitle)
            intent.putExtra(NotePreviewActivity.KEY_NOTE_CONTENT, content.noteContent)
            intent.putExtra(NotePreviewActivity.KEY_NOTE_GROUP, content.noteGroup)
            intent.putExtra(NotePreviewActivity.KEY_NOTE_TIME, content.noteTime)
            intent.putExtra(NotePreviewActivity.KEY_BLOCK_LIST_JSON, content.blockListJson)
            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            context.startActivity(intent)
        }
    }

    override fun resetCellBackground(
        parentView: View,
        uiChatMsgItemEntity: WKUIChatMsgItemEntity,
        from: WKChatIteMsgFromType
    ) {
        super.resetCellBackground(parentView, uiChatMsgItemEntity, from)
        val bubbleLayout = parentView.findViewById<BubbleLayout>(R.id.contentLayout)
        val bgType = getMsgBgType(
            uiChatMsgItemEntity.previousMsg,
            uiChatMsgItemEntity.wkMsg,
            uiChatMsgItemEntity.nextMsg
        )
        bubbleLayout?.setAll(bgType, from, WKContentType.noteMsg)
    }

    override fun resetCellListener(
        position: Int,
        parentView: View,
        uiChatMsgItemEntity: WKUIChatMsgItemEntity,
        from: WKChatIteMsgFromType
    ) {
        super.resetCellListener(position, parentView, uiChatMsgItemEntity, from)
        val bubbleLayout = parentView.findViewById<BubbleLayout>(R.id.contentLayout)
        if (bubbleLayout != null) {
            addLongClick(bubbleLayout, uiChatMsgItemEntity)
        }
    }

    /**
     * 获取笔记封面图片的可加载URL
     * 参考utalk实现：确保发送方和接收方都能正确加载同一张图片
     * - 本地文件路径：直接返回（发送方上传前可显示）
     * - 网络URL：直接返回
     * - 相对路径：通过getShowUrl转换为完整URL
     */
    private fun getCoverImageUrl(content: WKNoteContent): String {
        val rawUrl = if (!TextUtils.isEmpty(content.coverUrl)) {
            content.coverUrl
        } else if (!TextUtils.isEmpty(content.resource)) {
            content.resource
        } else {
            ""
        }

        if (TextUtils.isEmpty(rawUrl)) return ""

        val lower = rawUrl.lowercase()
        // 已经是完整的网络URL，直接返回
        if (lower.startsWith("http://") || lower.startsWith("https://")) {
            return rawUrl
        }

        // 本地绝对路径且文件存在，直接返回（发送方上传前的本地预览）
        if (rawUrl.startsWith("/") && !rawUrl.startsWith("//") && rawUrl.contains(".")) {
            val file = java.io.File(rawUrl)
            if (file.exists() && file.length() > 0) {
                return rawUrl
            }
        }

        // content URI 类型（Android 10+ 分区存储）
        if (rawUrl.startsWith("content://")) {
            return rawUrl
        }

        // 相对路径：通过 getShowUrl 转换为完整可访问URL
        return com.chat.base.config.WKApiConfig.getShowUrl(rawUrl.replace("\\/", "/"))
    }

    override fun getPopupList(mMsg: com.xinbida.wukongim.entity.WKMsg): List<PopupMenuItem> {
        val list = super.getPopupList(mMsg).toMutableList()
        val content = mMsg.baseContentMsgModel as? WKNoteContent
        android.util.Log.d("WKNoteProvider", "getPopupList: contentIsNull=${content == null}, type=${mMsg.type}, msgId=${mMsg.messageID}")
        if (content != null) {
            val saveItem = PopupMenuItem("保存笔记", R.mipmap.msg_fave,
                object : PopupMenuItem.IClick {
                    override fun onClick() {
                        val note = NoteEntity()
                        note.id = if (TextUtils.isEmpty(content.noteId)) {
                            System.currentTimeMillis().toString()
                        } else {
                            content.noteId
                        }
                        note.title = content.noteTitle ?: ""
                        note.content = content.noteContent ?: ""
                        note.groupName = content.noteGroup ?: ""
                        note.time = content.noteTime ?: ""
                        note.isTop = false
                        note.type = 1
                        note.blockListJson = content.blockListJson ?: ""
                        note.coverUrl = if (!TextUtils.isEmpty(content.coverUrl)) {
                            content.coverUrl
                        } else {
                            content.resource ?: ""
                        }
                        android.util.Log.d("WKNoteProvider", "saving note: id=${note.id}, title=${note.title}, coverUrl=${note.coverUrl}")
                        NoteStorageManager.getInstance(context).saveNote(note)
                        // 验证是否保存成功
                        val saved = NoteStorageManager.getInstance(context).getNote(note.id)
                        android.util.Log.d("WKNoteProvider", "save result: noteFound=${saved != null}, title=${saved?.title}")
                        android.widget.Toast.makeText(context, "已保存到我的笔记", android.widget.Toast.LENGTH_SHORT).show()
                    }
                })
            list.add(0, saveItem)
        }
        return list
    }
}
