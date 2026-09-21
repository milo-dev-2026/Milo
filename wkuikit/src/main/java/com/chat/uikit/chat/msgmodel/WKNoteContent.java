package com.chat.uikit.chat.msgmodel;

import android.os.Parcel;
import android.text.TextUtils;

import androidx.annotation.NonNull;

import org.json.JSONException;
import org.json.JSONObject;

/**
 * 笔记消息内容类 - 用于在聊天中分享笔记
 */
public class WKNoteContent extends com.xinbida.wukongim.msgmodel.WKMessageContent {

    public static final int TYPE = 100;

    public String noteId;
    public String noteTitle;
    public String noteContent;
    public String noteGroup;
    public String noteTime;
    public String blockListJson;
    public String coverUrl;   // 笔记封面图URL（第一张图片），接收方直接加载
    public String resource;   // 兼容utalk的封面图字段，与coverUrl含义一致
    public String resourceType; // 兼容utalk的资源类型字段
    public String summary;    // 笔记摘要
    public int containVideo;  // 是否包含视频 1=是 0=否
    public int containLocation; // 是否包含位置 1=是 0=否

    public WKNoteContent() {
        type = TYPE;
    }

    public WKNoteContent(String noteId, String noteTitle, String noteContent, String noteGroup, String noteTime, String blockListJson) {
        this();
        this.noteId = noteId;
        this.noteTitle = noteTitle;
        this.noteContent = noteContent;
        this.noteGroup = noteGroup;
        this.noteTime = noteTime;
        this.blockListJson = blockListJson;
    }

    @NonNull
    @Override
    public JSONObject encodeMsg() {
        JSONObject jsonObject = new JSONObject();
        try {
            jsonObject.put("noteId", noteId != null ? noteId : "");
            jsonObject.put("noteTitle", noteTitle != null ? noteTitle : "");
            jsonObject.put("noteContent", noteContent != null ? noteContent : "");
            jsonObject.put("noteGroup", noteGroup != null ? noteGroup : "");
            jsonObject.put("noteTime", noteTime != null ? noteTime : "");
            jsonObject.put("blockListJson", blockListJson != null ? blockListJson : "");
            // 确保coverUrl和resource一致，优先使用coverUrl
            String cover = (coverUrl != null && !coverUrl.isEmpty()) ? coverUrl : (resource != null ? resource : "");
            jsonObject.put("coverUrl", cover);
            jsonObject.put("resource", cover);  // 兼容utalk字段
            jsonObject.put("resourceType", resourceType != null ? resourceType : "");
            jsonObject.put("summary", summary != null ? summary : "");
            jsonObject.put("containVideo", containVideo);
            jsonObject.put("containLocation", containLocation);
            android.util.Log.d("WKNoteContent", "encodeMsg: coverUrl=" + cover + ", summary=" + summary + ", title=" + noteTitle);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return jsonObject;
    }

    @Override
    public WKNoteContent decodeMsg(@NonNull JSONObject jsonObject) {
        noteId = jsonObject.optString("noteId", "");
        noteTitle = jsonObject.optString("noteTitle", "");
        noteContent = jsonObject.optString("noteContent", "");
        noteGroup = jsonObject.optString("noteGroup", "");
        noteTime = jsonObject.optString("noteTime", "");
        blockListJson = jsonObject.optString("blockListJson", "");
        // 兼容utalk：coverUrl和resource都可能是封面图，优先使用coverUrl，其次resource
        String cover = jsonObject.optString("coverUrl", "");
        if (TextUtils.isEmpty(cover)) {
            cover = jsonObject.optString("resource", "");
        }
        coverUrl = cover;
        resource = cover;
        resourceType = jsonObject.optString("resourceType", "");
        summary = jsonObject.optString("summary", "");
        containVideo = jsonObject.optInt("containVideo", 0);
        containLocation = jsonObject.optInt("containLocation", 0);
        android.util.Log.d("WKNoteContent", "decodeMsg: coverUrl=" + coverUrl + ", title=" + noteTitle + ", json=" + jsonObject.toString());
        return this;
    }

    protected WKNoteContent(Parcel in) {
        super(in);
        type = TYPE;
        noteId = in.readString();
        noteTitle = in.readString();
        noteContent = in.readString();
        noteGroup = in.readString();
        noteTime = in.readString();
        blockListJson = in.readString();
        coverUrl = in.readString();
        resource = in.readString();
        resourceType = in.readString();
        summary = in.readString();
        containVideo = in.readInt();
        containLocation = in.readInt();
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        super.writeToParcel(dest, flags);
        dest.writeString(noteId);
        dest.writeString(noteTitle);
        dest.writeString(noteContent);
        dest.writeString(noteGroup);
        dest.writeString(noteTime);
        dest.writeString(blockListJson);
        dest.writeString(coverUrl);
        dest.writeString(resource);
        dest.writeString(resourceType);
        dest.writeString(summary);
        dest.writeInt(containVideo);
        dest.writeInt(containLocation);
    }

    public static final Creator<WKNoteContent> CREATOR = new Creator<WKNoteContent>() {
        @Override
        public WKNoteContent createFromParcel(Parcel in) {
            return new WKNoteContent(in);
        }

        @Override
        public WKNoteContent[] newArray(int size) {
            return new WKNoteContent[size];
        }
    };

    @Override
    public int describeContents() {
        return 0;
    }

    @Override
    public String getDisplayContent() {
        return "[笔记] " + (noteTitle != null && !noteTitle.isEmpty() ? noteTitle : "无标题");
    }
}
