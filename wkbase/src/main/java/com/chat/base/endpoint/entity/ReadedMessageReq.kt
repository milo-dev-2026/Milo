package com.chat.base.endpoint.entity

class ReadedMessageReq(
    @JvmField val message_id: String,
    @JvmField val from_uid: String,
    @JvmField val message_seq: Int
)
