package com.chat.uikit.favorite;

import android.content.Context;

import com.chat.base.config.WKSharedPreferencesUtil;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

public class FavoriteStorageManager {
    private static FavoriteStorageManager instance;
    private final Context context;
    private static final String SP_KEY_FAVORITES = "favorite_list";
    private static final String SP_KEY_FAVORITES_VERSION = "favorite_list_version";
    private static final int CURRENT_VERSION = 2;

    private FavoriteStorageManager(Context context) {
        this.context = context.getApplicationContext();
        cleanupOldDataIfNeeded();
    }

    public static FavoriteStorageManager getInstance(Context context) {
        if (instance == null) {
            synchronized (FavoriteStorageManager.class) {
                if (instance == null) {
                    instance = new FavoriteStorageManager(context);
                }
            }
        }
        return instance;
    }

    private void cleanupOldDataIfNeeded() {
        int version = WKSharedPreferencesUtil.getInstance().getInt(SP_KEY_FAVORITES_VERSION, 0);
        if (version < CURRENT_VERSION) {
            WKSharedPreferencesUtil.getInstance().putSP(SP_KEY_FAVORITES, "");
            WKSharedPreferencesUtil.getInstance().putInt(SP_KEY_FAVORITES_VERSION, CURRENT_VERSION);
        }
    }

    public void addFavorite(int type, String content, String extra) {
        addFavorite(type, content, extra, "", "");
    }

    public void addFavorite(int type, String content, String extra, String senderName, String time) {
        addFavorite(type, content, extra, senderName, time, 0, 0, null);
    }

    public void addFavorite(int type, String content, String extra, String senderName, String time, int width, int height, String videoUrl) {
        List<FavoriteItem> list = getAllFavorites();
        FavoriteItem item = new FavoriteItem();
        item.id = System.currentTimeMillis();
        item.type = type;
        item.content = content;
        item.extra = extra;
        item.senderName = senderName;
        item.time = time;
        item.width = width;
        item.height = height;
        item.videoUrl = videoUrl;
        list.add(0, item);
        saveFavorites(list);
    }

    public void removeFavorite(long id) {
        List<FavoriteItem> list = getAllFavorites();
        for (int i = 0; i < list.size(); i++) {
            if (list.get(i).id == id) {
                list.remove(i);
                break;
            }
        }
        saveFavorites(list);
    }

    public List<FavoriteItem> getAllFavorites() {
        List<FavoriteItem> list = new ArrayList<>();
        String json = WKSharedPreferencesUtil.getInstance().getSP(SP_KEY_FAVORITES);
        if (json != null && !json.isEmpty()) {
            try {
                JSONArray array = new JSONArray(json);
                for (int i = 0; i < array.length(); i++) {
                    JSONObject obj = array.getJSONObject(i);
                    FavoriteItem item = new FavoriteItem();
                    item.id = obj.optLong("id", 0);
                    item.type = obj.optInt("type", 1);
                    item.content = obj.optString("content", "");
                    item.extra = obj.optString("extra", "");
                    item.senderName = obj.optString("senderName", "");
                    item.time = obj.optString("time", "");
                    item.fromConversation = obj.optString("fromConversation", "");
                    item.width = obj.optInt("width", 0);
                    item.height = obj.optInt("height", 0);
                    item.videoUrl = obj.optString("videoUrl", "");
                    list.add(item);
                }
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
        return list;
    }

    public void clearAll() {
        WKSharedPreferencesUtil.getInstance().putSP(SP_KEY_FAVORITES, "");
    }

    private void saveFavorites(List<FavoriteItem> list) {
        JSONArray array = new JSONArray();
        for (FavoriteItem item : list) {
            JSONObject obj = new JSONObject();
            try {
                obj.put("id", item.id);
                obj.put("type", item.type);
                obj.put("content", item.content != null ? item.content : "");
                obj.put("extra", item.extra != null ? item.extra : "");
                obj.put("senderName", item.senderName != null ? item.senderName : "");
                obj.put("time", item.time != null ? item.time : "");
                obj.put("fromConversation", item.fromConversation != null ? item.fromConversation : "");
                obj.put("width", item.width);
                obj.put("height", item.height);
                obj.put("videoUrl", item.videoUrl != null ? item.videoUrl : "");
                array.put(obj);
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
        WKSharedPreferencesUtil.getInstance().putSP(SP_KEY_FAVORITES, array.toString());
    }
}
