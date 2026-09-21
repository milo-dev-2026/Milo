package com.chat.uikit.sticker;

import org.json.JSONObject;

public class StickerEntity {
    public String stickerID;
    public String categoryID;
    public String url;
    public String name;
    public int sort;
    public int type; // 0=emoji, 1=gif, 2=image
    public int width;
    public int height;
    public boolean isCustom;

    public static StickerEntity fromJson(JSONObject json) {
        StickerEntity sticker = new StickerEntity();
        try {
            sticker.stickerID = json.optString("sticker_id", "");
            sticker.categoryID = json.optString("category_id", "");
            sticker.url = json.optString("url", "");
            sticker.name = json.optString("name", "");
            sticker.sort = json.optInt("sort", 0);
            sticker.type = json.optInt("type", 0);
            sticker.width = json.optInt("width", 120);
            sticker.height = json.optInt("height", 120);
            sticker.isCustom = json.optBoolean("is_custom", false);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return sticker;
    }

    public JSONObject toJson() {
        JSONObject json = new JSONObject();
        try {
            json.put("sticker_id", stickerID);
            json.put("category_id", categoryID);
            json.put("url", url);
            json.put("name", name);
            json.put("sort", sort);
            json.put("type", type);
            json.put("width", width);
            json.put("height", height);
            json.put("is_custom", isCustom);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return json;
    }
}
