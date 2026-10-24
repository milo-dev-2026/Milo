package com.chat.uikit.message.entity;

/**
 * 消息扩展同步实体（蛇形字段名，与服务端返回一致）
 * 注意：SDK 里的 WKSyncExtraMsg 是驼峰命名，FastJson 默认不自动转换蛇形→驼峰，
 * 所以需要自定义这个类来正确解析服务端返回的数据。
 */
public class WKSyncExtraMsgEntity {
    public String message_id;
    public String message_id_str;
    public int revoke;
    public String revoker;
    public int voice_status;
    public int is_mutual_deleted;
    public long extra_version;
    public int unread_count;
    public int readed_count;
    public int readed;
    public long edited_at;
    public int is_pinned;
    public long version;      // 服务端返回的版本号字段名
}
