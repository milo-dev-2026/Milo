package com.chat.api.entity.message;

import android.os.Parcel;
import android.os.Parcelable;

import org.json.JSONObject;

/**
 * 富文本消息实体
 */
public class WKMsgEntity implements Parcelable {

    public static final Parcelable.Creator<WKMsgEntity> CREATOR = new Parcelable.Creator<WKMsgEntity>() {
        @Override
        public WKMsgEntity createFromParcel(Parcel parcel) {
            return new WKMsgEntity(parcel);
        }

        @Override
        public WKMsgEntity[] newArray(int i) {
            return new WKMsgEntity[i];
        }
    };

    public int length;
    public int offset;
    public String type;
    public String value;

    public WKMsgEntity() {
    }

    public WKMsgEntity(Parcel parcel) {
        this.offset = parcel.readInt();
        this.length = parcel.readInt();
        this.type = parcel.readString();
        this.value = parcel.readString();
    }

    public JSONObject encodeEntities() {
        JSONObject jsonObject = new JSONObject();
        try {
            jsonObject.put("offset", this.offset);
            jsonObject.put("length", this.length);
            jsonObject.put("type", this.type);
            jsonObject.put("value", this.value);
            return jsonObject;
        } catch (Exception e) {
            e.printStackTrace();
            return jsonObject;
        }
    }

    @Override
    public int describeContents() {
        return 0;
    }

    @Override
    public void writeToParcel(Parcel parcel, int i) {
        parcel.writeInt(this.offset);
        parcel.writeInt(this.length);
        parcel.writeString(this.type);
        parcel.writeString(this.value);
    }
}
