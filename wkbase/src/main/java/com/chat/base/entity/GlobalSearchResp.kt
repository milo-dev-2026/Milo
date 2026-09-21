package com.chat.base.entity

import com.chat.base.entity.GlobalChannel
import com.chat.base.entity.GlobalMessage

/**
 * 全局搜索响应实体
 */
data class GlobalSearchResp(
    var friends: List<GlobalChannel> = ArrayList(),
    var groups: List<GlobalChannel> = ArrayList(),
    var messages: List<GlobalMessage> = ArrayList()
)
