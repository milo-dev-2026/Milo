package com.chat.base.net.entity;

import java.util.Map;

/**
 * 腾讯云COS批量预签名上传结果
 */
public class CosPresignResultEntity {
    public Map<String, String> urls;      // 文件路径 -> 预签名PUT URL
    public String cdn_domain;              // CDN域名（如果配置了）
    public String bucket;                  // COS bucket名
    public int expires;                    // 过期时间（秒）
}
