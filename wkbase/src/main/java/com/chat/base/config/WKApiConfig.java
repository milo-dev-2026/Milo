package com.chat.base.config;

import android.text.TextUtils;

import com.xinbida.wukongim.entity.WKChannelType;

import java.util.Locale;

/**
 * 2019-11-20 10:11
 * api地址
 */
public class WKApiConfig {
    public static String baseUrl = "";
    public static String baseWebUrl = "";
    public static String authUrl = "";
    /**
     * 对象存储(MinIO)外网直连基地址，例如 http://hz01.cc/
     * 接收图片/视频/文件时直连对象存储，绕过应用服务器中转，配合nginx边缘缓存实现秒开
     */
    public static String mediaBaseUrl = "";

    private static final String FILE_PREVIEW_PREFIX = "file/preview/";

    public static void initBaseURL(String apiURL) {
        baseUrl = apiURL + "/v1/";
        baseWebUrl = apiURL + "/web/";
        mediaBaseUrl = apiURL + "/";
    }

    public static void initBaseURLIncludeIP(String apiURL) {
        baseUrl = apiURL + "/v1/";
        baseWebUrl = apiURL + "/web/";
        mediaBaseUrl = apiURL + "/";
    }

    public static void initAuthURL(String authAPIURL) {
        authUrl = authAPIURL + "/v1/";
    }

    public static String getAvatarUrl(String uid) {
        return baseUrl + "users/" + uid + "/avatar";
    }

    public static String getGroupUrl(String groupId) {
        return baseUrl + "groups/" + groupId + "/avatar";
    }

    public static String getShowAvatar(String channelID, byte channelType) {
        return channelType == WKChannelType.PERSONAL ? getAvatarUrl(channelID) : getGroupUrl(channelID);
    }

    /**
     * 将消息中存储的文件路径转换为可直接访问的完整URL。
     * <p>
     * 服务端上传成功后返回的 path 形如：file/preview/{bucket}/{key}，
     * 其中 bucket 为 chat/avatar/group。接收端直接访问对象存储：
     * {mediaBaseUrl}{bucket}/{key}（例如 http://hz01.cc/chat/2/xxx.jpg），
     * 由 nginx 反代到 MinIO 并做边缘缓存，比走应用服务器中转更快。
     */
    public static String getShowUrl(String url) {
        if (TextUtils.isEmpty(url)) {
            // 永不返回 null，避免 Kotlin 调用点把返回值传给非空参数时抛 NullPointerException
            return "";
        }
        String lower = url.toLowerCase(Locale.ROOT);
        if (lower.startsWith("http://") || lower.startsWith("https://")) {
            return url;
        }
        // 本地绝对路径
        if (url.startsWith("/") && !url.startsWith("//") && url.contains(".")) {
            java.io.File f = new java.io.File(url);
            if (f.exists() && f.length() > 0) {
                return url;
            }
        }
        if (url.startsWith(FILE_PREVIEW_PREFIX)) {
            // file/preview/chat/2/xxx.jpg -> {mediaBaseUrl}chat/2/xxx.jpg
            return mediaBaseUrl + url.substring(FILE_PREVIEW_PREFIX.length());
        }
        // 兜底：走应用服务器
        return baseUrl + url;
    }

}
