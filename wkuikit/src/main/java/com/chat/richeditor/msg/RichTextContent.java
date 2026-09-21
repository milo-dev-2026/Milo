package com.chat.richeditor.msg;

import android.os.Parcel;

import androidx.annotation.NonNull;

import com.chat.uikit.R;
import com.xinbida.wukongim.message.type.WKMsgContentType;
import com.xinbida.wukongim.msgmodel.WKMessageContent;
import com.xinbida.wukongim.msgmodel.WKMsgEntity;

import org.json.JSONArray;
import org.json.JSONException;
import org.json.JSONObject;

import java.util.ArrayList;
import java.util.List;

/**
 * 富文本消息内容
 */
public class RichTextContent extends WKMessageContent {

    public List<WKMsgEntity> entities;

    public RichTextContent() {
        type = 14; // WKContentType.richText
    }

    public RichTextContent(String content) {
        this();
        this.content = content;
    }

    @NonNull
    @Override
    public JSONObject encodeMsg() {
        JSONObject jsonObject = new JSONObject();
        try {
            jsonObject.put("content", content);
            if (entities != null && !entities.isEmpty()) {
                JSONArray jsonArray = new JSONArray();
                for (WKMsgEntity entity : entities) {
                    JSONObject entityJson = new JSONObject();
                    entityJson.put("type", entity.type);
                    entityJson.put("offset", entity.offset);
                    entityJson.put("length", entity.length);
                    if (entity.value != null) {
                        entityJson.put("value", entity.value);
                    }
                    jsonArray.put(entityJson);
                }
                jsonObject.put("entities", jsonArray);
            }
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return jsonObject;
    }

    @Override
    public WKMessageContent decodeMsg(JSONObject jsonObject) {
        content = jsonObject.optString("content");
        JSONArray entitiesArray = jsonObject.optJSONArray("entities");
        if (entitiesArray != null && entitiesArray.length() > 0) {
            entities = new ArrayList<>();
            for (int i = 0; i < entitiesArray.length(); i++) {
                JSONObject entityJson = entitiesArray.optJSONObject(i);
                if (entityJson != null) {
                    WKMsgEntity entity = new WKMsgEntity();
                    entity.type = entityJson.optString("type");
                    entity.offset = entityJson.optInt("offset");
                    entity.length = entityJson.optInt("length");
                    entity.value = entityJson.optString("value");
                    entities.add(entity);
                }
            }
        }
        return this;
    }

    protected RichTextContent(Parcel in) {
        super(in);
        content = in.readString();
        // 使用 JSON 字符串序列化 entities，避免依赖 WKMsgEntity.CREATOR
        String entitiesJsonStr = in.readString();
        if (entitiesJsonStr != null && !entitiesJsonStr.isEmpty()) {
            try {
                JSONArray entitiesArray = new JSONArray(entitiesJsonStr);
                entities = new ArrayList<>();
                for (int i = 0; i < entitiesArray.length(); i++) {
                    JSONObject entityJson = entitiesArray.optJSONObject(i);
                    if (entityJson != null) {
                        WKMsgEntity entity = new WKMsgEntity();
                        entity.type = entityJson.optString("type");
                        entity.offset = entityJson.optInt("offset");
                        entity.length = entityJson.optInt("length");
                        entity.value = entityJson.optString("value");
                        entities.add(entity);
                    }
                }
            } catch (JSONException e) {
                e.printStackTrace();
            }
        }
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        super.writeToParcel(dest, flags);
        dest.writeString(content);
        // 使用 JSON 字符串序列化 entities
        if (entities != null && !entities.isEmpty()) {
            JSONArray jsonArray = new JSONArray();
            for (WKMsgEntity entity : entities) {
                try {
                    JSONObject entityJson = new JSONObject();
                    entityJson.put("type", entity.type);
                    entityJson.put("offset", entity.offset);
                    entityJson.put("length", entity.length);
                    if (entity.value != null) {
                        entityJson.put("value", entity.value);
                    }
                    jsonArray.put(entityJson);
                } catch (JSONException e) {
                    e.printStackTrace();
                }
            }
            dest.writeString(jsonArray.toString());
        } else {
            dest.writeString("");
        }
    }

    public static final Creator<RichTextContent> CREATOR = new Creator<RichTextContent>() {
        @Override
        public RichTextContent createFromParcel(Parcel in) {
            return new RichTextContent(in);
        }

        @Override
        public RichTextContent[] newArray(int size) {
            return new RichTextContent[size];
        }
    };

    @Override
    public int describeContents() {
        return 0;
    }

    @Override
    public String getDisplayContent() {
        return content;
    }

    @Override
    public String getSearchableWord() {
        return content;
    }
}
