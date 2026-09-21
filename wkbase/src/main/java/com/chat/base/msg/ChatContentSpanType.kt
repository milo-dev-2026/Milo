package com.chat.base.msg

class ChatContentSpanType {
    companion object {
        @JvmField
        val mention = "mention"

        @JvmField
        val link = "link"

        @JvmField
        val botCommand = "bot_command"
    }
}