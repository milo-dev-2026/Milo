package com.chat.uikit.chat.manager;

import com.chat.base.msgitem.WKUIChatMsgItemEntity;

import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ConcurrentHashMap;

/**
 * 聊天消息内存缓存
 * 应用运行期间有效，退出APP自动清空
 * 用于快速进入聊天页面时先显示缓存，再后台同步最新消息
 */
public class ChatMsgCacheManager {
    private static final ChatMsgCacheManager instance = new ChatMsgCacheManager();
    private final ConcurrentHashMap<String, List<WKUIChatMsgItemEntity>> cacheMap = new ConcurrentHashMap<>();
    // 缓存最大数量，防止内存溢出
    private static final int MAX_CACHE_COUNT = 20;

    private ChatMsgCacheManager() {}

    public static ChatMsgCacheManager getInstance() {
        return instance;
    }

    private String getKey(String channelId, int channelType) {
        return channelId + "_" + channelType;
    }

    /**
     * 获取缓存的消息列表
     */
    public List<WKUIChatMsgItemEntity> getCache(String channelId, int channelType) {
        String key = getKey(channelId, channelType);
        List<WKUIChatMsgItemEntity> list = cacheMap.get(key);
        if (list != null) {
            return new ArrayList<>(list);
        }
        return null;
    }

    /**
     * 保存消息列表到缓存
     */
    public void putCache(String channelId, int channelType, List<WKUIChatMsgItemEntity> list) {
        if (list == null || list.isEmpty()) return;
        // 控制缓存数量，超过则清除最老的
        if (cacheMap.size() >= MAX_CACHE_COUNT) {
            String firstKey = cacheMap.keys().nextElement();
            cacheMap.remove(firstKey);
        }
        String key = getKey(channelId, channelType);
        // 复制一份，避免外部修改影响缓存
        cacheMap.put(key, new ArrayList<>(list));
    }

    /**
     * 清除指定频道缓存
     */
    public void removeCache(String channelId, int channelType) {
        String key = getKey(channelId, channelType);
        cacheMap.remove(key);
    }

    /**
     * 清除所有缓存（退出登录时调用）
     */
    public void clearAll() {
        cacheMap.clear();
    }

    /**
     * 判断是否有缓存
     */
    public boolean hasCache(String channelId, int channelType) {
        return cacheMap.containsKey(getKey(channelId, channelType));
    }
}
