package com.chat.scan.entity;

import java.util.Map;

/**
 * 扫码解析用户二维码时使用的搜索结果 DTO
 * 复用 /v1/user/search 接口，按 short_no 解析出 uid 与 vercode
 */
public class ScanSearchResult {
    public int exist;
    public Map<String, Object> data;
}
