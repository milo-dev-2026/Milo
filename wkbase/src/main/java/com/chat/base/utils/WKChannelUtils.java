package com.chat.base.utils;

import com.xinbida.wukongim.entity.WKChannel;

/**
 * 频道相关工具类
 */
public class WKChannelUtils {

    private WKChannelUtils() {
    }

    private static class ChannelUtilsBinder {
        final static WKChannelUtils utils = new WKChannelUtils();
    }

    public static WKChannelUtils getInstance() {
        return ChannelUtilsBinder.utils;
    }

    /**
     * 判断群是否开启了全员禁言
     * 优先使用 SDK 标准字段 forbidden（WuKongIM 核心禁言逻辑基于此字段），
     * remote_extra 中的 forbidden 仅作为兜底兼容
     */
    public boolean isGroupForbidden(WKChannel channel) {
        if (channel == null) return false;
        // 标准字段优先 - WuKongIM 的禁言功能基于此字段
        if (channel.forbidden == 1) {
            return true;
        }
        // 兜底：从 remote_extra 读取（兼容旧数据）
        if (channel.remoteExtraMap != null && channel.remoteExtraMap.containsKey("forbidden")) {
            Object valObj = channel.remoteExtraMap.get("forbidden");
            if (valObj instanceof Integer) {
                return (int) valObj == 1;
            }
            if (valObj instanceof Number) {
                return ((Number) valObj).intValue() == 1;
            }
        }
        return false;
    }
}
