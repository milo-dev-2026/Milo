package com.chat.base.entity

import com.chat.base.msgitem.WKContentType

/**
 * 全局搜索消息实体
 */
data class GlobalMessage(
    var message_seq: Long = 0,
    var channel: GlobalChannel? = null,
    var from_uid: String? = null,
    var content: String? = null,
    var type: Int = 0,
    var timestamp: Long = 0
) {
    /**
     * 获取消息内容类型
     */
    fun getContentType(): Int {
        return type
    }

    /**
     * 获取 HTML 格式的文本内容（搜索高亮）
     */
    fun getHtmlText(): String {
        return content ?: ""
    }

    /**
     * 获取指定字段的 HTML 格式内容（搜索高亮）
     */
    fun getHtmlWithField(field: String): String {
        return content ?: ""
    }
}
