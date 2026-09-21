package com.chat.base.entity

/**
 * 全局搜索请求实体
 */
data class GlobalSearchReq(
    var onlyMessage: Int = 0,
    var keyword: String = "",
    var channel_id: String = "",
    var channel_type: Byte = 0,
    var start_msg_id: String = "",
    var end_msg_id: String = "",
    var content_types: List<Int> = ArrayList(),
    var page: Int = 1,
    var size: Int = 20,
    var search_type: Int = 0,
    var search_mode: Int = 0
)
