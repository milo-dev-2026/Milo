package com.chat.base.entity

/**
 * 全局搜索频道实体
 */
data class GlobalChannel(
    var channel_id: String = "",
    var channel_type: Byte = 0,
    var channel_name: String? = null,
    var avatar: String? = null,
    var remark: String? = null,
    var extra: String? = null
) {
    /**
     * 获取 HTML 格式的名称（搜索高亮）
     */
    fun getHtmlName(): String {
        return channel_name ?: ""
    }
}
