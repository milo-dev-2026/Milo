package com.chat.uikit.trtc;

import com.chat.base.msgitem.WKRTCType;
import com.xinbida.wukongim.msgmodel.WKMessageContent;

import org.json.JSONException;
import org.json.JSONObject;

/**
 * P2P 通话消息内容
 * callType: 0=语音通话, 1=视频通话
 * resultType: 0=取消, 1=正常结束(含时长), 2=未接听, 3=拒绝
 * second: 通话时长(秒)
 */
public class RTCMsgContent extends WKMessageContent {

    public static final int CALL_TYPE_AUDIO = 0;
    public static final int CALL_TYPE_VIDEO = 1;

    public static final int RESULT_CANCEL = 0;
    public static final int RESULT_NORMAL = 1;
    public static final int RESULT_MISSED = 2;
    public static final int RESULT_DECLINED = 3;
    public static final int RESULT_BUSY = 4;

    public int callType;
    public int resultType;
    public int second;

    public RTCMsgContent() {
        this.type = WKRTCType.WK_P2P_CALL;
    }

    public RTCMsgContent(int callType, int resultType, int second) {
        this();
        this.callType = callType;
        this.resultType = resultType;
        this.second = second;
    }

    @Override
    public WKMessageContent decodeMsg(JSONObject jsonObject) {
        if (jsonObject.has("call_type")) {
            this.callType = jsonObject.optInt("call_type");
        }
        if (jsonObject.has("second")) {
            this.second = jsonObject.optInt("second");
        }
        if (jsonObject.has("result_type")) {
            this.resultType = jsonObject.optInt("result_type");
        }
        return this;
    }

    @Override
    public JSONObject encodeMsg() {
        JSONObject jsonObject = new JSONObject();
        try {
            jsonObject.put("call_type", this.callType);
            jsonObject.put("second", this.second);
            jsonObject.put("result_type", this.resultType);
            jsonObject.put("type", this.type);
        } catch (JSONException e) {
            e.printStackTrace();
        }
        return jsonObject;
    }

    @Override
    public String getDisplayContent() {
        return this.callType == CALL_TYPE_VIDEO ? "[视频通话]" : "[语音通话]";
    }

    @Override
    public String getSearchableWord() {
        return this.callType == CALL_TYPE_VIDEO ? "[视频通话]" : "[语音通话]";
    }
}
