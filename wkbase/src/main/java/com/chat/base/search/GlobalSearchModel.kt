package com.chat.base.search

import com.chat.base.entity.GlobalSearchReq
import com.chat.base.entity.GlobalSearchResp
import com.chat.base.net.HttpResponseCode

/**
 * 全局搜索 Model
 */
object GlobalSearchModel {

    /**
     * 全局搜索
     */
    fun search(
        req: GlobalSearchReq,
        callback: (code: Short, msg: String?, resp: GlobalSearchResp?) -> Unit
    ) {
        // 存根实现 - 实际实现需要调用后端 API
        callback(HttpResponseCode.error, "Not implemented", null)
    }
}
