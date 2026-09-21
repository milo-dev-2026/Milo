package com.chat.base.net.entity;

/**
 * MinIO 预签名上传结果
 */
public class PresignResultEntity {
    public String upload_url;   // 预签名PUT上传地址
    public String path;         // 文件访问路径（file/preview/chat/xxx）
    public String url;          // 兼容字段，同path
    public String access_url;   // 完整访问URL
    public int expires;         // 过期时间（秒）
}
