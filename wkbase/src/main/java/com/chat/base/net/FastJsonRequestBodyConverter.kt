package com.chat.base.net
import com.alibaba.fastjson.JSON
import com.alibaba.fastjson.JSONObject
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody
import okhttp3.RequestBody.Companion.toRequestBody
import retrofit2.Converter

class FastJsonRequestBodyConverter<T> : Converter<T, RequestBody> {
    private val MEDIA_TYPE = "application/json; charset=UTF-8".toMediaType()

    override fun convert(value: T): RequestBody {
        val jsonStr = when (value) {
            is JSONObject -> value.toJSONString()
            is String -> value
            else -> JSON.toJSONString(value)
        }
        return jsonStr.toRequestBody(contentType = MEDIA_TYPE)
    }
}