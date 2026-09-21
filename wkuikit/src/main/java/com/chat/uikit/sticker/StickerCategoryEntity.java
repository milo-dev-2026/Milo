package com.chat.uikit.sticker;

import org.json.JSONObject;

public class StickerCategoryEntity {
    public String categoryID;
    public String name;
    public String cover;
    public String desc;
    public int sort;
    public boolean isAdded;
    public boolean isCustom;

    public static StickerCategoryEntity fromJson(JSONObject json) {
        StickerCategoryEntity category = new StickerCategoryEntity();
        try {
            category.categoryID = json.optString("category_id", "");
            category.name = json.optString("name", "");
            category.cover = json.optString("cover", "");
            category.desc = json.optString("desc", "");
            category.sort = json.optInt("sort", 0);
            category.isAdded = json.optBoolean("is_added", false);
            category.isCustom = json.optBoolean("is_custom", false);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return category;
    }

    public JSONObject toJson() {
        JSONObject json = new JSONObject();
        try {
            json.put("category_id", categoryID);
            json.put("name", name);
            json.put("cover", cover);
            json.put("desc", desc);
            json.put("sort", sort);
            json.put("is_added", isAdded);
            json.put("is_custom", isCustom);
        } catch (Exception e) {
            e.printStackTrace();
        }
        return json;
    }
}
