package com.chat.uikit.sticker;

import android.content.Context;
import android.os.Handler;
import android.os.Looper;

import com.chat.base.config.WKApiConfig;
import com.chat.base.config.WKSharedPreferencesUtil;

import org.json.JSONArray;
import org.json.JSONObject;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;
import java.util.ArrayList;
import java.util.Collections;
import java.util.List;

public class StickerService {

    private static StickerService instance;
    private Context appContext;

    public static synchronized StickerService getInstance() {
        if (instance == null) {
            instance = new StickerService();
        }
        return instance;
    }

    public void init(Context context) {
        this.appContext = context.getApplicationContext();
    }

    private static final String SP_KEY_STICKERS = "stickers_data";
    private static final String SP_KEY_CATEGORIES = "sticker_categories";
    private static final String SP_KEY_MY_STICKERS = "my_stickers";
    private static final String SP_KEY_STICKER_ORDER = "sticker_order";
    private static final String SP_KEY_MY_CATEGORIES = "my_sticker_categories";

    public interface DataCallback<T> {
        void onSuccess(T data);
        void onError(String error);
    }

    // ==================== 贴纸商店分类 ====================

    public void fetchStoreCategories(DataCallback<List<StickerCategoryEntity>> callback) {
        String apiUrl = WKApiConfig.baseUrl;
        if (apiUrl == null || apiUrl.isEmpty()) {
            loadLocalCategories(callback);
            return;
        }
        new Thread(() -> {
            try {
                URL url = new URL(apiUrl + "/api/sticker/categories");
                HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                conn.setConnectTimeout(5000);
                conn.setReadTimeout(5000);
                conn.setRequestMethod("GET");
                int code = conn.getResponseCode();
                if (code == 200) {
                    String response = readResponse(conn.getInputStream());
                    List<StickerCategoryEntity> categories = parseCategoriesResponse(response);
                    saveCategoriesLocally(categories);
                    notifyOnMain(() -> callback.onSuccess(categories));
                } else {
                    notifyOnMain(() -> loadLocalCategories(callback));
                }
                conn.disconnect();
            } catch (Exception e) {
                notifyOnMain(() -> loadLocalCategories(callback));
            }
        }).start();
    }

    private List<StickerCategoryEntity> parseCategoriesResponse(String json) {
        List<StickerCategoryEntity> categories = new ArrayList<>();
        try {
            JSONObject obj = new JSONObject(json);
            JSONArray array = obj.optJSONArray("data");
            if (array != null) {
                for (int i = 0; i < array.length(); i++) {
                    categories.add(StickerCategoryEntity.fromJson(array.getJSONObject(i)));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return categories;
    }

    private void saveCategoriesLocally(List<StickerCategoryEntity> categories) {
        JSONArray array = new JSONArray();
        for (StickerCategoryEntity c : categories) {
            array.put(c.toJson());
        }
        WKSharedPreferencesUtil.getInstance().putSP(SP_KEY_CATEGORIES, array.toString());
    }

    private void loadLocalCategories(DataCallback<List<StickerCategoryEntity>> callback) {
        List<StickerCategoryEntity> categories = getStickerCategories();
        if (categories.isEmpty() || categories.size() <= 3) {
            categories = seedStoreCategories();
            saveCategoriesLocally(categories);
        }
        List<StickerCategoryEntity> finalCategories = categories;
        notifyOnMain(() -> callback.onSuccess(finalCategories));
    }

    private List<StickerCategoryEntity> seedStoreCategories() {
        List<StickerCategoryEntity> list = new ArrayList<>();
        String[][] data = {
                {"store_1", "可爱表情包", "超可爱的表情包合集"},
                {"store_2", "萌宠日常", "萌化你的心的宠物贴纸"},
                {"store_3", "职场生存", "打工人必备表情包"},
                {"store_4", "恋爱物语", "恋爱中的甜蜜瞬间"},
                {"store_5", "节日祝福", "节日问候贴纸包"},
                {"store_6", "动漫精选", "经典动漫角色贴纸"},
                {"store_7", "搞笑沙雕", "让人捧腹大笑的沙雕图"},
                {"store_8", "治愈系", "温暖治愈系贴纸"}
        };
        for (int i = 0; i < data.length; i++) {
            StickerCategoryEntity c = new StickerCategoryEntity();
            c.categoryID = data[i][0];
            c.name = data[i][1];
            c.desc = data[i][2];
            c.sort = i;
            c.isAdded = i < 3;
            list.add(c);
        }
        return list;
    }

    public List<StickerCategoryEntity> getStickerCategories() {
        List<StickerCategoryEntity> categories = new ArrayList<>();
        String saved = WKSharedPreferencesUtil.getInstance().getSP(SP_KEY_CATEGORIES);
        if (saved != null && !saved.isEmpty()) {
            try {
                JSONArray array = new JSONArray(saved);
                for (int i = 0; i < array.length(); i++) {
                    categories.add(StickerCategoryEntity.fromJson(array.getJSONObject(i)));
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        if (categories.isEmpty()) {
            categories = seedStoreCategories();
        }
        return categories;
    }

    // ==================== 分类下贴纸列表 ====================

    public void fetchStickersByCategory(String categoryID, DataCallback<List<StickerEntity>> callback) {
        String apiUrl = WKApiConfig.baseUrl;
        if (apiUrl == null || apiUrl.isEmpty()) {
            List<StickerEntity> local = getStickersByCategory(categoryID);
            if (local.isEmpty()) {
                local = seedStickersForCategory(categoryID);
                saveStickersLocally(categoryID, local);
            }
            List<StickerEntity> finalLocal = local;
            notifyOnMain(() -> callback.onSuccess(finalLocal));
            return;
        }
        new Thread(() -> {
            try {
                URL url = new URL(apiUrl + "/api/sticker/list?category_id=" + categoryID);
                HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                conn.setConnectTimeout(5000);
                conn.setReadTimeout(5000);
                conn.setRequestMethod("GET");
                int code = conn.getResponseCode();
                if (code == 200) {
                    String response = readResponse(conn.getInputStream());
                    List<StickerEntity> stickers = parseStickersResponse(response);
                    saveStickersLocally(categoryID, stickers);
                    notifyOnMain(() -> callback.onSuccess(stickers));
                } else {
                    List<StickerEntity> local = getStickersByCategory(categoryID);
                    if (local.isEmpty()) {
                        local = seedStickersForCategory(categoryID);
                        saveStickersLocally(categoryID, local);
                    }
                    List<StickerEntity> finalLocal = local;
                    notifyOnMain(() -> callback.onSuccess(finalLocal));
                }
                conn.disconnect();
            } catch (Exception e) {
                List<StickerEntity> local = getStickersByCategory(categoryID);
                if (local.isEmpty()) {
                    local = seedStickersForCategory(categoryID);
                    saveStickersLocally(categoryID, local);
                }
                List<StickerEntity> finalLocal = local;
                notifyOnMain(() -> callback.onSuccess(finalLocal));
            }
        }).start();
    }

    private List<StickerEntity> parseStickersResponse(String json) {
        List<StickerEntity> stickers = new ArrayList<>();
        try {
            JSONObject obj = new JSONObject(json);
            JSONArray array = obj.optJSONArray("data");
            if (array != null) {
                for (int i = 0; i < array.length(); i++) {
                    stickers.add(StickerEntity.fromJson(array.getJSONObject(i)));
                }
            }
        } catch (Exception e) {
            e.printStackTrace();
        }
        return stickers;
    }

    private void saveStickersLocally(String categoryID, List<StickerEntity> stickers) {
        JSONArray array = new JSONArray();
        for (StickerEntity s : stickers) {
            array.put(s.toJson());
        }
        WKSharedPreferencesUtil.getInstance().putSP(SP_KEY_STICKERS + "_" + categoryID, array.toString());
    }

    private List<StickerEntity> seedStickersForCategory(String categoryID) {
        List<StickerEntity> list = new ArrayList<>();
        int count = 16;
        for (int i = 0; i < count; i++) {
            StickerEntity s = new StickerEntity();
            s.stickerID = categoryID + "_sticker_" + i;
            s.categoryID = categoryID;
            s.url = "";
            s.name = "贴纸 " + (i + 1);
            s.sort = i;
            s.type = i % 2;
            s.width = 120;
            s.height = 120;
            list.add(s);
        }
        return list;
    }

    public List<StickerEntity> getStickersByCategory(String categoryID) {
        List<StickerEntity> stickers = new ArrayList<>();
        String saved = WKSharedPreferencesUtil.getInstance().getSP(SP_KEY_STICKERS + "_" + categoryID);
        if (saved != null && !saved.isEmpty()) {
            try {
                JSONArray array = new JSONArray(saved);
                for (int i = 0; i < array.length(); i++) {
                    stickers.add(StickerEntity.fromJson(array.getJSONObject(i)));
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        return stickers;
    }

    // ==================== 我的贴纸 ====================

    public List<StickerEntity> getMyStickers() {
        List<StickerEntity> stickers = new ArrayList<>();
        String saved = WKSharedPreferencesUtil.getInstance().getSP(SP_KEY_MY_STICKERS);
        if (saved != null && !saved.isEmpty()) {
            try {
                JSONArray array = new JSONArray(saved);
                for (int i = 0; i < array.length(); i++) {
                    stickers.add(StickerEntity.fromJson(array.getJSONObject(i)));
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }
        return stickers;
    }

    public boolean addSticker(StickerEntity sticker) {
        List<StickerEntity> stickers = getMyStickers();
        for (StickerEntity s : stickers) {
            if (s.stickerID.equals(sticker.stickerID)) {
                return false;
            }
        }
        stickers.add(sticker);
        saveMyStickers(stickers);
        return true;
    }

    public boolean removeSticker(String stickerID) {
        List<StickerEntity> stickers = new ArrayList<>();
        List<StickerEntity> all = getMyStickers();
        boolean found = false;
        for (StickerEntity s : all) {
            if (!s.stickerID.equals(stickerID)) {
                stickers.add(s);
            } else {
                found = true;
            }
        }
        saveMyStickers(stickers);
        return found;
    }

    public boolean reorderStickers(List<StickerEntity> reorderedList) {
        saveMyStickers(reorderedList);
        return true;
    }

    private void saveMyStickers(List<StickerEntity> stickers) {
        JSONArray array = new JSONArray();
        for (StickerEntity s : stickers) {
            array.put(s.toJson());
        }
        WKSharedPreferencesUtil.getInstance().putSP(SP_KEY_MY_STICKERS, array.toString());
    }

    // ==================== 我的贴纸分类 ====================

    public List<StickerCategoryEntity> getMyCategories() {
        List<StickerCategoryEntity> categories = new ArrayList<>();
        String saved = WKSharedPreferencesUtil.getInstance().getSP(SP_KEY_MY_CATEGORIES);
        if (saved != null && !saved.isEmpty()) {
            try {
                JSONArray array = new JSONArray(saved);
                for (int i = 0; i < array.length(); i++) {
                    categories.add(StickerCategoryEntity.fromJson(array.getJSONObject(i)));
                }
            } catch (Exception e) {
                e.printStackTrace();
            }
        }

        if (categories.isEmpty()) {
            for (StickerCategoryEntity c : getStickerCategories()) {
                if (c.isAdded) {
                    categories.add(c);
                }
            }
        }
        return categories;
    }

    public boolean addCategory(StickerCategoryEntity category) {
        List<StickerCategoryEntity> categories = getMyCategories();
        for (StickerCategoryEntity c : categories) {
            if (c.categoryID.equals(category.categoryID)) {
                return false;
            }
        }
        category.isAdded = true;
        categories.add(category);
        saveMyCategories(categories);
        updateCategoryAddedStatus(category.categoryID, true);
        return true;
    }

    public boolean removeCategory(String categoryID) {
        List<StickerCategoryEntity> categories = new ArrayList<>();
        List<StickerCategoryEntity> all = getMyCategories();
        for (StickerCategoryEntity c : all) {
            if (!c.categoryID.equals(categoryID)) {
                categories.add(c);
            }
        }
        saveMyCategories(categories);
        updateCategoryAddedStatus(categoryID, false);
        return true;
    }

    public boolean reorderCategories(List<StickerCategoryEntity> reorderedList) {
        saveMyCategories(reorderedList);
        return true;
    }

    private void saveMyCategories(List<StickerCategoryEntity> categories) {
        JSONArray array = new JSONArray();
        for (StickerCategoryEntity c : categories) {
            array.put(c.toJson());
        }
        WKSharedPreferencesUtil.getInstance().putSP(SP_KEY_MY_CATEGORIES, array.toString());
    }

    private void updateCategoryAddedStatus(String categoryID, boolean added) {
        List<StickerCategoryEntity> all = getStickerCategories();
        for (StickerCategoryEntity c : all) {
            if (c.categoryID.equals(categoryID)) {
                c.isAdded = added;
                break;
            }
        }
        saveCategoriesLocally(all);
    }

    // ==================== 贴纸下载 ====================

    public void downloadSticker(StickerEntity sticker, DataCallback<Boolean> callback) {
        if (sticker.url == null || sticker.url.isEmpty()) {
            addSticker(sticker);
            notifyOnMain(() -> callback.onSuccess(true));
            return;
        }
        new Thread(() -> {
            try {
                URL url = new URL(sticker.url);
                HttpURLConnection conn = (HttpURLConnection) url.openConnection();
                conn.setConnectTimeout(10000);
                conn.setReadTimeout(10000);
                int code = conn.getResponseCode();
                conn.disconnect();
                if (code == 200) {
                    addSticker(sticker);
                    notifyOnMain(() -> callback.onSuccess(true));
                } else {
                    addSticker(sticker);
                    notifyOnMain(() -> callback.onSuccess(true));
                }
            } catch (Exception e) {
                addSticker(sticker);
                notifyOnMain(() -> callback.onSuccess(true));
            }
        }).start();
    }

    // ==================== 工具方法 ====================

    private String readResponse(InputStream is) throws Exception {
        BufferedReader reader = new BufferedReader(new InputStreamReader(is));
        StringBuilder sb = new StringBuilder();
        String line;
        while ((line = reader.readLine()) != null) {
            sb.append(line);
        }
        reader.close();
        return sb.toString();
    }

    private void notifyOnMain(Runnable runnable) {
        new Handler(Looper.getMainLooper()).post(runnable);
    }
}
