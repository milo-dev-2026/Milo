package com.chat.base.endpoint.entity

class ReadMsgMenu(
    @JvmField val channelID: String,
    @JvmField val channelType: Byte,
    @JvmField val msgIds: List<ReadedMessageReq>,
    @JvmField val maxLargeMessageSeq: Int = 0
)
