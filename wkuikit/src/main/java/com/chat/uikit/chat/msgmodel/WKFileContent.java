package com.chat.uikit.chat.msgmodel;

import android.os.Parcel;

import androidx.annotation.NonNull;

import com.chat.uikit.R;
import com.xinbida.wukongim.message.type.WKMsgContentType;
import com.xinbida.wukongim.msgmodel.WKMediaMessageContent;
import com.xinbida.wukongim.msgmodel.WKMessageContent;

import org.json.JSONException;
import org.json.JSONObject;

public class WKFileContent extends WKMediaMessageContent {

    public String name;
    public long size;

    public WKFileContent() {
        type = WKMsgContentType.WK_FILE;
    }

    public WKFileContent(String localPath, String name, long size) {
        this();
        this.localPath = localPath;
        this.name = name;
        this.size = size;
    }

    @NonNull
    @Override
    public JSONObject encodeMsg() {
        JSONObject jsonObject = new JSONObject();
        try {
            jsonObject.put("name", name);
            jsonObject.put("size", size);
            jsonObject.put("url", url);
            jsonObject.put("localPath", localPath);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return jsonObject;
    }

    @Override
    public WKMessageContent decodeMsg(JSONObject jsonObject) {
        name = jsonObject.optString("name");
        size = jsonObject.optLong("size");
        url = jsonObject.optString("url");
        localPath = jsonObject.optString("localPath");
        return this;
    }

    protected WKFileContent(Parcel in) {
        super(in);
        name = in.readString();
        size = in.readLong();
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        super.writeToParcel(dest, flags);
        dest.writeString(name);
        dest.writeLong(size);
    }

    public static final Creator<WKFileContent> CREATOR = new Creator<WKFileContent>() {
        @Override
        public WKFileContent createFromParcel(Parcel in) {
            return new WKFileContent(in);
        }

        @Override
        public WKFileContent[] newArray(int size) {
            return new WKFileContent[size];
        }
    };

    @Override
    public int describeContents() {
        return 0;
    }

    @Override
    public String getDisplayContent() {
        return "[文件]";
    }

    public String getFileExtension() {
        if (name != null && name.contains(".")) {
            return name.substring(name.lastIndexOf(".") + 1).toUpperCase();
        }
        return "FILE";
    }
}
