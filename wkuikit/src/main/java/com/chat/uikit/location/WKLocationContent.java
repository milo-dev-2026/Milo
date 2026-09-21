package com.chat.uikit.location;

import android.os.Parcel;

import androidx.annotation.NonNull;

import com.xinbida.wukongim.msgmodel.WKMediaMessageContent;
import com.xinbida.wukongim.msgmodel.WKMessageContent;

import org.json.JSONException;
import org.json.JSONObject;

/**
 * 位置消息内容
 */
public class WKLocationContent extends WKMediaMessageContent {

    public double latitude;
    public double longitude;
    public String address;
    public String title;

    public WKLocationContent() {
        type = 6; // WK_LOCATION
    }

    public WKLocationContent(double longitude, double latitude, String address, String title) {
        this();
        this.longitude = longitude;
        this.latitude = latitude;
        this.address = address;
        this.title = title;
    }

    @NonNull
    @Override
    public JSONObject encodeMsg() {
        JSONObject jsonObject = new JSONObject();
        try {
            jsonObject.put("title", title != null ? title : "");
            jsonObject.put("address", address != null ? address : "");
            jsonObject.put("lat", latitude);
            jsonObject.put("lng", longitude);
            jsonObject.put("url", url != null ? url : "");
            jsonObject.put("localPath", localPath != null ? localPath : "");
            jsonObject.put("type", type);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return jsonObject;
    }

    @Override
    public WKMessageContent decodeMsg(JSONObject jsonObject) {
        if (jsonObject == null) return this;
        if (jsonObject.has("lat")) {
            latitude = jsonObject.optDouble("lat");
        }
        if (jsonObject.has("lng")) {
            longitude = jsonObject.optDouble("lng");
        }
        if (jsonObject.has("longitude")) {
            longitude = jsonObject.optDouble("longitude");
        }
        address = jsonObject.optString("address");
        title = jsonObject.optString("title");
        // 优先读取 "url"（标准键），兼容旧数据的 "img" 键
        if (jsonObject.has("url")) {
            url = jsonObject.optString("url");
        } else {
            url = jsonObject.optString("img");
        }
        localPath = jsonObject.optString("localPath");
        return this;
    }

    protected WKLocationContent(Parcel in) {
        super(in);
        latitude = in.readDouble();
        longitude = in.readDouble();
        address = in.readString();
        title = in.readString();
    }

    @Override
    public void writeToParcel(Parcel dest, int flags) {
        super.writeToParcel(dest, flags);
        dest.writeDouble(latitude);
        dest.writeDouble(longitude);
        dest.writeString(address);
        dest.writeString(title);
    }

    public static final Creator<WKLocationContent> CREATOR = new Creator<WKLocationContent>() {
        @Override
        public WKLocationContent createFromParcel(Parcel in) {
            return new WKLocationContent(in);
        }

        @Override
        public WKLocationContent[] newArray(int size) {
            return new WKLocationContent[size];
        }
    };

    @Override
    public int describeContents() {
        return 0;
    }

    @Override
    public String getDisplayContent() {
        return "[位置]";
    }

    @Override
    public String getSearchableWord() {
        return title != null ? title : address;
    }
}
