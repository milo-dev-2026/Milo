package com.chat.base.utils;

import android.content.Context;
import android.content.SharedPreferences;
import android.text.TextUtils;
import android.util.Log;

import com.chat.base.WKBaseApplication;
import com.chat.base.config.WKApiConfig;
import com.chat.base.net.ud.WKDownloader;
import com.chat.base.net.ud.WKProgressManager;

import java.io.File;
import java.util.LinkedList;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.atomic.AtomicInteger;

/**
 * 视频预下载工具：收到视频消息后在后台自动下载，用户点击播放时直接读本地文件实现秒开。
 * <p>
 * 优化策略：
 * 1. 优先级队列：最新消息优先下载
 * 2. 并发控制：最多同时下载3个视频
 * 3. 缓存上限：最多缓存50个视频，超过则淘汰最旧的
 * 4. 去重：同一URL只下载一次
 */
public class VideoPreDownloader {
    private static final String TAG = "VideoPreDownloader";
    private static final String PREF_NAME = "video_pre_download";
    private static final String KEY_PREFIX = "video_";
    private static final String VIDEO_DIR = "pre_downloaded_video";
    private static final int MAX_PARALLEL = 3;       // 最大并发下载数
    private static final int MAX_CACHE_COUNT = 50;    // 最大缓存视频数

    private static volatile VideoPreDownloader instance;
    private final SharedPreferences prefs;
    private final ConcurrentHashMap<String, Boolean> downloading = new ConcurrentHashMap<>();
    private final ConcurrentHashMap<String, Long> cachedOrder = new ConcurrentHashMap<>(); // url -> timestamp
    private final LinkedList<String> pendingQueue = new LinkedList<>(); // 待下载队列（按优先级排序）
    private final AtomicInteger activeDownloads = new AtomicInteger(0);

    private VideoPreDownloader() {
        prefs = WKBaseApplication.getInstance().application
                .getSharedPreferences(PREF_NAME, Context.MODE_PRIVATE);
    }

    public static VideoPreDownloader getInstance() {
        if (instance == null) {
            synchronized (VideoPreDownloader.class) {
                if (instance == null) {
                    instance = new VideoPreDownloader();
                }
            }
        }
        return instance;
    }

    /**
     * 尝试预下载视频。最新消息优先下载。
     * 线程安全，可安全多次调用同一 URL。
     */
    public void preDownload(String url) {
        if (TextUtils.isEmpty(url) || !url.startsWith("http")) return;
        if (url.toLowerCase().endsWith(".m3u8")) return;

        // 已有本地缓存，跳过
        if (getCachedPath(url) != null) {
            return;
        }

        // 正在下载中，跳过
        if (downloading.containsKey(url)) {
            return;
        }

        // 检查队列中是否已存在
        synchronized (pendingQueue) {
            if (pendingQueue.contains(url)) {
                // 移到队首（提高优先级）
                pendingQueue.remove(url);
                pendingQueue.addFirst(url);
                return;
            }
            // 加入队首（新消息优先）
            pendingQueue.addFirst(url);
        }

        // 尝试启动下一个下载
        startNextDownload();
    }

    private void startNextDownload() {
        if (activeDownloads.get() >= MAX_PARALLEL) return;

        String nextUrl;
        synchronized (pendingQueue) {
            if (pendingQueue.isEmpty()) return;
            nextUrl = pendingQueue.poll();
        }

        if (nextUrl == null) return;

        // 双重检查：可能已经缓存了
        if (getCachedPath(nextUrl) != null) {
            startNextDownload();
            return;
        }

        // 标记下载中
        if (downloading.putIfAbsent(nextUrl, true) != null) {
            startNextDownload();
            return;
        }

        activeDownloads.incrementAndGet();
        doDownload(nextUrl);
    }

    private void doDownload(String url) {
        Context app = WKBaseApplication.getInstance().application;
        File dir = new File(app.getExternalCacheDir(), VIDEO_DIR);
        if (!dir.exists()) dir.mkdirs();
        String fileName = KEY_PREFIX + Math.abs(url.hashCode()) + ".mp4";
        String localPath = new File(dir, fileName).getAbsolutePath();

        // url 已经是完整 URL（调用方已通过 WKApiConfig.getShowUrl 处理），直接下载
        WKDownloader.Companion.getInstance().download(url, localPath, new WKProgressManager.IProgress() {
            @Override
            public void onProgress(Object tag, int progress) {
            }

            @Override
            public void onSuccess(Object tag, String path) {
                downloading.remove(url);
                activeDownloads.decrementAndGet();
                prefs.edit().putString(KEY_PREFIX + url, path).apply();
                cachedOrder.put(url, System.currentTimeMillis());
                Log.d(TAG, "Pre-download success: " + url);
                // 检查缓存数量，超过上限清理最旧的
                checkCacheLimit();
                // 启动下一个下载
                startNextDownload();
            }

            @Override
            public void onFail(Object tag, String msg) {
                downloading.remove(url);
                activeDownloads.decrementAndGet();
                Log.w(TAG, "Pre-download failed: " + url + " " + msg);
                // 启动下一个下载
                startNextDownload();
            }
        });
    }

    private void checkCacheLimit() {
        if (cachedOrder.size() <= MAX_CACHE_COUNT) return;
        // 找到最旧的并删除
        String oldestUrl = null;
        long oldestTime = Long.MAX_VALUE;
        for (java.util.Map.Entry<String, Long> entry : cachedOrder.entrySet()) {
            if (entry.getValue() < oldestTime) {
                oldestTime = entry.getValue();
                oldestUrl = entry.getKey();
            }
        }
        if (oldestUrl != null) {
            String path = prefs.getString(KEY_PREFIX + oldestUrl, null);
            if (path != null) {
                new File(path).delete();
            }
            prefs.edit().remove(KEY_PREFIX + oldestUrl).apply();
            cachedOrder.remove(oldestUrl);
            Log.d(TAG, "Cache evicted: " + oldestUrl);
        }
    }

    /**
     * 获取已预下载的本地路径，不存在返回 null
     */
    public String getCachedPath(String url) {
        if (url == null) return null;
        String path = prefs.getString(KEY_PREFIX + url, null);
        if (path != null) {
            File f = new File(path);
            if (f.exists() && f.length() > 0) {
                // 更新访问时间
                cachedOrder.put(url, System.currentTimeMillis());
                return path;
            }
            // 文件不存在了，清理记录
            prefs.edit().remove(KEY_PREFIX + url).apply();
            cachedOrder.remove(url);
        }
        return null;
    }

    /**
     * 清理所有预下载缓存
     */
    public void clearCache() {
        Context app = WKBaseApplication.getInstance().application;
        File dir = new File(app.getExternalCacheDir(), VIDEO_DIR);
        if (dir.exists()) {
            File[] files = dir.listFiles();
            if (files != null) {
                for (File f : files) {
                    f.delete();
                }
            }
        }
        prefs.edit().clear().apply();
        cachedOrder.clear();
    }
}
