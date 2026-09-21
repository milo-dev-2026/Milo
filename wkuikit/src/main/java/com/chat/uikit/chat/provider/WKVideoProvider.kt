package com.chat.uikit.chat.provider

import android.content.Intent
import android.text.TextUtils
import android.view.Gravity
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.widget.FrameLayout
import android.widget.LinearLayout
import android.widget.TextView
import androidx.core.content.ContextCompat
import com.chat.base.config.WKApiConfig
import com.chat.base.glide.GlideUtils
import com.chat.base.msgitem.WKChatBaseProvider
import com.chat.base.msgitem.WKChatIteMsgFromType
import com.chat.base.msgitem.WKContentType
import com.chat.base.msgitem.WKMsgBgType
import com.chat.base.msgitem.WKUIChatMsgItemEntity
import com.chat.base.net.ud.WKProgressManager
import com.chat.base.ui.Theme
import com.chat.base.ui.components.FilterImageView
import com.chat.base.ui.components.SecretDeleteTimer
import com.chat.base.utils.AndroidUtilities
import com.chat.base.utils.ImageUtils
import com.chat.base.utils.LayoutHelper
import com.chat.base.utils.VideoPreDownloader
import com.chat.base.utils.WKTimeUtils
import com.chat.base.views.CircularProgressView
import com.chat.base.views.blurview.ShapeBlurView
import com.chat.uikit.R
import com.xinbida.wukongim.msgmodel.WKVideoContent
import java.io.File

/**
 * 视频消息 Provider
 */
class WKVideoProvider : WKChatBaseProvider() {

    override fun getChatViewItem(parentView: ViewGroup, from: WKChatIteMsgFromType): View? {
        return LayoutInflater.from(context).inflate(R.layout.chat_item_video, parentView, false)
    }

    override val itemViewType: Int
        get() = WKContentType.WK_VIDEO

    override fun setData(
        adapterPosition: Int,
        parentView: View,
        uiChatMsgItemEntity: WKUIChatMsgItemEntity,
        from: WKChatIteMsgFromType
    ) {
        val contentLayout = parentView.findViewById<LinearLayout>(R.id.contentLayout)
        val videoLayout = parentView.findViewById<FrameLayout>(R.id.videoLayout)
        val imageView = parentView.findViewById<FilterImageView>(R.id.imageView)
        val blurView = parentView.findViewById<ShapeBlurView>(R.id.blurView)
        val playIv = parentView.findViewById<View>(R.id.playIv)
        val durationTv = parentView.findViewById<TextView>(R.id.durationTv)
        val progressTv = parentView.findViewById<TextView>(R.id.progressTv)
        val progressView = parentView.findViewById<CircularProgressView>(R.id.progressView)
        val uploadProgress = parentView.findViewById<View>(R.id.uploadProgress)
        val otherLayout = parentView.findViewById<FrameLayout>(R.id.otherLayout)
        val expiredImg = parentView.findViewById<View>(R.id.expiredImg)
        val coverView = parentView.findViewById<View>(R.id.coverView)
        val deleteTimer = SecretDeleteTimer(context)

        progressView.setProgColor(Theme.colorAccount)

        otherLayout.removeAllViews()
        otherLayout.addView(deleteTimer, LayoutHelper.createFrame(35, 35, Gravity.CENTER))

        expiredImg.visibility = View.GONE
        coverView.visibility = View.GONE

        contentLayout.gravity =
            if (from == WKChatIteMsgFromType.RECEIVED) Gravity.START else Gravity.END

        val content = uiChatMsgItemEntity.wkMsg.baseContentMsgModel as? WKVideoContent ?: return

        // 设置视频尺寸
        val layoutParams = imageView.layoutParams as FrameLayout.LayoutParams
        val blurViewLayoutParams = blurView.layoutParams as FrameLayout.LayoutParams
        val videoLayoutParams = videoLayout.layoutParams as LinearLayout.LayoutParams
        val ints = ImageUtils.getInstance()
            .getImageWidthAndHeightToTalk(content.width, content.height)

        blurView.visibility = if (uiChatMsgItemEntity.wkMsg.flame == 1)
            View.VISIBLE
        else View.GONE

        if (uiChatMsgItemEntity.wkMsg.flame == 1) {
            otherLayout.visibility = View.VISIBLE
            deleteTimer.setSize(35)
            if (uiChatMsgItemEntity.wkMsg.viewedAt > 0 && uiChatMsgItemEntity.wkMsg.flameSecond > 0) {
                deleteTimer.setDestroyTime(
                    uiChatMsgItemEntity.wkMsg.clientMsgNO,
                    uiChatMsgItemEntity.wkMsg.flameSecond,
                    uiChatMsgItemEntity.wkMsg.viewedAt,
                    false
                )
            }
        } else {
            otherLayout.visibility = View.GONE
        }

        // 设置尺寸
        if (uiChatMsgItemEntity.wkMsg.flame == 1) {
            layoutParams.height = AndroidUtilities.dp(150f)
            layoutParams.width = AndroidUtilities.dp(150f)
            blurViewLayoutParams.height = AndroidUtilities.dp(150f)
            blurViewLayoutParams.width = AndroidUtilities.dp(150f)
            videoLayoutParams.height = AndroidUtilities.dp(150f)
            videoLayoutParams.width = AndroidUtilities.dp(150f)
        } else {
            layoutParams.height = ints[1]
            layoutParams.width = ints[0]
            blurViewLayoutParams.height = ints[1]
            blurViewLayoutParams.width = ints[0]
            videoLayoutParams.height = ints[1]
            videoLayoutParams.width = ints[0]
        }
        imageView.layoutParams = layoutParams
        blurView.layoutParams = blurViewLayoutParams
        videoLayout.layoutParams = videoLayoutParams

        // 加载封面图
        val coverUrl = getCoverUrl(content)
        if (!TextUtils.isEmpty(coverUrl)) {
            GlideUtils.getInstance().showImg(context, coverUrl, ints[0], ints[1], imageView)
        } else {
            imageView.setImageResource(R.drawable.default_view_bg)
        }

        // 对已接收的视频消息触发预下载，用户点击播放时可直接读本地文件秒开
        // HLS(m3u8)流不能预下载：m3u8是播放列表文本，不是视频文件
        if (from == WKChatIteMsgFromType.RECEIVED && !TextUtils.isEmpty(content.url)) {
            val showUrl = WKApiConfig.getShowUrl(content.url)
            if (!showUrl.lowercase().endsWith(".m3u8")) {
                VideoPreDownloader.getInstance().preDownload(showUrl)
            }
        }

        // 显示时长
        if (content.second > 0) {
            durationTv.visibility = View.VISIBLE
            durationTv.text = formatDuration(content.second)
        } else {
            durationTv.visibility = View.GONE
        }

        // 设置圆角
        setCorners(from, uiChatMsgItemEntity, imageView, blurView)

        // 上传进度
        if (TextUtils.isEmpty(content.url)) {
            uploadProgress.visibility = View.GONE
            progressView.visibility = View.VISIBLE
            progressTv.visibility = View.VISIBLE
            playIv.visibility = View.GONE
            WKProgressManager.instance.registerProgress(uiChatMsgItemEntity.wkMsg.clientSeq,
                object : WKProgressManager.IProgress {
                    override fun onProgress(tag: Any?, progress: Int) {
                        if (tag is Long && tag == uiChatMsgItemEntity.wkMsg.clientSeq) {
                            progressView.progress = progress
                            progressTv.text = String.format("%s%%", progress)
                            if (progress >= 100) {
                                progressTv.visibility = View.GONE
                                progressView.visibility = View.GONE
                                playIv.visibility = View.VISIBLE
                                deleteTimer.visibility = View.VISIBLE
                            } else {
                                progressView.visibility = View.VISIBLE
                                progressTv.visibility = View.VISIBLE
                                playIv.visibility = View.GONE
                                deleteTimer.visibility = View.GONE
                            }
                        }
                    }

                    override fun onSuccess(tag: Any?, path: String?) {
                        progressTv.visibility = View.GONE
                        progressView.visibility = View.GONE
                        playIv.visibility = View.VISIBLE
                        deleteTimer.visibility = View.VISIBLE
                        if (tag != null) {
                            WKProgressManager.instance.unregisterProgress(tag)
                        }
                    }

                    override fun onFail(tag: Any?, msg: String?) {
                    }
                })
        } else {
            progressView.visibility = View.GONE
            progressTv.visibility = View.GONE
            uploadProgress.visibility = View.GONE
            playIv.visibility = View.VISIBLE
        }

        // 点击播放视频
        imageView.setOnClickListener {
            onVideoClick(uiChatMsgItemEntity)
        }
        playIv.setOnClickListener {
            onVideoClick(uiChatMsgItemEntity)
        }

        // 长按
        addLongClick(imageView, uiChatMsgItemEntity)
    }

    private fun onVideoClick(uiChatMsgItemEntity: WKUIChatMsgItemEntity) {
        val content = uiChatMsgItemEntity.wkMsg.baseContentMsgModel as? WKVideoContent ?: return

        // 阅后即焚标记已读
        if (uiChatMsgItemEntity.wkMsg.flame == 1 && uiChatMsgItemEntity.wkMsg.viewed == 0) {
            for (i in 0 until (getAdapter()?.data?.size ?: 0)) {
                if (getAdapter()?.data?.get(i)?.wkMsg?.clientMsgNO == uiChatMsgItemEntity.wkMsg.clientMsgNO) {
                    getAdapter()?.data?.get(i)?.wkMsg?.viewed = 1
                    getAdapter()?.data?.get(i)?.wkMsg?.viewedAt =
                        WKTimeUtils.getInstance().currentMills
                    getAdapter()?.notifyItemChanged(i)
                    com.xinbida.wukongim.WKIM.getInstance().msgManager.updateViewedAt(
                        1,
                        getAdapter()!!.data[i].wkMsg.viewedAt,
                        getAdapter()!!.data[i].wkMsg.clientMsgNO
                    )
                    break
                }
            }
        }

        // 跳转到播放页面
        val playUrl = getPlayUrl(content)
        if (TextUtils.isEmpty(playUrl)) return

        val intent = Intent(context, com.chat.base.act.PlayVideoActivity::class.java)
        intent.putExtra("url", playUrl)
        intent.putExtra("coverImg", getCoverUrl(content))
        intent.putExtra("clientMsgNo", uiChatMsgItemEntity.wkMsg.clientMsgNO)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        context.startActivity(intent)
    }

    private fun getCoverUrl(content: WKVideoContent): String {
        if (!TextUtils.isEmpty(content.coverLocalPath)) {
            val file = File(content.coverLocalPath)
            if (file.exists() && file.length() > 0L) {
                return file.absolutePath
            }
        }
        if (!TextUtils.isEmpty(content.cover)) {
            return WKApiConfig.getShowUrl(content.cover)
        }
        return ""
    }

    private fun getPlayUrl(content: WKVideoContent): String {
        if (!TextUtils.isEmpty(content.localPath)) {
            val file = File(content.localPath)
            if (file.exists() && file.length() > 0L) {
                return file.absolutePath
            }
        }
        if (!TextUtils.isEmpty(content.url)) {
            val showUrl = WKApiConfig.getShowUrl(content.url)
            // HLS(m3u8)流不能用预下载缓存：m3u8是播放列表文本，不是视频文件
            if (!showUrl.lowercase().endsWith(".m3u8")) {
                val cachedPath = VideoPreDownloader.getInstance().getCachedPath(showUrl)
                if (!cachedPath.isNullOrEmpty()) {
                    return cachedPath
                }
            }
            return showUrl
        }
        return ""
    }

    override fun resetCellListener(
        position: Int,
        parentView: View,
        uiChatMsgItemEntity: WKUIChatMsgItemEntity,
        from: WKChatIteMsgFromType
    ) {
        super.resetCellListener(position, parentView, uiChatMsgItemEntity, from)
        val imageView = parentView.findViewById<FilterImageView>(R.id.imageView)
        addLongClick(imageView, uiChatMsgItemEntity)
    }

    override fun resetCellBackground(
        parentView: View,
        uiChatMsgItemEntity: WKUIChatMsgItemEntity,
        from: WKChatIteMsgFromType
    ) {
        super.resetCellBackground(parentView, uiChatMsgItemEntity, from)
        val imageView = parentView.findViewById<FilterImageView>(R.id.imageView)
        val blurView = parentView.findViewById<ShapeBlurView>(R.id.blurView)
        if (imageView != null && blurView != null) {
            setCorners(from, uiChatMsgItemEntity, imageView, blurView)
        }
    }

    private fun setCorners(
        from: WKChatIteMsgFromType,
        uiChatMsgItemEntity: WKUIChatMsgItemEntity,
        imageView: FilterImageView,
        blurView: ShapeBlurView
    ) {
        imageView.strokeWidth = 0f
        imageView.setStrokeColor(android.graphics.Color.TRANSPARENT)
        // 图片/视频消息：四个角统一圆角
        val radius = 12f
        imageView.setAllCorners(radius.toInt())
        blurView.setCornerRadius(
            AndroidUtilities.dp(radius).toFloat(),
            AndroidUtilities.dp(radius).toFloat(),
            AndroidUtilities.dp(radius).toFloat(),
            AndroidUtilities.dp(radius).toFloat()
        )
        // 解决边缘白边问题：给图片添加1.5dp的背景色边框，掩盖抗锯齿白边
        val bgColor = ContextCompat.getColor(context, R.color.color_chat)
        imageView.setStrokeColor(bgColor)
        imageView.strokeWidth = 1.5f
    }

    /**
     * 格式化视频时长（秒 → mm:ss 或 hh:mm:ss）
     */
    private fun formatDuration(seconds: Long): String {
        val hours = seconds / 3600
        val minutes = (seconds % 3600) / 60
        val secs = seconds % 60
        return if (hours > 0) {
            String.format("%02d:%02d:%02d", hours, minutes, secs)
        } else {
            String.format("%02d:%02d", minutes, secs)
        }
    }
}
